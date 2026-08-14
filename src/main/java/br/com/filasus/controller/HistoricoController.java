package br.com.filasus.controller;

import br.com.filasus.dao.AtendimentoDAO;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Histórico de atendimentos de um médico.
 *
 * ponytail: usa AtendimentoDAO.listarPorMedico, que já existe — não foi
 * criado um listarTodos()/porPeriodo() porque nenhuma outra feature pediu
 * isso ainda; se precisar de histórico geral (não por médico), adicionar
 * esse método na DAO compartilhada combinando antes com quem mais mexe nela.
 */
@WebServlet("/historico")
public class HistoricoController extends HttpServlet {

    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String cpfMedico = request.getParameter("cpfMedico");
        if (cpfMedico != null && !cpfMedico.isBlank()) {
            try {
                request.setAttribute("historico", atendimentoDAO.listarPorMedico(cpfMedico.trim()));
                request.setAttribute("cpfMedico", cpfMedico);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar histórico: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/historico/lista.jsp").forward(request, response);
    }
}
