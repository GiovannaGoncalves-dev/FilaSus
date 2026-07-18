package br.com.filasus.model;

/**
 * Vínculo entre um usuário da equipe e uma unidade de saúde. Dá escopo ao
 * perfil ADM_UNIDADE (só enxerga/gerencia dados da(s) unidade(s) vinculada(s)).
 * Tabela: UsuarioUnidade. PK composta: (cpfUsuario, idUnidade).
 */
public class UsuarioUnidade {

    private String cpfUsuario;
    private int idUnidade;

    public UsuarioUnidade() {}

    public UsuarioUnidade(String cpfUsuario, int idUnidade) {
        this.cpfUsuario = cpfUsuario;
        this.idUnidade = idUnidade;
    }

    public String getCpfUsuario() { return cpfUsuario; }
    public void setCpfUsuario(String cpfUsuario) { this.cpfUsuario = cpfUsuario; }

    public int getIdUnidade() { return idUnidade; }
    public void setIdUnidade(int idUnidade) { this.idUnidade = idUnidade; }
}
