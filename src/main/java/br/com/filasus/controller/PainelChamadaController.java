package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.enums.StatusItemFila;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 * Painel de chamada (TV): mostra os itens chamados/em atendimento de todas
 * as filas de um mutirão. A própria JSP se atualiza sozinha.
 */
@WebServlet("/painel")
public class PainelChamadaController extends HttpServlet {

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idMutiraoParam = request.getParameter("idMutirao");
        if (idMutiraoParam != null && !idMutiraoParam.isBlank()) {
            try {
                int idMutirao = Integer.parseInt(idMutiraoParam);
                List<Fila> filas = filaDAO.listarPorMutirao(idMutirao);
                List<ItemFila> chamados = new ArrayList<>();
                for (Fila fila : filas) {
                    chamados.addAll(itemFilaDAO.listarPorFilaEStatus(
                            fila.getId(), List.of(StatusItemFila.CHAMADO, StatusItemFila.EM_ATENDIMENTO)));
                }
                request.setAttribute("chamados", chamados);
                request.setAttribute("idMutirao", idMutirao);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar painel: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/painel.jsp").forward(request, response);
    }
}
