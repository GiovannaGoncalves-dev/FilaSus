package br.com.filasus.controller;

import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.FilaDAO;
import br.com.filasus.model.Documento;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.enums.TipoDocumento;
import br.com.filasus.util.UploadUtil;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;

/**
 * Pedido de prioridade: paciente envia um documento (comprovante, exame,
 * relatório) que fica pendente de validação (feature-validar-prioridade).
 */
@WebServlet("/documento/solicitar")
@MultipartConfig(maxFileSize = 10 * 1024 * 1024) // 10 MB
public class SolicitarPrioridadeController extends HttpServlet {

    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final FilaDAO filaDAO = new FilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        if (usuario == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        Object sucesso = request.getSession().getAttribute("prioridadeSucesso");
        if (sucesso != null) {
            request.setAttribute("sucesso", sucesso);
            request.getSession().removeAttribute("prioridadeSucesso");
        }
        try {
            List<ItemFila> itens = new ArrayList<>();
            for (ItemFila item : itemFilaDAO.listarPorPaciente(usuario.getCpf())) {
                if (EnumSet.of(StatusItemFila.AGUARDANDO, StatusItemFila.CHAMADO, StatusItemFila.EM_ATENDIMENTO)
                        .contains(item.getStatus())) {
                    item.setFila(filaDAO.buscarPorId(item.getIdFila()));
                    itens.add(item);
                }
            }
            request.setAttribute("itens", itens);
            request.setAttribute("documentos", documentoDAO.listarPorUsuario(usuario.getCpf()));
            request.getRequestDispatcher("/jsp/paciente/solicitar-prioridade.jsp").forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Erro ao carregar solicitações de prioridade.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        String cpfUsuario = usuario == null ? null : usuario.getCpf();
        request.setCharacterEncoding("UTF-8");
        String tipoParam = request.getParameter("tipo");
        String motivo = request.getParameter("motivo");
        String descricao = request.getParameter("descricao");
        int idFila = inteiro(request.getParameter("idFila"));
        int sequencia = inteiro(request.getParameter("sequencia"));
        Part arquivo = request.getPart("arquivo");

        if (cpfUsuario == null || cpfUsuario.isBlank() || tipoParam == null || motivo == null || motivo.isBlank()
                || descricao == null || descricao.isBlank() || idFila <= 0 || sequencia <= 0
                || arquivo == null || arquivo.getSize() == 0) {
            request.setAttribute("erro", "Selecione uma senha, informe o motivo, descreva o documento e escolha o arquivo.");
            doGet(request, response);
            return;
        }

        try {
            ItemFila item = itemFilaDAO.buscarPorChave(idFila, sequencia);
            if (item == null || !cpfUsuario.equals(item.getCpfPaciente())) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "A senha informada não pertence ao paciente autenticado.");
                return;
            }
            String caminhoArquivo = UploadUtil.salvar(arquivo);

            Documento documento = new Documento();
            documento.setCpfUsuario(cpfUsuario.trim());
            documento.setTipo(TipoDocumento.fromJson(tipoParam));
            documento.setArquivoUrl(caminhoArquivo);
            documento.setNomeOriginal(arquivo.getSubmittedFileName());
            documento.setIdFila(idFila);
            documento.setSequenciaItemFila(sequencia);
            documento.setMotivoPrioridade(motivo.trim());
            documento.setDescricao(descricao.trim());
            documento.setStatusValidacao(StatusValidacaoDocumento.PENDENTE);
            documentoDAO.inserir(documento);

            request.getSession().setAttribute("prioridadeSucesso", "Documento enviado! Aguarde a validação.");
            response.sendRedirect(request.getContextPath() + "/documento/solicitar");
            return;
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            request.setAttribute("erro", "Tipo de documento inválido. Use relatório, exame ou outro.");
        } catch (IOException | SQLException e) {
            request.setAttribute("erro", "Erro ao enviar documento: " + e.getMessage());
        }
        doGet(request, response);
    }

    private int inteiro(String valor) {
        try { return Integer.parseInt(valor); } catch (NumberFormatException e) { return 0; }
    }
}
