package br.com.filasus.model;

import java.time.LocalDateTime;

/**
 * Registro de atendimento clínico de um item de fila por um médico.
 * Tabela: Atendimento.
 *
 * ponytail: `id_item_fila` existe no schema como coluna solta, sem FK (o
 * vínculo real com ItemFila é o par idFila+sequenciaItemFila). Mantido aqui
 * como campo próprio em vez de reaproveitar outro id, pra não inventar um
 * significado que a coluna não tem.
 */
public class Atendimento {

    private int id;
    private int idItemFila;
    private int idFila;
    private int sequenciaItemFila;
    private String cpfMedico;
    private LocalDateTime inicio;
    private LocalDateTime fim;

    public Atendimento() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getIdItemFila() { return idItemFila; }
    public void setIdItemFila(int idItemFila) { this.idItemFila = idItemFila; }

    public int getIdFila() { return idFila; }
    public void setIdFila(int idFila) { this.idFila = idFila; }

    public int getSequenciaItemFila() { return sequenciaItemFila; }
    public void setSequenciaItemFila(int sequenciaItemFila) { this.sequenciaItemFila = sequenciaItemFila; }

    public String getCpfMedico() { return cpfMedico; }
    public void setCpfMedico(String cpfMedico) { this.cpfMedico = cpfMedico; }

    public LocalDateTime getInicio() { return inicio; }
    public void setInicio(LocalDateTime inicio) { this.inicio = inicio; }

    public LocalDateTime getFim() { return fim; }
    public void setFim(LocalDateTime fim) { this.fim = fim; }

    public boolean isEmAndamento() { return fim == null; }

    @Override
    public String toString() {
        return "Atendimento{id=" + id + ", idFila=" + idFila + ", seq=" + sequenciaItemFila
             + ", cpfMedico='" + cpfMedico + "'}";
    }
}
