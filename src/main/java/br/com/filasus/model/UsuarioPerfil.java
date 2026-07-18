package br.com.filasus.model;

import br.com.filasus.model.enums.PerfilUsuario;

/**
 * Vínculo entre um usuário e um perfil (um usuário pode ter vários).
 * Tabela: UsuarioPerfil. PK composta: (idPerfil, cpfUsuario) — idPerfil é um
 * número sequencial por usuário, controlado pelo DAO na inserção.
 */
public class UsuarioPerfil {

    private int idPerfil;
    private String cpfUsuario;
    private PerfilUsuario perfil;

    public UsuarioPerfil() {}

    public UsuarioPerfil(int idPerfil, String cpfUsuario, PerfilUsuario perfil) {
        this.idPerfil = idPerfil;
        this.cpfUsuario = cpfUsuario;
        this.perfil = perfil;
    }

    public int getIdPerfil() { return idPerfil; }
    public void setIdPerfil(int idPerfil) { this.idPerfil = idPerfil; }

    public String getCpfUsuario() { return cpfUsuario; }
    public void setCpfUsuario(String cpfUsuario) { this.cpfUsuario = cpfUsuario; }

    public PerfilUsuario getPerfil() { return perfil; }
    public void setPerfil(PerfilUsuario perfil) { this.perfil = perfil; }
}
