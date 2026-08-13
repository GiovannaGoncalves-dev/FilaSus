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

    /**
     * Obtém o usuário atualmente logado na sessão HTTP.
     *
     * @param request Requisição HTTP
     * @return O objeto Usuario se estiver logado, ou null se não houver usuário na sessão.
     */
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

    /**
     * Define o usuário logado na sessão HTTP.
     *
     * @param request Requisição HTTP
     * @param usuario Usuário a ser guardado na sessão
     */
    public static void setUsuarioLogado(HttpServletRequest request, Usuario usuario) {
        if (request != null) {
            HttpSession session = request.getSession(true);
            session.setAttribute(SESSION_USER_KEY, usuario);
        }
    }

    /**
     * Invalida a sessão atual e desloga o usuário.
     *
     * @param request Requisição HTTP
     */
    public static void encerrarSessao(HttpServletRequest request) {
        if (request != null) {
            HttpSession session = request.getSession(false);
            if (session != null) {
                session.invalidate();
            }
        }
    }

    /**
     * Verifica se existe um usuário autenticado na sessão.
     *
     * @param request Requisição HTTP
     * @return true se o usuário estiver autenticado, false caso contrário.
     */
    public static boolean isAutenticado(HttpServletRequest request) {
        return getUsuarioLogado(request) != null;
    }

    /**
     * Verifica se o usuário possui determinado perfil.
     *
     * @param usuario Usuário a ser verificado
     * @param perfil Perfil esperado
     * @return true se possui o perfil, false caso contrário.
     */
    public static boolean temPerfil(Usuario usuario, PerfilUsuario perfil) {
        if (usuario == null || perfil == null) return false;
        return usuario.temPerfil(perfil);
    }

    /**
     * Verifica se o usuário logado na sessão possui determinado perfil.
     *
     * @param request Requisição HTTP
     * @param perfil Perfil esperado
     * @return true se o usuário logado possui o perfil, false caso contrário.
     */
    public static boolean temPerfil(HttpServletRequest request, PerfilUsuario perfil) {
        return temPerfil(getUsuarioLogado(request), perfil);
    }

    /**
     * Verifica se o usuário possui ao menos um dos perfis fornecidos.
     *
     * @param usuario Usuário a ser verificado
     * @param perfis Lista de perfis permitidos
     * @return true se possui algum dos perfis, false caso contrário.
     */
    public static boolean temAlgumPerfil(Usuario usuario, PerfilUsuario... perfis) {
        if (usuario == null || perfis == null) return false;
        for (PerfilUsuario p : perfis) {
            if (usuario.temPerfil(p)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Verifica se o usuário logado possui ao menos um dos perfis fornecidos.
     *
     * @param request Requisição HTTP
     * @param perfis Lista de perfis permitidos
     * @return true se possui algum dos perfis, false caso contrário.
     */
    public static boolean temAlgumPerfil(HttpServletRequest request, PerfilUsuario... perfis) {
        return temAlgumPerfil(getUsuarioLogado(request), perfis);
    }

    /**
     * Verifica se o usuário informado tem permissão para cadastrar/editar/gerenciar pacientes.
     * Perfis autorizados: ATENDENTE, ADM_UNIDADE, ADM_GERAL (ou MEDICO).
     *
     * @param usuario Usuário a ser verificado
     * @return true se o usuário pode cadastrar/editar pacientes, false caso contrário.
     */
    public static boolean podeGerenciarPacientes(Usuario usuario) {
        return temAlgumPerfil(usuario,
                PerfilUsuario.ATENDENTE,
                PerfilUsuario.ADM_UNIDADE,
                PerfilUsuario.ADM_GERAL,
                PerfilUsuario.MEDICO);
    }

    /**
     * Verifica se o usuário logado na requisição tem permissão para cadastrar/editar/gerenciar pacientes.
     *
     * @param request Requisição HTTP
     * @return true se o usuário logado pode cadastrar/editar pacientes, false caso contrário.
     */
    public static boolean podeGerenciarPacientes(HttpServletRequest request) {
        Usuario user = getUsuarioLogado(request);
        return podeGerenciarPacientes(user);
    }
}
