package br.com.filasus.util;

import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * Utilitário para gerenciamento de autenticação, sessão de usuário
 * e verificação de controle de acesso por perfil.
 */
public class AuthUtil {

    public static final String SESSION_USER_KEY = "usuarioLogado";
    public static final String SESSION_USER_KEY_ALT = "usuario";

    private AuthUtil() {
        // Construtor privado para classe utilitária
    }

    public static Usuario getUsuarioLogado(HttpServletRequest request) {
        if (request == null) return null;
        HttpSession session = request.getSession(false);
        if (session == null) return null;

        Object user = session.getAttribute(SESSION_USER_KEY);
        if (user == null) {
            user = session.getAttribute(SESSION_USER_KEY_ALT);
        }
        if (user instanceof Usuario) {
            return (Usuario) user;
        }
        return null;
    }

    public static void setUsuarioLogado(HttpServletRequest request, Usuario usuario) {
        if (request != null) {
            HttpSession session = request.getSession(true);
            session.setAttribute(SESSION_USER_KEY, usuario);
        }
    }

    public static void encerrarSessao(HttpServletRequest request) {
        if (request != null) {
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }
        }
    }

    public static boolean isAutenticado(HttpServletRequest request) {
        return getUsuarioLogado(request) != null;
    }

    public static boolean temPerfil(Usuario usuario, PerfilUsuario perfil) {
        if (usuario == null || perfil == null) return false;
        return usuario.temPerfil(perfil);
    }

    public static boolean temPerfil(HttpServletRequest request, PerfilUsuario perfil) {
        return temPerfil(getUsuarioLogado(request), perfil);
    }

    public static boolean temAlgumPerfil(Usuario usuario, PerfilUsuario... perfis) {
        if (usuario == null || perfis == null) return false;
        for (PerfilUsuario p : perfis) {
            if (usuario.temPerfil(p)) {
                return true;
            }
        }
        return false;
    }

    public static boolean temAlgumPerfil(HttpServletRequest request, PerfilUsuario... perfis) {
        return temAlgumPerfil(getUsuarioLogado(request), perfis);
    }

    public static boolean isAdmGeral(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.ADM_GERAL);
    }

    public static boolean isAdmGeral(HttpServletRequest request) {
        return isAdmGeral(getUsuarioLogado(request));
    }

    public static boolean isAdmUnidade(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.ADM_UNIDADE);
    }

    public static boolean isAdmUnidade(HttpServletRequest request) {
        return isAdmUnidade(getUsuarioLogado(request));
    }

    public static boolean isAdm(Usuario usuario) {
        return temAlgumPerfil(usuario, PerfilUsuario.ADM_GERAL, PerfilUsuario.ADM_UNIDADE);
    }

    public static boolean isAdm(HttpServletRequest request) {
        return isAdm(getUsuarioLogado(request));
    }

    public static boolean podeGerenciarMutiroes(Usuario usuario) {
        return isAdm(usuario);
    }

    public static boolean podeGerenciarMutiroes(HttpServletRequest request) {
        return podeGerenciarMutiroes(getUsuarioLogado(request));
    }

    public static boolean podeGerenciarUnidades(Usuario usuario) {
        return isAdmGeral(usuario);
    }

    public static boolean podeGerenciarUnidades(HttpServletRequest request) {
        return podeGerenciarUnidades(getUsuarioLogado(request));
    }

    public static boolean podeGerenciarUsuarios(Usuario usuario) {
        return isAdm(usuario);
    }

    public static boolean podeGerenciarUsuarios(HttpServletRequest request) {
        Usuario user = getUsuarioLogado(request);
        return podeGerenciarUsuarios(user);
    }

    public static boolean podeGerenciarPacientes(Usuario usuario) {
        return temAlgumPerfil(usuario,
                PerfilUsuario.ATENDENTE,
                PerfilUsuario.ADM_UNIDADE,
                PerfilUsuario.ADM_GERAL,
                PerfilUsuario.MEDICO);
    }

    public static boolean podeGerenciarPacientes(HttpServletRequest request) {
        Usuario user = getUsuarioLogado(request);
        return podeGerenciarPacientes(user);
    }
}
