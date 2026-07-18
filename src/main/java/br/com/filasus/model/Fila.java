package br.com.filasus.model;

import br.com.filasus.model.enums.TipoFila;

/**
 * Representa uma fila de atendimento dentro de um mutirão. Tabela: Fila.
 */
public class Fila {

    private int id;
    private int idMutirao;
    private String nome;
    private TipoFila tipo;

    public Fila() {}

    public Fila(int id, String nome, int idMutirao, TipoFila tipo) {
        this.id = id;
        this.nome = nome;
        this.idMutirao = idMutirao;
        this.tipo = tipo;
    }

    // ─── Getters & Setters ────────────────────────────────────────────────────

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getIdMutirao() { return idMutirao; }
    public void setIdMutirao(int idMutirao) { this.idMutirao = idMutirao; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public TipoFila getTipo() { return tipo; }
    public void setTipo(TipoFila tipo) { this.tipo = tipo; }

    @Override
    public String toString() {
        return "Fila{id=" + id + ", nome='" + nome + "', idMutirao=" + idMutirao + ", tipo=" + tipo + "}";
    }
}
