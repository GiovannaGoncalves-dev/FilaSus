package br.com.filasus.service;

import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.DocumentoDAO;
import br.com.filasus.dao.FilaDAO;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.enums.StatusItemFila;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/** Intercala chamadas prioritárias e comuns sem bloquear a fila comum. */
public class ChamarProximoService {
    private static final int A_CADA_N_CHAMADAS_UMA_COMUM = 3;
    private static final Map<Integer, Integer> contadorChamadasPorFila = new ConcurrentHashMap<>();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();
    private final FilaDAO filaDAO = new FilaDAO();

    /** Compatibilidade com o formulário legado; a API nova sempre informa a fila. */
    public ItemFila chamarProximo(int idMutirao) throws SQLException {
        for (br.com.filasus.model.Fila fila : filaDAO.listarPorMutirao(idMutirao)) {
            ItemFila chamado = chamarProximoDaFila(fila.getId());
            if (chamado != null) return chamado;
        }
        return null;
    }

    public ItemFila chamarProximoDaFila(int idFila) throws SQLException {
        ItemFila proximoPrioritario = null;
        ItemFila proximoComum = null;
        for (ItemFila item : itemFilaDAO.listarPorFilaEStatus(idFila, List.of(StatusItemFila.AGUARDANDO))) {
            boolean prioridade = documentoDAO.temPrioridadeAprovada(item.getIdFila(), item.getSequenciaItemFila());
            if (prioridade && proximoPrioritario == null) proximoPrioritario = item;
            if (!prioridade && proximoComum == null) proximoComum = item;
        }
        int chamadas = contadorChamadasPorFila.merge(idFila, 1, Integer::sum);
        boolean vezDaComum = chamadas % A_CADA_N_CHAMADAS_UMA_COMUM == 0;
        ItemFila escolhido = vezDaComum && proximoComum != null
                ? proximoComum : proximoPrioritario != null ? proximoPrioritario : proximoComum;
        if (escolhido != null) {
            itemFilaDAO.atualizarStatus(escolhido.getIdFila(), escolhido.getSequenciaItemFila(), StatusItemFila.CHAMADO);
        }
        return escolhido;
    }

}
