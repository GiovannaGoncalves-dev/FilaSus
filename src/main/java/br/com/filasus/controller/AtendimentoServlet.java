package br.com.filasus.controller;

import br.com.filasus.dao.AtendimentoDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.model.Atendimento;
import br.com.filasus.model.enums.StatusItemFila;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDateTime;

/**
 * Iniciar/finalizar atendimento clínico e marcar item da fila
 * atendido/ausente. cpfMedico vem do formulário por enquanto (sem AuthUtil
 * ainda — feature-auth).
 */
@WebServlet("/atendimento")
public class AtendimentoServlet extends HttpServlet {

    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String cpfMedico = request.getParameter("cpfMedico");
        if (cpfMedico != null && !cpfMedico.isBlank()) {
            try {
                Atendimento emAndamento = atendimentoDAO.buscarEmAndamento(cpfMedico.trim());
                request.setAttribute("emAndamento", emAndamento);
                request.setAttribute("cpfMedico", cpfMedico);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao carregar atendimento: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/atendimento/painel.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String acao = request.getParameter("acao"); // "iniciar" | "finalizar" | "ausente"
        String cpfMedico = request.getParameter("cpfMedico");

        try {
            switch (acao) {
                case "iniciar" -> iniciar(request, cpfMedico);
                case "finalizar" -> finalizar(request);
                case "ausente" -> marcarAusente(request);
                default -> request.setAttribute("erro", "Ação inválida.");
            }
        } catch (SQLException | NumberFormatException e) {
            request.setAttribute("erro", "Erro ao processar atendimento: " + e.getMessage());
        }
        doGet(request, response);
    }

    private void iniciar(HttpServletRequest request, String cpfMedico) throws SQLException {
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));

        Atendimento atendimento = new Atendimento();
        atendimento.setIdFila(idFila);
        atendimento.setSequenciaItemFila(sequencia);
        // id_item_fila é coluna solta no schema, sem FK real (ver Atendimento.java) —
        // reaproveita a sequência, não existe outro valor com significado próprio.
        atendimento.setIdItemFila(sequencia);
        atendimento.setCpfMedico(cpfMedico.trim());

        atendimentoDAO.iniciar(atendimento);
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.EM_ATENDIMENTO);
    }

    private void finalizar(HttpServletRequest request) throws SQLException {
        int idAtendimento = Integer.parseInt(request.getParameter("idAtendimento"));
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));

        atendimentoDAO.finalizar(idAtendimento, LocalDateTime.now());
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.ATENDIDO);
    }

    private void marcarAusente(HttpServletRequest request) throws SQLException {
        int idFila = Integer.parseInt(request.getParameter("idFila"));
        int sequencia = Integer.parseInt(request.getParameter("sequencia"));
        itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.AUSENTE);
    }
}
