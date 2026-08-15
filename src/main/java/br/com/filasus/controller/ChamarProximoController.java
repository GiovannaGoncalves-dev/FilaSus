package br.com.filasus.controller;

import br.com.filasus.model.ItemFila;
import br.com.filasus.service.ChamarProximoService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Chama o próximo paciente de um mutirão, intercalando prioritário/comum
 */
@WebServlet("/fila/chamar-proximo")
public class ChamarProximoController extends HttpServlet {

    private final ChamarProximoService chamarProximoService = new ChamarProximoService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("/jsp/atendente/gerenciar-fila.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idMutiraoParam = request.getParameter("idMutirao");
        if (idMutiraoParam == null || idMutiraoParam.isBlank()) {
            request.setAttribute("erro", "Informe o id do mutirão.");
            doGet(request, response);
            return;
        }

        try {
            int idMutirao = Integer.parseInt(idMutiraoParam);
            ItemFila chamado = chamarProximoService.chamarProximo(idMutirao);
            request.setAttribute("chamado", chamado);
            request.setAttribute("idMutirao", idMutirao);
            if (chamado == null) {
                request.setAttribute("erro", "Não há ninguém aguardando neste mutirão.");
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao chamar próximo: " + e.getMessage());
        }
        doGet(request, response);
    }
}
