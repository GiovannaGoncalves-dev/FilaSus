package br.com.filasus.model;

import br.com.filasus.model.enums.StatusMutirao;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Representa um mutirão de atendimento, sempre vinculado a uma unidade.
 * Agrupa uma ou mais filas de atendimento. Tabela: Mutirao.
 */
public class Mutirao {

    private int id;
    private int idUnidade;
    private LocalDate data;
    private String tipo;
    private String local;
    private int duracaoMinutos;
    private StatusMutirao status;
    private LocalDateTime criadoEm;

    private List<Fila> filas = new ArrayList<>();

    public Mutirao() {}

    // ─── Getters & Setters ────────────────────────────────────────────────────

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getIdUnidade() { return idUnidade; }
    public void setIdUnidade(int idUnidade) { this.idUnidade = idUnidade; }

    public LocalDate getData() { return data; }
    public void setData(LocalDate data) { this.data = data; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getLocal() { return local; }
    public void setLocal(String local) { this.local = local; }

    public int getDuracaoMinutos() { return duracaoMinutos; }
    public void setDuracaoMinutos(int duracaoMinutos) { this.duracaoMinutos = duracaoMinutos; }

    public StatusMutirao getStatus() { return status; }
    public void setStatus(StatusMutirao status) { this.status = status; }

    public LocalDateTime getCriadoEm() { return criadoEm; }
    public void setCriadoEm(LocalDateTime criadoEm) { this.criadoEm = criadoEm; }

    public List<Fila> getFilas() { return filas; }
    public void setFilas(List<Fila> filas) { this.filas = filas; }

    public boolean isAberto() {
        return StatusMutirao.ABERTO.equals(this.status);
    }

    @Override
    public String toString() {
        return "Mutirao{id=" + id + ", tipo='" + tipo + "', status=" + status + "}";
    }
}
