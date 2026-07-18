package br.com.filasus.model;

/**
 * Unidade de saúde onde mutirões acontecem e à qual a equipe (atendente,
 * médico, admin de unidade) é vinculada. Tabela: Unidade.
 */
public class Unidade {

    private int id;
    private String nome;
    private String endereco;

    public Unidade() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getEndereco() { return endereco; }
    public void setEndereco(String endereco) { this.endereco = endereco; }

    @Override
    public String toString() {
        return "Unidade{id=" + id + ", nome='" + nome + "'}";
    }
}
