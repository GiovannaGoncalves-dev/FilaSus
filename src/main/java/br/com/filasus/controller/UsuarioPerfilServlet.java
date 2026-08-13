package br.com.filasus.controller;

import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;
import br.com.filasus.util.CpfUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Controller específico para gerenciamento de Perfis de Usuários (atribuir/remover perfil).
 *
 * Mapeamento: @WebServlet("/usuarios/perfis")
 */
@WebServlet("/usuarios/perfis")
public class UsuarioPerfilServlet extends HttpServlet {

    private static final String JSP_PERFIS = "/jsp/usuarios/perfis.jsp";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String acao = obtermAcao(request);

        try {
            switch (acao) {
                case "atribuir":
                case "adicionar":
                    tratarAtribuir(request, response);
                    break;
                case "remover":
                case "deletar":
                    tratarRemover(request, response);
                    break;
                case "listar":
                default:
                    tratarListar(request, response);
                    break;
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro de banco de dados ao gerenciar perfis: " + e.getMessage());
            request.getRequestDispatcher(JSP_PERFIS).forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String acao = obtermAcao(request);

        try {
            if ("remover".equalsIgnoreCase(acao) || "deletar".equalsIgnoreCase(acao)) {
                tratarRemover(request, response);
            } else {
                tratarAtribuir(request, response);
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao atualizar perfis: " + e.getMessage());
            request.getRequestDispatcher(JSP_PERFIS).forward(request, response);
        }
    }

    // ─── Ações ────────────────────────────────────────────────────────────────

    private void tratarListar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String cpfParam = request.getParameter("cpf");
        if (cpfParam == null || cpfParam.isBlank()) {
            cpfParam = request.getParameter("cpfUsuario");
        }

        if (cpfParam == null || cpfParam.isBlank()) {
            request.setAttribute("erro", "Informe o CPF do usuário para listar seus perfis.");
            response.sendRedirect(request.getContextPath() + "/usuarios");
            return;
        }

        String cpfClean = CpfUtil.desformatar(cpfParam);
        Usuario usuario = usuarioDAO.buscarPorCpf(cpfClean);

        if (usuario == null) {
            request.setAttribute("erro", "Usuário não encontrado para o CPF informado: " + cpfParam);
            response.sendRedirect(request.getContextPath() + "/usuarios");
            return;
        }

        List<PerfilUsuario> perfis = perfilDAO.listarPerfis(cpfClean);
        request.setAttribute("usuario", usuario);
        request.setAttribute("perfis", perfis);
        request.setAttribute("todosPerfis", PerfilUsuario.values());
        request.getRequestDispatcher(JSP_PERFIS).forward(request, response);
    }

    private void tratarAtribuir(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios de Administrador para atribuir perfis.");
            tratarListar(request, response);
            return;
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam == null || cpfParam.isBlank()) {
            cpfParam = request.getParameter("cpfUsuario");
        }

        String perfilStr = request.getParameter("perfil");

        if (cpfParam != null && !cpfParam.isBlank() && perfilStr != null && !perfilStr.isBlank()) {
            String cpfClean = CpfUtil.desformatar(cpfParam);
            try {
                PerfilUsuario perfilEnum = PerfilUsuario.valueOf(perfilStr.trim().toUpperCase());
                perfilDAO.adicionar(cpfClean, perfilEnum);
                request.setAttribute("sucesso", "Perfil " + perfilEnum.getDescricao() + " atribuído com sucesso!");
            } catch (IllegalArgumentException e) {
                request.setAttribute("erro", "Perfil inválido: " + perfilStr);
            }
        } else {
            request.setAttribute("erro", "CPF e perfil são obrigatórios para a atribuição.");
        }

        String redirect = request.getParameter("redirect");
        if ("form".equalsIgnoreCase(redirect)) {
            response.sendRedirect(request.getContextPath() + "/usuarios?acao=editar&cpf=" + CpfUtil.desformatar(cpfParam));
        } else {
            tratarListar(request, response);
        }
    }

    private void tratarRemover(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios de Administrador para remover perfis.");
            tratarListar(request, response);
            return;
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam == null || cpfParam.isBlank()) {
            cpfParam = request.getParameter("cpfUsuario");
        }

        String perfilStr = request.getParameter("perfil");

        if (cpfParam != null && !cpfParam.isBlank() && perfilStr != null && !perfilStr.isBlank()) {
            String cpfClean = CpfUtil.desformatar(cpfParam);
            try {
                PerfilUsuario perfilEnum = PerfilUsuario.valueOf(perfilStr.trim().toUpperCase());
                perfilDAO.remover(cpfClean, perfilEnum);
                request.setAttribute("sucesso", "Perfil " + perfilEnum.getDescricao() + " removido com sucesso!");
            } catch (IllegalArgumentException e) {
                request.setAttribute("erro", "Perfil inválido: " + perfilStr);
            }
        } else {
            request.setAttribute("erro", "CPF e perfil são obrigatórios para a remoção.");
        }

        String redirect = request.getParameter("redirect");
        if ("form".equalsIgnoreCase(redirect)) {
            response.sendRedirect(request.getContextPath() + "/usuarios?acao=editar&cpf=" + CpfUtil.desformatar(cpfParam));
        } else {
            tratarListar(request, response);
        }
    }

    private String obtermAcao(HttpServletRequest request) {
        String acao = request.getParameter("acao");
        if (acao == null || acao.isBlank()) {
            acao = request.getParameter("action");
        }
        if (acao == null || acao.isBlank()) {
            acao = "listar";
        }
        return acao.trim().toLowerCase();
    }
}
