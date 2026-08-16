package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.service.ChamarProximoService;
import br.com.filasus.util.AuthUtil;

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
    private final FilaDAO filaDAO = new FilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String destino = "dashboard".equals(request.getParameter("origem"))
                ? "/atendente/dashboard" : "/atendente/fila";
        response.sendRedirect(request.getContextPath() + destino);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String idFilaParam = request.getParameter("idFila");
        try {
            int idFila = Integer.parseInt(idFilaParam);
            Fila fila = filaDAO.buscarPorId(idFila);
            Integer unidade = AuthUtil.getUnidadeAtiva(request);
            if (fila == null || unidade == null
                    || mutiraoDAO.buscarPorId(fila.getIdMutirao()).getIdUnidade() != unidade) {
                throw new IllegalArgumentException("Fila não pertence à unidade ativa.");
            }
            ItemFila chamado = chamarProximoService.chamarProximoDaFila(idFila);
            request.getSession().setAttribute(chamado == null ? "flash_erro" : "flash_sucesso",
                    chamado == null ? "Não há ninguém aguardando nesta fila."
                            : "Senha F" + idFila + "-" + String.format("%03d", chamado.getSequenciaItemFila()) + " chamada.");
        } catch (SQLException | IllegalArgumentException | NullPointerException e) {
            request.getSession().setAttribute("flash_erro", "Não foi possível chamar a próxima senha.");
        }
        response.sendRedirect(request.getContextPath() + "/atendente/fila");
    }
}
