package br.com.filasus.filter;

import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/** Autorização server-side para páginas privadas e operações legadas. */
@WebFilter("/*")
public class AuthorizationFilter implements Filter {
    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        String path = request.getRequestURI().substring(request.getContextPath().length());
        PerfilUsuario[] required = requiredProfiles(path, request.getMethod());
        if (required == null) {
            chain.doFilter(req, res);
            return;
        }
        if (!AuthUtil.isLogado(request)) {
            deny(request, response, HttpServletResponse.SC_UNAUTHORIZED, "Não autenticado.");
            return;
        }
        if (required.length > 0 && !AuthUtil.checarPerfil(request, required)) {
            deny(request, response, HttpServletResponse.SC_FORBIDDEN, "Perfil sem permissão para esta operação.");
            return;
        }
        chain.doFilter(req, res);
    }

    private PerfilUsuario[] requiredProfiles(String path, String method) {
        if (path.startsWith("/jsp/atendente/")) return profiles(PerfilUsuario.ATENDENTE);
        if (path.startsWith("/jsp/medico/")) return profiles(PerfilUsuario.MEDICO);
        if (path.startsWith("/jsp/admin/")) return profiles(PerfilUsuario.ADM_UNIDADE, PerfilUsuario.ADM_GERAL);
        if (path.startsWith("/jsp/paciente/")) return profiles(PerfilUsuario.PACIENTE);
        if (path.equals("/jsp/painel.jsp")) return profiles();
        if (path.equals("/fila/emitir") || path.equals("/fila/chamar-proximo")) return profiles(PerfilUsuario.ATENDENTE);
        if (path.equals("/atendimento")) return profiles(PerfilUsuario.MEDICO);
        if (path.equals("/documento/solicitar")) return profiles(PerfilUsuario.PACIENTE);
        if (path.equals("/documento/validar")) return profiles(PerfilUsuario.MEDICO);
        if (path.startsWith("/api/") && !path.equals("/api/auth")
                && !(path.equals("/api/patients") && "POST".equals(method))) return profiles();
        return null;
    }

    private PerfilUsuario[] profiles(PerfilUsuario... profiles) { return profiles; }

    private void deny(HttpServletRequest request, HttpServletResponse response, int status, String message)
            throws IOException {
        if (request.getRequestURI().contains("/api/")) {
            response.setStatus(status);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"error\":\"" + message + "\"}");
        } else {
            response.sendRedirect(request.getContextPath() + "/jsp/login.jsp");
        }
    }
}
