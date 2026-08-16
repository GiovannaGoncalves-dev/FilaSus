package br.com.filasus.controller;

import br.com.filasus.dao.*;
import br.com.filasus.model.*;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.nio.file.Paths;
import java.util.*;

@WebServlet(urlPatterns = {"/paciente/dashboard", "/paciente/meus-dados"})
public class PacienteController extends HttpServlet {
    private static final EnumSet<StatusItemFila> ATIVOS = EnumSet.of(
            StatusItemFila.AGUARDANDO, StatusItemFila.CHAMADO, StatusItemFila.EM_ATENDIMENTO);
    private final ItemFilaDAO itemDAO = new ItemFilaDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Usuario sessao = AuthUtil.getUsuarioLogado(request);
        if (sessao == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        try {
            Usuario paciente = usuarioDAO.buscarPorCpf(sessao.getCpf());
            if (paciente == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Paciente não encontrado.");
                return;
            }
            request.setAttribute("paciente", paciente);
            if (request.getServletPath().endsWith("meus-dados")) {
                request.setAttribute("documentos", documentoDAO.listarPorUsuario(paciente.getCpf()));
                request.getRequestDispatcher("/jsp/paciente/meus-dados.jsp").forward(request, response);
                return;
            }
            List<SenhaPaciente> ativas = new ArrayList<>();
            List<SenhaPaciente> historico = new ArrayList<>();
            for (ItemFila item : itemDAO.listarPorPaciente(paciente.getCpf())) {
                SenhaPaciente senha = montar(item);
                (ATIVOS.contains(item.getStatus()) ? ativas : historico).add(senha);
            }
            request.setAttribute("senhasAtivas", ativas);
            request.setAttribute("historico", historico);
            request.getRequestDispatcher("/jsp/paciente/dashboard.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Erro ao carregar a área do paciente.", e);
        }
    }

    private SenhaPaciente montar(ItemFila item) throws SQLException {
        Fila fila = filaDAO.buscarPorId(item.getIdFila());
        Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
        Documento documento = documentoDAO.buscarPorItem(item.getIdFila(), item.getSequenciaItemFila());
        return new SenhaPaciente(item, fila, mutirao, documento, itemDAO.calcularPosicao(item));
    }

    public static class SenhaPaciente {
        private final ItemFila item;
        private final Fila fila;
        private final Mutirao mutirao;
        private final Documento documento;
        private final int posicao;
        SenhaPaciente(ItemFila item, Fila fila, Mutirao mutirao, Documento documento, int posicao) {
            this.item = item; this.fila = fila; this.mutirao = mutirao; this.documento = documento; this.posicao = posicao;
        }
        public String getCodigo() { return "F" + item.getIdFila() + "-" + String.format("%03d", item.getSequenciaItemFila()); }
        public String getFilaNome() { return fila == null ? "Fila" : fila.getNome(); }
        public String getMutiraoNome() { return mutirao == null ? "" : mutirao.getTipo(); }
        public String getStatus() { return item.getStatus() == null ? "" : item.getStatus().toJson(); }
        public int getPosicao() { return posicao; }
        public long getEspera() { return Math.max(0, item.getTempoEsperaMinutos()); }
        public java.time.LocalDateTime getEntrada() { return item.getEntradaEm(); }
        public boolean isPrioridade() { return documento != null && documento.getStatusValidacao() != null
                && "APROVADO".equals(documento.getStatusValidacao().name()); }
    }

    public static String nomeDocumento(Documento documento) {
        if (documento.getNomeOriginal() != null && !documento.getNomeOriginal().isBlank()) return documento.getNomeOriginal();
        if (documento.getArquivoUrl() == null) return "Documento";
        return Paths.get(documento.getArquivoUrl()).getFileName().toString();
    }
}
