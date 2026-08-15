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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Relatório simples de um mutirão: quantidade de itens de fila por status,
 * somando todas as filas do mutirão.
 *
 * ponytail: agregação feita aqui varrendo os status um a um pela DAO já
 * existente, sem criar uma query agregada nova (COUNT/GROUP BY) na DAO
 * compartilhada. Se o relatório crescer (períodos, múltiplos mutirões),
 * migrar para um método agregado na ItemFilaDAO, combinando antes com quem
 * mais mexe nela.
 */
@WebServlet("/relatorios")
public class RelatorioServlet extends HttpServlet {

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idMutiraoParam = request.getParameter("idMutirao");
        if (idMutiraoParam != null && !idMutiraoParam.isBlank()) {
            try {
                int idMutirao = Integer.parseInt(idMutiraoParam);
                List<Fila> filas = filaDAO.listarPorMutirao(idMutirao);

                Map<String, Integer> porStatus = new LinkedHashMap<>();
                for (StatusItemFila status : StatusItemFila.values()) {
                    int total = 0;
                    for (Fila fila : filas) {
                        List<ItemFila> itens = itemFilaDAO.listarPorFilaEStatus(fila.getId(), List.of(status));
                        total += itens.size();
                    }
                    porStatus.put(status.getDescricao(), total);
                }

                request.setAttribute("filas", filas);
                request.setAttribute("porStatus", porStatus);
                request.setAttribute("idMutirao", idMutirao);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao gerar relatório: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/relatorio/dashboard.jsp").forward(request, response);
    }
}
