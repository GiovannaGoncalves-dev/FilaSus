package br.com.filasus.controller;

import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Aprovar/rejeitar documento de prioridade. 
 */
@WebServlet("/documento/validar")
public class ValidarPrioridadeController extends HttpServlet {

    private final DocumentoDAO documentoDAO = new DocumentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            request.setAttribute("pendentes", documentoDAO.listarPorStatus(StatusValidacaoDocumento.PENDENTE));
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao carregar documentos pendentes: " + e.getMessage());
        }
        request.getRequestDispatcher("/jsp/medico/validar-prioridade.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idDocumentoParam = request.getParameter("idDocumento");
        String decisao = request.getParameter("decisao"); // "aprovado" ou "rejeitado"
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        String cpfValidador = usuario == null ? null : usuario.getCpf();

        if (idDocumentoParam == null || idDocumentoParam.isBlank()
                || decisao == null || decisao.isBlank()
                || cpfValidador == null || cpfValidador.isBlank()) {
            request.setAttribute("erro", "Informe o documento, a decisão e o CPF de quem está validando.");
            doGet(request, response);
            return;
        }

        try {
            int idDocumento = Integer.parseInt(idDocumentoParam);
            StatusValidacaoDocumento status = StatusValidacaoDocumento.fromJson(decisao);
            documentoDAO.validar(idDocumento, status, cpfValidador.trim());
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            request.setAttribute("erro", "Decisão inválida. Use aprovado ou rejeitado.");
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao validar documento: " + e.getMessage());
        }
        doGet(request, response);
    }
}
