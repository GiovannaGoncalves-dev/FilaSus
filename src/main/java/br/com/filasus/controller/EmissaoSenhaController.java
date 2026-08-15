package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.ItemFilaId;
import br.com.filasus.model.enums.StatusItemFila;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Emissão de senha: paciente entra numa fila (comum ou prioritária) de um
 * mutirão. A sequência do dia é calculada pela própria ItemFilaDAO.
 */
@WebServlet("/fila/emitir")
public class EmissaoSenhaController extends HttpServlet {

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idMutiraoParam = request.getParameter("idMutirao");
        if (idMutiraoParam != null && !idMutiraoParam.isBlank()) {
            try {
                List<Fila> filas = filaDAO.listarPorMutirao(Integer.parseInt(idMutiraoParam));
                request.setAttribute("filas", filas);
                request.setAttribute("idMutirao", idMutiraoParam);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar filas: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/atendente/cadastrar-paciente.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idFilaParam = request.getParameter("idFila");
        String cpfPaciente = request.getParameter("cpfPaciente");

        if (idFilaParam == null || idFilaParam.isBlank() || cpfPaciente == null || cpfPaciente.isBlank()) {
            request.setAttribute("erro", "Selecione a fila e informe o CPF do paciente.");
            doGet(request, response);
            return;
        }

        try {
            ItemFila item = new ItemFila();
            item.setId(new ItemFilaId(Integer.parseInt(idFilaParam), 0)); // sequência real é calculada pela DAO
            item.setCpfPaciente(cpfPaciente.trim());
            item.setStatus(StatusItemFila.AGUARDANDO);
            itemFilaDAO.inserir(item);

            request.setAttribute("senhaGerada", item);
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao emitir senha: " + e.getMessage());
        }
        doGet(request, response);
    }
}
