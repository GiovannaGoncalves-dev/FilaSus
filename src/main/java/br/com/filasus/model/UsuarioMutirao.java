package br.com.filasus.model;

/**
 * Vínculo entre um usuário e um mutirão que ele organiza/participa.
 * Tabela: UsuarioMutirao. PK composta: (cpfUsuario, idMutirao).
 */
public class UsuarioMutirao {

    private String cpfUsuario;
    private int idMutirao;
    private boolean criouMutirao;

    public UsuarioMutirao() {}

    public UsuarioMutirao(String cpfUsuario, int idMutirao, boolean criouMutirao) {
        this.cpfUsuario = cpfUsuario;
        this.idMutirao = idMutirao;
        this.criouMutirao = criouMutirao;
    }

    public String getCpfUsuario() { return cpfUsuario; }
    public void setCpfUsuario(String cpfUsuario) { this.cpfUsuario = cpfUsuario; }

    public int getIdMutirao() { return idMutirao; }
    public void setIdMutirao(int idMutirao) { this.idMutirao = idMutirao; }

    public boolean isCriouMutirao() { return criouMutirao; }
    public void setCriouMutirao(boolean criouMutirao) { this.criouMutirao = criouMutirao; }
}
