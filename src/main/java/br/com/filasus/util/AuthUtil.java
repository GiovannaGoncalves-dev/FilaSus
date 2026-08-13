package br.com.filasus.util;

import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.util.List;

/**
 * Utilitário central de autenticação e gestão de sessão do FilaSUS.
 * Prover funções de login, logout, recuperação de usuário logado,
 * verificação de perfis ativos e restrição de acesso por unidade.
 */
public class AuthUtil {

    public static final String USUARIO_SESSION_KEY = "usuarioLogado";
    public static final String PERFIL_ATIVO_SESSION_KEY = "perfilAtivo";
    public static final String UNIDADE_ATIVA_SESSION_KEY = "unidadeAtiva";

    private AuthUtil() {}

    /**
     * Efetua o login registrando o usuário e seu perfil ativo na sessão HTTP.
     *
     * @param session     Sessão HTTP do usuário
     * @param usuario     Instância do usuário autenticado
     * @param perfilAtivo Perfil que estará ativo durante a navegação
     */
    public static void login(HttpSession session, Usuario usuario, PerfilUsuario perfilAtivo) {
        if (session == null || usuario == null) return;
        session.setAttribute(USUARIO_SESSION_KEY, usuario);
        session.setAttribute(PERFIL_ATIVO_SESSION_KEY, perfilAtivo);

        // Se o usuário possui apenas 1 unidade vinculada, define-a automaticamente como ativa
        List<Integer> unidades = usuario.getUnidadeIds();
        if (unidades != null && unidades.size() == 1) {
            session.setAttribute(UNIDADE_ATIVA_SESSION_KEY, unidades.get(0));
        }
    }

    /**
     * Efetua o login registrando o usuário na sessão.
     * Se ele tiver exatamente 1 perfil, esse perfil é ativado automaticamente.
     * Caso possua múltiplos perfis, o perfil ativo permanece null até ser escolhido em /selecionar-perfil.
     *
     * @param session Sessão HTTP do usuário
     * @param usuario Instância do usuário autenticado
     */
    public static void login(HttpSession session, Usuario usuario) {
        if (session == null || usuario == null) return;
        PerfilUsuario perfilUnico = null;
        if (usuario.getPerfis() != null && usuario.getPerfis().size() == 1) {
            perfilUnico = usuario.getPerfis().get(0);
        }
        login(session, usuario, perfilUnico);
    }

    /**
     * Encerra a sessão HTTP do usuário.
     *
     * @param session Sessão a ser invalidada
     */
    public static void logout(HttpSession session) {
        if (session != null) {
            try {
                session.invalidate();
            } catch (IllegalStateException ignored) {
                // Sessão já desativada/invalidada
            }
        }
    }

    /**
     * Retorna o usuário logado na sessão informada, ou null se não autenticado.
     */
    public static Usuario getUsuarioLogado(HttpSession session) {
        if (session == null) return null;
        Object u = session.getAttribute(USUARIO_SESSION_KEY);
        return (u instanceof Usuario) ? (Usuario) u : null;
    }

    /**
     * Retorna o usuário logado a partir da requisição HTTP.
     */
    public static Usuario getUsuarioLogado(HttpServletRequest request) {
        if (request == null) return null;
        return getUsuarioLogado(request.getSession(false));
    }

    /**
     * Verifica se existe um usuário autenticado na sessão.
     */
    public static boolean isLogado(HttpSession session) {
        return getUsuarioLogado(session) != null;
    }

    /**
     * Verifica se existe um usuário autenticado a partir da requisição.
     */
    public static boolean isLogado(HttpServletRequest request) {
        return isLogado(request != null ? request.getSession(false) : null);
    }

    /**
     * Retorna o perfil ativo na sessão atual.
     */
    public static PerfilUsuario getPerfilAtivo(HttpSession session) {
        if (session == null) return null;
        Object p = session.getAttribute(PERFIL_ATIVO_SESSION_KEY);
        return (p instanceof PerfilUsuario) ? (PerfilUsuario) p : null;
    }

