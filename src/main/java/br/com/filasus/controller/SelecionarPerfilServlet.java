package br.com.filasus.controller;

import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Controller responsável pela seleção de perfil ativo do usuário quando ele possui mais de um.
 * Mapeamento: @WebServlet("/selecionar-perfil")
 */
@WebServlet("/selecionar-perfil")
public class SelecionarPerfilServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (!AuthUtil.isLogado(session)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Usuario usuario = AuthUtil.getUsuarioLogado(session);
        if (usuario == null || usuario.getPerfis() == null || usuario.getPerfis().isEmpty()) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // Se o usuário tem apenas 1 perfil, ativa-o automaticamente e vai para o início
        if (usuario.getPerfis().size() == 1) {
            AuthUtil.setPerfilAtivo(session, usuario.getPerfis().get(0));
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        // Se tem mais de 1 perfil, disponibiliza a lista para renderização na JSP
        request.setAttribute("perfis", usuario.getPerfis());
        request.setAttribute("perfilAtivo", AuthUtil.getPerfilAtivo(session));
        request.getRequestDispatcher("/selecionar-perfil.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (!AuthUtil.isLogado(session)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        Usuario usuario = AuthUtil.getUsuarioLogado(session);
        if (usuario == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String perfilParam = request.getParameter("perfil");
        if (perfilParam == null || perfilParam.trim().isEmpty()) {
            perfilParam = request.getParameter("tipoPerfil");
        }

        if (perfilParam == null || perfilParam.trim().isEmpty()) {
            request.setAttribute("erro", "Por favor, selecione um perfil válido.");
            request.setAttribute("perfis", usuario.getPerfis());
            request.setAttribute("perfilAtivo", AuthUtil.getPerfilAtivo(session));
            request.getRequestDispatcher("/selecionar-perfil.jsp").forward(request, response);
            return;
        }

        try {
            PerfilUsuario perfilSelecionado = PerfilUsuario.valueOf(perfilParam.trim().toUpperCase());

            if (usuario.temPerfil(perfilSelecionado)) {
                AuthUtil.setPerfilAtivo(session, perfilSelecionado);
                response.sendRedirect(request.getContextPath() + "/");
            } else {
                request.setAttribute("erro", "O perfil selecionado não pertence à sua conta.");
                request.setAttribute("perfis", usuario.getPerfis());
                request.setAttribute("perfilAtivo", AuthUtil.getPerfilAtivo(session));
                request.getRequestDispatcher("/selecionar-perfil.jsp").forward(request, response);
            }
        } catch (IllegalArgumentException e) {
            request.setAttribute("erro", "Perfil inválido informado.");
            request.setAttribute("perfis", usuario.getPerfis());
            request.setAttribute("perfilAtivo", AuthUtil.getPerfilAtivo(session));
            request.getRequestDispatcher("/selecionar-perfil.jsp").forward(request, response);
        }
    }
}
