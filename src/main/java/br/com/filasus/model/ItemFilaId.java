package br.com.filasus.model;

import java.util.Objects;

/**
 * Chave composta para a entidade ItemFila: (idFila, sequenciaItemFila).
 */
public class ItemFilaId {

    private int idFila;
    private int sequenciaItemFila;

    public ItemFilaId() {}

    public ItemFilaId(int idFila, int sequenciaItemFila) {
        this.idFila = idFila;
        this.sequenciaItemFila = sequenciaItemFila;
    }

    public int getIdFila() { return idFila; }
    public void setIdFila(int idFila) { this.idFila = idFila; }

    public int getSequenciaItemFila() { return sequenciaItemFila; }
    public void setSequenciaItemFila(int sequenciaItemFila) { this.sequenciaItemFila = sequenciaItemFila; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ItemFilaId)) return false;
        ItemFilaId that = (ItemFilaId) o;
        return idFila == that.idFila && sequenciaItemFila == that.sequenciaItemFila;
    }

    @Override
    public int hashCode() {
        return Objects.hash(idFila, sequenciaItemFila);
    }

    @Override
    public String toString() {
        return "ItemFilaId{idFila=" + idFila + ", sequencia=" + sequenciaItemFila + "}";
    }
}
