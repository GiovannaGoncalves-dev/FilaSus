package br.com.filasus.controller;

import br.com.filasus.dao.AtendimentoDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.model.Atendimento;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;

/*
 * Iniciar/finalizar atendimento clínico e marcar item da fila
 * atendido/ausente.  
 */

@WebServlet("/atendimento")
public class AtendimentoController extends HttpServlet {

    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        String cpfMedico = usuario == null ? null : usuario.getCpf();
        if (cpfMedico != null && !cpfMedico.isBlank()) {
            try {
                Atendimento emAndamento = atendimentoDAO.buscarEmAndamento(cpfMedico.trim());
                request.setAttribute("emAndamento", emAndamento);
                request.setAttribute("cpfMedico", cpfMedico);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar atendimento: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/medico/atendimento.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String acao = request.getParameter("acao"); // "iniciar" | "finalizar" | "ausente"
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        String cpfMedico = usuario == null ? null : usuario.getCpf();

        try {
            switch (acao) {
                case "iniciar" -> iniciar(request, cpfMedico);
                case "finalizar" -> finalizar(request);
                case "ausente" -> marcarAusente(request);
                default -> request.setAttribute("erro", "Ação inválida.");
            }
        } catch (SQLException | NumberFormatException e) {
            request.setAttribute("erro", "Erro ao processar atendimento: " + e.getMessage());
        }
        doGet(request, response);
    }

    private void iniciar(HttpServletRequest request, String cpfMedico) throws SQLException {
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));

        Atendimento atendimento = new Atendimento();
        atendimento.setIdFila(idFila);
        atendimento.setSequenciaItemFila(sequencia);
        atendimento.setIdItemFila(sequencia);
        atendimento.setCpfMedico(cpfMedico.trim());

        atendimentoDAO.iniciar(atendimento);
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.EM_ATENDIMENTO);
    }

    private void finalizar(HttpServletRequest request) throws SQLException {
        int idAtendimento = Integer.parseInt(request.getParameter("idAtendimento"));
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));

        atendimentoDAO.finalizar(idAtendimento, LocalDateTime.now());
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.ATENDIDO);
    }

    private void marcarAusente(HttpServletRequest request) throws SQLException {
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.AUSENTE);
    }
}
