package br.com.filasus.controller;

import br.com.filasus.dao.ItemFilaDAO;
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
 * Consulta de status da fila: o paciente informa o CPF e vê, para cada fila
 * em que está, o status atual e (se aguardando) a posição na fila.
 */
@WebServlet("/fila/consulta")
public class ConsultaFilaServlet extends HttpServlet {

    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String cpfPaciente = request.getParameter("cpfPaciente");
        if (cpfPaciente != null && !cpfPaciente.isBlank()) {
            try {
                List<ItemFila> itens = itemFilaDAO.listarPorPaciente(cpfPaciente.trim());
                List<Integer> posicoes = new ArrayList<>();
                for (ItemFila item : itens) {
                    posicoes.add(calcularPosicao(item));
                }
                request.setAttribute("itens", itens);
                request.setAttribute("posicoes", posicoes);
                request.setAttribute("cpfPaciente", cpfPaciente);
            } catch (SQLException e) {
                request.setAttribute("erro", "Erro ao consultar fila: " + e.getMessage());
            }
        }
        request.getRequestDispatcher("/jsp/fila/consulta.jsp").forward(request, response);
    }

    /** Posição = 1 + quantos itens aguardando na mesma fila entraram antes. Retorna 0 se não estiver aguardando. */
    private int calcularPosicao(ItemFila item) throws SQLException {
        if (!item.isAguardando()) return 0;
        List<ItemFila> aguardando = itemFilaDAO.listarPorFilaEStatus(item.getIdFila(), List.of(StatusItemFila.AGUARDANDO));
        int posicao = 1;
        for (ItemFila outro : aguardando) {
            if (outro.getSequenciaItemFila() < item.getSequenciaItemFila()) posicao++;
        }
        return posicao;
    }
}
