package br.com.filasus.controller.api;

import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** API de autenticação consumida pelas telas originais em js/auth.js. */
@WebServlet(urlPatterns = {"/api/auth", "/api/me"})
public class AuthApiController extends HttpServlet {
    private static final Pattern CAMPO_JSON = Pattern.compile("\\\"([^\\\"]+)\\\"\\s*:\\s*\\\"((?:\\\\.|[^\\\"])*)\\\"");
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (!request.getServletPath().equals("/api/me")) {
            erro(response, HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Método não permitido.");
            return;
        }
        Usuario usuario = AuthUtil.getUsuarioLogado(request);
        PerfilUsuario perfil = AuthUtil.getPerfilAtivo(request);
        if (usuario == null || perfil == null) {
            erro(response, HttpServletResponse.SC_UNAUTHORIZED, "Não autenticado.");
            return;
        }
        json(response, HttpServletResponse.SC_OK, "{\"token\":\"session_" + request.getSession().getId() + "\",\"user\":" + usuarioJson(usuario, perfil)
                + (perfil == PerfilUsuario.PACIENTE ? ",\"patientId\":\"" + escapar(usuario.getCpf()) + "\"" : "") + "}");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (!request.getServletPath().equals("/api/auth")) {
            erro(response, HttpServletResponse.SC_METHOD_NOT_ALLOWED, "Método não permitido.");
            return;
        }
        String corpo = request.getReader().lines().reduce("", (a, b) -> a + b);
        String login = campo(corpo, "email");
        String senha = campo(corpo, "password");
        String role = campo(corpo, "role");
        if (login == null || login.isBlank() || senha == null || senha.isBlank()) {
            erro(response, HttpServletResponse.SC_BAD_REQUEST, "Informe CPF ou e-mail e senha.");
            return;
        }

        try {
            Usuario usuario = login.contains("@")
                    ? usuarioDAO.buscarPorEmail(login.trim())
                    : usuarioDAO.buscarPorCpf(login.replaceAll("\\D", ""));
            if (usuario == null || !usuario.isAtivo() || !PasswordUtil.matches(senha, usuario.getSenhaHash())) {
                erro(response, HttpServletResponse.SC_UNAUTHORIZED, "Credenciais inválidas.");
                return;
            }
            if (PasswordUtil.needsUpgrade(usuario.getSenhaHash())) {
                usuarioDAO.atualizarSenha(usuario.getCpf(), PasswordUtil.hash(senha));
            }
            if ((role == null || role.isBlank()) && usuario.getPerfis().size() > 1) {
                AuthUtil.login(request.getSession(true), usuario);
                json(response, HttpServletResponse.SC_OK, "{\"requiresProfileSelection\":true,\"profiles\":"
                        + perfisJson(usuario) + "}");
                return;
            }
            PerfilUsuario perfil = perfilSolicitado(usuario, role);
            if (perfil == null) {
                erro(response, HttpServletResponse.SC_FORBIDDEN, "A conta não possui o perfil selecionado.");
                return;
            }

            AuthUtil.login(request.getSession(true), usuario, perfil);
            AuthUtil.atualizarCookiesFrontend(request, response);
            String patientId = perfil == PerfilUsuario.PACIENTE
                    ? ",\"patientId\":\"" + escapar(usuario.getCpf()) + "\"" : "";
            json(response, HttpServletResponse.SC_OK, "{\"token\":\"session_" + request.getSession().getId()
                    + "\",\"user\":" + usuarioJson(usuario, perfil) + patientId + "}");
        } catch (SQLException e) {
            throw new IOException("Erro ao consultar usuário.", e);
        }
    }

    private String perfisJson(Usuario usuario) {
        StringBuilder json = new StringBuilder("[");
        for (int i = 0; i < usuario.getPerfis().size(); i++) {
            if (i > 0) json.append(',');
            json.append('\"').append(usuario.getPerfis().get(i).name().toLowerCase()).append('\"');
        }
        return json.append(']').toString();
    }

    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response) throws IOException {
        AuthUtil.logout(request.getSession(false));
        AuthUtil.limparCookiesFrontend(request, response);
        json(response, HttpServletResponse.SC_OK, "{\"ok\":true}");
    }

    private PerfilUsuario perfilSolicitado(Usuario usuario, String role) {
        if (usuario.getPerfis() == null || usuario.getPerfis().isEmpty()) return null;
        if (role == null || role.isBlank()) return usuario.getPerfis().get(0);
        return usuario.getPerfis().stream().filter(perfil -> switch (role.toLowerCase()) {
            case "paciente" -> perfil == PerfilUsuario.PACIENTE;
            case "atendente" -> perfil == PerfilUsuario.ATENDENTE;
            case "medico" -> perfil == PerfilUsuario.MEDICO;
            case "admin" -> perfil == PerfilUsuario.ADM_GERAL || perfil == PerfilUsuario.ADM_UNIDADE;
            default -> false;
        }).findFirst().orElse(null);
    }

    private String usuarioJson(Usuario usuario, PerfilUsuario perfil) {
        String role = switch (perfil) {
            case PACIENTE -> "paciente";
            case ATENDENTE -> "atendente";
            case MEDICO -> "medico";
            case ADM_UNIDADE, ADM_GERAL -> "admin";
        };
        return "{\"id\":\"" + escapar(usuario.getCpf()) + "\",\"name\":\"" + escapar(usuario.getNome())
                + "\",\"email\":\"" + escapar(usuario.getEmail()) + "\",\"role\":\"" + role
                + "\",\"specialty\":\"" + escapar(usuario.getEspecialidade()) + "\",\"active\":" + usuario.isAtivo() + "}";
    }

    private String campo(String json, String nome) {
        Matcher matcher = CAMPO_JSON.matcher(json == null ? "" : json);
        while (matcher.find()) if (matcher.group(1).equals(nome)) return matcher.group(2).replace("\\\"", "\"").replace("\\\\", "\\");
        return null;
    }

    private void erro(HttpServletResponse response, int status, String mensagem) throws IOException {
        json(response, status, "{\"error\":\"" + escapar(mensagem) + "\"}");
    }

    private void json(HttpServletResponse response, int status, String conteudo) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(conteudo);
    }

    private String escapar(String valor) {
        if (valor == null) return "";
        return valor.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}
