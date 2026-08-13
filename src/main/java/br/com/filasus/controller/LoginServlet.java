package br.com.filasus.controller;

import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.model.Usuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;

/**
 * Controller responsável pelo login de usuários no FilaSUS (form -> HttpSession).
 * Suporta autenticação tanto por E-mail quanto por CPF.
 * Mapeamento: @WebServlet("/login")
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (AuthUtil.isLogado(session)) {
            Usuario u = AuthUtil.getUsuarioLogado(session);
            // Se o usuário possui múltiplos perfis e ainda não selecionou um perfil ativo
            if (u.getPerfis() != null && u.getPerfis().size() > 1 && AuthUtil.getPerfilAtivo(session) == null) {
                response.sendRedirect(request.getContextPath() + "/selecionar-perfil");
                return;
            }
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        request.getRequestDispatcher("/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        String loginInput = request.getParameter("login");
        if (loginInput == null || loginInput.trim().isEmpty()) {
            loginInput = request.getParameter("cpf");
        }
        if (loginInput == null || loginInput.trim().isEmpty()) {
            loginInput = request.getParameter("email");
        }

        String senha = request.getParameter("senha");
        if (senha == null) {
            senha = request.getParameter("password");
        }

        if (loginInput == null || loginInput.trim().isEmpty() || senha == null || senha.trim().isEmpty()) {
            request.setAttribute("erro", "Por favor, informe o CPF ou E-mail e a senha.");
            request.setAttribute("login", loginInput);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
            return;
        }

        loginInput = loginInput.trim();

        try {
            Usuario usuario = null;
            if (loginInput.contains("@")) {
                usuario = usuarioDAO.buscarPorEmail(loginInput);
            } else {
                String cpfLimpo = loginInput.replaceAll("\\D", "");
                if (!cpfLimpo.isEmpty()) {
                    usuario = usuarioDAO.buscarPorCpf(cpfLimpo);
                }
                if (usuario == null) {
                    usuario = usuarioDAO.buscarPorEmail(loginInput);
                }
            }

            if (usuario == null) {
                request.setAttribute("erro", "Usuário não encontrado ou inativo.");
                request.setAttribute("login", loginInput);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                return;
            }

            if (!usuario.isAtivo()) {
                request.setAttribute("erro", "Sua conta de usuário está desativada no sistema.");
                request.setAttribute("login", loginInput);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                return;
            }

            // Validação da senha armazenada no banco
            boolean senhaValida = usuario.getSenhaHash() != null && usuario.getSenhaHash().equals(senha.trim());

            if (!senhaValida) {
                request.setAttribute("erro", "Senha incorreta.");
                request.setAttribute("login", loginInput);
                request.getRequestDispatcher("/login.jsp").forward(request, response);
                return;
            }

            // Login bem-sucedido: cria/obtem a sessão
            HttpSession session = request.getSession(true);
            AuthUtil.login(session, usuario);

            // Redirecionamento condicional com base nos perfis do usuário
            if (usuario.getPerfis() != null && usuario.getPerfis().size() > 1) {
                response.sendRedirect(request.getContextPath() + "/selecionar-perfil");
            } else {
                response.sendRedirect(request.getContextPath() + "/");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("erro", "Erro ao conectar com o banco de dados. Tente novamente mais tarde.");
            request.setAttribute("login", loginInput);
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }
}
