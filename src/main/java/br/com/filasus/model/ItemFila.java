package br.com.filasus.model;

import br.com.filasus.model.enums.StatusItemFila;
import java.time.LocalDateTime;

/**
 * Representa um item (paciente) na fila de atendimento.
 * Chave primária composta: (idFila, sequenciaItemFila). Tabela: ItemFila.
 *
 * Não guarda mais senha/código de exibição nem dados de prioridade — a
 * classificação comum/prioritário é da {@link Fila} (tipo), e a validação de
 * prioridade é feita via {@link Documento}.
 */
public class ItemFila {

    private ItemFilaId id; // PK composta: id_fila + sequencia_item_fila

    private String cpfPaciente;
    private Usuario paciente; // carregado sob demanda
    private Fila fila;        // carregado sob demanda

    private StatusItemFila status;
    private LocalDateTime entradaEm;
    private LocalDateTime atualizadoEm;

    public ItemFila() {}

    public ItemFila(ItemFilaId id, String cpfPaciente, StatusItemFila status, LocalDateTime entradaEm) {
        this.id = id;
        this.cpfPaciente = cpfPaciente;
        this.status = status;
        this.entradaEm = entradaEm;
    }

    // ─── Métodos de negócio ───────────────────────────────────────────────────

    public boolean isAguardando() {
        return StatusItemFila.AGUARDANDO.equals(this.status);
    }

    /** Tempo de espera em minutos desde a entrada na fila até agora (ou até ser atualizado). */
    public long getTempoEsperaMinutos() {
        if (entradaEm == null) return 0;
        LocalDateTime fim = (atualizadoEm != null && !isAguardando()) ? atualizadoEm : LocalDateTime.now();
        return java.time.Duration.between(entradaEm, fim).toMinutes();
    }

    // ─── Getters & Setters ────────────────────────────────────────────────────

    public ItemFilaId getId() { return id; }
    public void setId(ItemFilaId id) { this.id = id; }

    public int getIdFila() { return id != null ? id.getIdFila() : 0; }
    public int getSequenciaItemFila() { return id != null ? id.getSequenciaItemFila() : 0; }

    public String getCpfPaciente() { return cpfPaciente; }
    public void setCpfPaciente(String cpfPaciente) { this.cpfPaciente = cpfPaciente; }

    public Usuario getPaciente() { return paciente; }
    public void setPaciente(Usuario paciente) { this.paciente = paciente; }

    public Fila getFila() { return fila; }
    public void setFila(Fila fila) { this.fila = fila; }

    public StatusItemFila getStatus() { return status; }
    public void setStatus(StatusItemFila status) { this.status = status; }

    public LocalDateTime getEntradaEm() { return entradaEm; }
    public void setEntradaEm(LocalDateTime entradaEm) { this.entradaEm = entradaEm; }

    public LocalDateTime getAtualizadoEm() { return atualizadoEm; }
    public void setAtualizadoEm(LocalDateTime atualizadoEm) { this.atualizadoEm = atualizadoEm; }

    @Override
    public String toString() {
        return "ItemFila{id=" + id + ", cpfPaciente='" + cpfPaciente + "', status=" + status + "}";
    }
}
