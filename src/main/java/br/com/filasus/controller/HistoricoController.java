package br.com.filasus.controller;

import br.com.filasus.dao.AtendimentoDAO;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;

/*
 * Histórico de atendimentos de um médico.
 */
@WebServlet("/historico")
public class HistoricoController extends HttpServlet {

    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String cpfMedico = request.getParameter("cpfMedico");
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        if ((cpfMedico == null || cpfMedico.isBlank()) && usuario != null) {
            cpfMedico = usuario.getCpf();
        }
        if (cpfMedico != null && !cpfMedico.isBlank()) {
            try {
                request.setAttribute("historico", atendimentoDAO.listarPorMedico(cpfMedico.trim()));
                request.setAttribute("cpfMedico", cpfMedico);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar histórico: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/atendente/historico.jsp").forward(request, response);
    }
}
