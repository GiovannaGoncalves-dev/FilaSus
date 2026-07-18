package br.com.filasus.model.enums;

/**
 * Tipos de perfil de um usuário. Um mesmo `Usuario` pode ter mais de um
 * perfil simultaneamente (tabela `UsuarioPerfil`, relação 1:N) — este enum
 * é só o valor de cada vínculo, não é mais um campo único em `Usuario`.
 */
public enum PerfilUsuario {
    PACIENTE("Paciente"),
    ATENDENTE("Atendente"),
    MEDICO("Médico"),
    ADM_UNIDADE("Administrador de unidade"),
    ADM_GERAL("Administrador geral");

    private final String descricao;

    PerfilUsuario(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public String toJson() {
        return name().toLowerCase();
    }

    public static PerfilUsuario fromJson(String valor) {
        if (valor == null) return null;
        return PerfilUsuario.valueOf(valor.trim().toUpperCase());
    }
}
