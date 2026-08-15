package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.StatusMutirao;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Painel de chamada: mostra os itens chamados/em atendimento de todas
 * as filas de um mutirão. A própria JSP se atualiza sozinha.
 */
@WebServlet("/painel")
public class PainelChamadaController extends HttpServlet {

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            Integer idUnidade = resolverUnidade(request);
            if (idUnidade == null) throw new IllegalArgumentException("Selecione uma unidade para abrir o painel.");
            Mutirao mutirao = escolherMutirao(request.getParameter("idMutirao"), idUnidade);
            List<Fila> filas = mutirao == null ? List.of() : filaDAO.listarPorMutirao(mutirao.getId());
            List<ItemFila> chamados = new ArrayList<>();
            Map<Integer, ItemFila> atualPorFila = new LinkedHashMap<>();
            Map<Integer, Long> aguardandoPorFila = new LinkedHashMap<>();
            for (Fila fila : filas) {
                List<ItemFila> itens = itemFilaDAO.listarPorFila(fila.getId());
                ItemFila atual = null;
                long aguardando = 0;
                for (ItemFila item : itens) {
                    item.setFila(fila);
                    item.setPaciente(usuarioDAO.buscarPorCpf(item.getCpfPaciente()));
                    if (item.getStatus() == StatusItemFila.AGUARDANDO) aguardando++;
                    if (item.getStatus() == StatusItemFila.CHAMADO
                            || item.getStatus() == StatusItemFila.EM_ATENDIMENTO) {
                        chamados.add(item);
                        if (atual == null || maisRecente(item, atual)) atual = item;
                    }
                }
                atualPorFila.put(fila.getId(), atual);
                aguardandoPorFila.put(fila.getId(), aguardando);
            }
            chamados.sort(Comparator.comparing(ItemFila::getAtualizadoEm,
                    Comparator.nullsLast(Comparator.reverseOrder())));
            request.setAttribute("mutirao", mutirao);
            request.setAttribute("filas", filas);
            request.setAttribute("chamados", chamados);
            request.setAttribute("atualPorFila", atualPorFila);
            request.setAttribute("aguardandoPorFila", aguardandoPorFila);
        } catch (IllegalArgumentException e) {
            request.setAttribute("erro", e.getMessage());
            atributosVazios(request);
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao carregar o painel.");
            atributosVazios(request);
        }
        request.getRequestDispatcher("/jsp/painel.jsp").forward(request, response);
    }

    private void atributosVazios(HttpServletRequest request) {
        request.setAttribute("mutirao", null);
        request.setAttribute("filas", List.of());
        request.setAttribute("chamados", List.of());
        request.setAttribute("atualPorFila", Map.of());
        request.setAttribute("aguardandoPorFila", Map.of());
    }

    private Mutirao escolherMutirao(String parametro, int idUnidade) throws SQLException {
        if (parametro != null && !parametro.isBlank()) {
            final int idMutirao;
            try { idMutirao = Integer.parseInt(parametro); }
            catch (NumberFormatException e) { throw new IllegalArgumentException("Identificador de mutirão inválido."); }
            Mutirao escolhido = mutiraoDAO.buscarPorId(idMutirao);
            if (escolhido == null || escolhido.getIdUnidade() != idUnidade)
                throw new IllegalArgumentException("O mutirão solicitado não pertence à unidade ativa.");
            return escolhido.getStatus() == StatusMutirao.ABERTO ? escolhido : null;
        }
        for (Mutirao mutirao : mutiraoDAO.listarPorUnidade(idUnidade)) {
            if (mutirao.getStatus() == StatusMutirao.ABERTO) return mutirao;
        }
        return null;
    }

    /** Pacientes sem vínculo fixo usam a unidade da senha ativa mais recente. */
    private Integer resolverUnidade(HttpServletRequest request) throws SQLException {
        Integer ativa = AuthUtil.getUnidadeAtiva(request);
        if (ativa != null) return ativa;
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        if (usuario == null) return null;
        for (ItemFila item : itemFilaDAO.listarPorPaciente(usuario.getCpf())) {
            if (item.getStatus() != StatusItemFila.AGUARDANDO
                    && item.getStatus() != StatusItemFila.CHAMADO
                    && item.getStatus() != StatusItemFila.EM_ATENDIMENTO) continue;
            Fila fila = filaDAO.buscarPorId(item.getIdFila());
            Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
            if (mutirao != null && mutirao.getStatus() == StatusMutirao.ABERTO) return mutirao.getIdUnidade();
        }
        return null;
    }

    private boolean maisRecente(ItemFila candidato, ItemFila atual) {
        if (candidato.getAtualizadoEm() == null) return false;
        return atual.getAtualizadoEm() == null || candidato.getAtualizadoEm().isAfter(atual.getAtualizadoEm());
    }
}