    /**
     * Retorna o perfil ativo a partir da requisição.
     */
    public static PerfilUsuario getPerfilAtivo(HttpServletRequest request) {
        if (request == null) return null;
        return getPerfilAtivo(request.getSession(false));
    }

    /**
     * Define ou atualiza o perfil ativo na sessão.
     */
    public static void setPerfilAtivo(HttpSession session, PerfilUsuario perfil) {
        if (session != null) {
            session.setAttribute(PERFIL_ATIVO_SESSION_KEY, perfil);
        }
    }

    /**
     * Retorna o ID da unidade de saúde ativa na sessão.
     */
    public static Integer getUnidadeAtiva(HttpSession session) {
        if (session == null) return null;
        Object u = session.getAttribute(UNIDADE_ATIVA_SESSION_KEY);
        return (u instanceof Integer) ? (Integer) u : null;
    }

    /**
     * Retorna o ID da unidade de saúde ativa a partir da requisição.
     */
    public static Integer getUnidadeAtiva(HttpServletRequest request) {
        if (request == null) return null;
        return getUnidadeAtiva(request.getSession(false));
    }

    /**
     * Define o ID da unidade de saúde ativa na sessão.
     */
    public static void setUnidadeAtiva(HttpSession session, Integer unidadeId) {
        if (session != null) {
            session.setAttribute(UNIDADE_ATIVA_SESSION_KEY, unidadeId);
        }
    }

    /**
     * Checa se o usuário logado está com o perfil especificado ativo
     * ou possui tal perfil em seus vínculos.
     */
    public static boolean checarPerfil(HttpSession session, PerfilUsuario perfilNecessario) {
        if (!isLogado(session) || perfilNecessario == null) return false;
        PerfilUsuario perfilAtivo = getPerfilAtivo(session);
        if (perfilAtivo == perfilNecessario) return true;

        Usuario usuario = getUsuarioLogado(session);
        return usuario != null && usuario.temPerfil(perfilNecessario);
    }

    /**
     * Checa o perfil necessário a partir da requisição.
     */
    public static boolean checarPerfil(HttpServletRequest request, PerfilUsuario perfilNecessario) {
        return checarPerfil(request != null ? request.getSession(false) : null, perfilNecessario);
    }

    /**
     * Checa se o usuário logado possui ou está utilizando qualquer um dos perfis permitidos.
     */
    public static boolean checarPerfil(HttpSession session, PerfilUsuario... perfisPermitidos) {
        if (!isLogado(session) || perfisPermitidos == null) return false;
        PerfilUsuario perfilAtivo = getPerfilAtivo(session);
        Usuario usuario = getUsuarioLogado(session);

        for (PerfilUsuario p : perfisPermitidos) {
            if (perfilAtivo == p || (usuario != null && usuario.temPerfil(p))) {
                return true;
            }
        }
        return false;
    }

    /**
     * Checa se o usuário possui qualquer um dos perfis permitidos a partir da requisição.
     */
    public static boolean checarPerfil(HttpServletRequest request, PerfilUsuario... perfisPermitidos) {
        return checarPerfil(request != null ? request.getSession(false) : null, perfisPermitidos);
    }

    /**
     * Checa se a unidade de saúde especificada é acessível pelo usuário na sessão.
     * Administradores Gerais possuem acesso a todas as unidades.
     */
    public static boolean checarUnidade(HttpSession session, Integer unidadeId) {
        if (!isLogado(session) || unidadeId == null) return false;

        if (checarPerfil(session, PerfilUsuario.ADM_GERAL)) return true;

        Integer unidadeAtiva = getUnidadeAtiva(session);
        if (unidadeId.equals(unidadeAtiva)) return true;

        Usuario u = getUsuarioLogado(session);
        return u != null && u.getUnidadeIds() != null && u.getUnidadeIds().contains(unidadeId);
    }

    /**
     * Checa o acesso à unidade especificada a partir da requisição.
     */
    public static boolean checarUnidade(HttpServletRequest request, Integer unidadeId) {
        return checarUnidade(request != null ? request.getSession(false) : null, unidadeId);
    }
}
