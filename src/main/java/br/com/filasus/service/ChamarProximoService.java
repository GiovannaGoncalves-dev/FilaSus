package br.com.filasus.service;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.enums.TipoFila;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Regra de priorização: intercala a chamada entre a fila prioritária e a
 * fila comum de um mutirão, sem deixar a fila comum nunca ser chamada.
 *
 * ponytail: contador de chamadas guardado em memória (Map estático), por
 * mutirão — reinicia a cada redeploy da aplicação. Se precisar sobreviver a
 * um restart, evoluir para persistir esse contador (ex.: coluna em Mutirao).
 */
public class ChamarProximoService {

    private static final int A_CADA_N_CHAMADAS_UMA_COMUM = 3;

    private static final Map<Integer, Integer> contadorChamadasPorMutirao = new ConcurrentHashMap<>();

    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();

    /**
     * Chama o próximo paciente do mutirão, marcando o item escolhido como
     * CHAMADO. Retorna null se não houver ninguém aguardando em nenhuma fila.
     */
    public ItemFila chamarProximo(int idMutirao) throws SQLException {
        List<Fila> filas = filaDAO.listarPorMutirao(idMutirao);
        Fila filaPrioritaria = buscarPorTipo(filas, TipoFila.PRIORITARIO);
        Fila filaComum = buscarPorTipo(filas, TipoFila.COMUM);

        ItemFila proximoPrioritario = filaPrioritaria != null ? proximoAguardando(filaPrioritaria.getId()) : null;
        ItemFila proximoComum = filaComum != null ? proximoAguardando(filaComum.getId()) : null;

        int chamadas = contadorChamadasPorMutirao.merge(idMutirao, 1, Integer::sum);
        boolean vezDaComum = chamadas % A_CADA_N_CHAMADAS_UMA_COMUM == 0;

        ItemFila escolhido;
        if (vezDaComum && proximoComum != null) {
            escolhido = proximoComum;
        } else if (proximoPrioritario != null) {
            escolhido = proximoPrioritario;
        } else {
            escolhido = proximoComum;
        }

        if (escolhido != null) {
            itemFilaDAO.atualizarStatus(escolhido.getIdFila(), escolhido.getSequenciaItemFila(), StatusItemFila.CHAMADO);
        }
        return escolhido;
    }

    private ItemFila proximoAguardando(int idFila) throws SQLException {
        List<ItemFila> aguardando = itemFilaDAO.listarPorFilaEStatus(idFila, List.of(StatusItemFila.AGUARDANDO));
        return aguardando.isEmpty() ? null : aguardando.get(0);
    }

    private Fila buscarPorTipo(List<Fila> filas, TipoFila tipo) {
        return filas.stream().filter(f -> f.getTipo() == tipo).findFirst().orElse(null);
    }
}
