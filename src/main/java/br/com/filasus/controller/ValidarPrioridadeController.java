package br.com.filasus.controller;

import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.model.enums.StatusValidacaoDocumento;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Aprovar/rejeitar documento de prioridade. Quem valida (cpfValidador) vem
 * do formulário por enquanto — não existe AuthUtil ainda (feature-auth).
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
        request.getRequestDispatcher("/jsp/documento/validar.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idDocumentoParam = request.getParameter("idDocumento");
        String decisao = request.getParameter("decisao"); // "aprovado" ou "rejeitado"
        String cpfValidador = request.getParameter("cpfValidador");

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
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao validar documento: " + e.getMessage());
        }
        doGet(request, response);
    }
}
