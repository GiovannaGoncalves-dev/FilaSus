package br.com.filasus.util;

import br.com.filasus.model.enums.PerfilUsuario;

/** Rotas server-side usadas depois do login e da selecao de perfil. */
public final class NavigationUtil {
    private NavigationUtil() {}

    public static String paginaInicial(PerfilUsuario perfil) {
        if (perfil == null) return "/login";
        return switch (perfil) {
            case PACIENTE -> "/paciente/dashboard";
            case ATENDENTE -> "/atendente/dashboard";
            case MEDICO -> "/medico/dashboard";
            case ADM_UNIDADE, ADM_GERAL -> "/admin/dashboard";
        };
    }
}
