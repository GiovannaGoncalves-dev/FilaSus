package br.com.filasus.util;

import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * Utilitário unificado para gerenciamento de autenticação, sessão de usuário
 * e verificação de controle de acesso por perfil.
 */
public class AuthUtil {

    public static final String SESSION_USER_KEY = "usuarioLogado";
    public static final String SESSION_USER_KEY_ALT = "usuario";

    private AuthUtil() {
        // Construtor privado para classe utilitária
    }

    // ─── Gerenciamento de Sessão ──────────────────────────────────────────────

    /**
     * Obtém o usuário atualmente autenticado na sessão HTTP.
     *
     * @param request Requisição HTTP
     * @return O objeto Usuario se estiver logado, ou null se não houver sessão ativa.
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
     * Armazena o usuário autenticado na sessão HTTP.
     *
     * @param request Requisição HTTP
     * @param usuario Usuário a ser mantido em sessão
     */
    public static void setUsuarioLogado(HttpServletRequest request, Usuario usuario) {
        if (request != null) {
            HttpSession session = request.getSession(true);
            session.setAttribute(SESSION_USER_KEY, usuario);
        }
    }

    /**
     * Invalida a sessão atual e encerra o login do usuário.
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
     * Verifica se existe um usuário autenticado na sessão HTTP.
     *
     * @param request Requisição HTTP
     * @return true se o usuário estiver autenticado, false caso contrário.
     */
    public static boolean isAutenticado(HttpServletRequest request) {
        return getUsuarioLogado(request) != null;
    }

    // ─── Verificações Genéricas de Perfis ─────────────────────────────────────

    /**
     * Verifica se o usuário informado possui determinado perfil.
     *
     * @param usuario Usuário a ser checado
     * @param perfil Perfil a ser verificado
     * @return true se possui o perfil, false caso contrário.
     */
    public static boolean temPerfil(Usuario usuario, PerfilUsuario perfil) {
        if (usuario == null || perfil == null) return false;
        return usuario.temPerfil(perfil);
    }

    /**
     * Verifica se o usuário autenticado na sessão possui determinado perfil.
     *
     * @param request Requisição HTTP
     * @param perfil Perfil a ser verificado
     * @return true se o usuário logado possui o perfil, false caso contrário.
     */
    public static boolean temPerfil(HttpServletRequest request, PerfilUsuario perfil) {
        return temPerfil(getUsuarioLogado(request), perfil);
    }

    /**
     * Verifica se o usuário informado possui ao menos um dos perfis informados.
     *
     * @param usuario Usuário a ser checado
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
     * Verifica se o usuário autenticado na sessão possui ao menos um dos perfis informados.
     *
     * @param request Requisição HTTP
     * @param perfis Lista de perfis permitidos
     * @return true se possui algum dos perfis, false caso contrário.
     */
    public static boolean temAlgumPerfil(HttpServletRequest request, PerfilUsuario... perfis) {
        return temAlgumPerfil(getUsuarioLogado(request), perfis);
    }

    // ─── Auxiliares Específicos por Perfil ────────────────────────────────────

    public static boolean isPaciente(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.PACIENTE);
    }

    public static boolean isPaciente(HttpServletRequest request) {
        return isPaciente(getUsuarioLogado(request));
    }

    public static boolean isAtendente(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.ATENDENTE);
    }

    public static boolean isAtendente(HttpServletRequest request) {
        return isAtendente(getUsuarioLogado(request));
    }

    public static boolean isMedico(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.MEDICO);
    }

    public static boolean isMedico(HttpServletRequest request) {
        return isMedico(getUsuarioLogado(request));
    }

    public static boolean isAdmUnidade(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.ADM_UNIDADE);
    }

    public static boolean isAdmUnidade(HttpServletRequest request) {
        return isAdmUnidade(getUsuarioLogado(request));
    }

    public static boolean isAdmGeral(Usuario usuario) {
        return temPerfil(usuario, PerfilUsuario.ADM_GERAL);
    }

    public static boolean isAdmGeral(HttpServletRequest request) {
        return isAdmGeral(getUsuarioLogado(request));
    }

    public static boolean isAdm(Usuario usuario) {
        return temAlgumPerfil(usuario, PerfilUsuario.ADM_GERAL, PerfilUsuario.ADM_UNIDADE);
    }

    public static boolean isAdm(HttpServletRequest request) {
        return isAdm(getUsuarioLogado(request));
    }

    // ─── Regras de Autorização por Módulo/Domínio ────────────────────────────

    /**
     * Permissão para cadastrar, editar e gerenciar Pacientes.
     * Permitido para: ATENDENTE, ADM_UNIDADE, ADM_GERAL e MEDICO.
     */
    public static boolean podeGerenciarPacientes(Usuario usuario) {
        return temAlgumPerfil(usuario,
                PerfilUsuario.ATENDENTE,
                PerfilUsuario.ADM_UNIDADE,
                PerfilUsuario.ADM_GERAL,
                PerfilUsuario.MEDICO);
    }

    public static boolean podeGerenciarPacientes(HttpServletRequest request) {
        return podeGerenciarPacientes(getUsuarioLogado(request));
    }

    /**
     * Permissão para cadastrar, editar e gerenciar Usuários da Equipe.
     * Permitido para: ADM_GERAL e ADM_UNIDADE.
     */
    public static boolean podeGerenciarUsuarios(Usuario usuario) {
        return isAdm(usuario);
    }

    public static boolean podeGerenciarUsuarios(HttpServletRequest request) {
        return podeGerenciarUsuarios(getUsuarioLogado(request));
    }

    /**
     * Permissão para cadastrar, editar e gerenciar Unidades de Saúde.
     * Permitido exclusivamente para: ADM_GERAL.
     */
    public static boolean podeGerenciarUnidades(Usuario usuario) {
        return isAdmGeral(usuario);
    }

    public static boolean podeGerenciarUnidades(HttpServletRequest request) {
        return podeGerenciarUnidades(getUsuarioLogado(request));
    }

    /**
     * Permissão para cadastrar, editar, abrir e encerrar Mutirões.
     * Permitido para: ADM_GERAL e ADM_UNIDADE.
     */
    public static boolean podeGerenciarMutiroes(Usuario usuario) {
        return isAdm(usuario);
    }

    public static boolean podeGerenciarMutiroes(HttpServletRequest request) {
        return podeGerenciarMutiroes(getUsuarioLogado(request));
    }
}
