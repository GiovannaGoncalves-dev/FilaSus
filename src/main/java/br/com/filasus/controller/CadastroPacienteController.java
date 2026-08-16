package br.com.filasus.controller;

import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.PasswordUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;
import java.time.LocalDate;

@WebServlet("/cadastro")
public class CadastroPacienteController extends HttpServlet {
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        copiarFlash(request, "cadastroSucesso", "sucesso");
        copiarFlash(request, "cadastroNome", "nomeCadastrado");
        copiarFlash(request, "cadastroCpf", "cpfCadastrado");
        copiarFlash(request, "cadastroIdade", "idadeCadastrada");
        request.getRequestDispatcher("/jsp/cadastro.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String cpf = digitos(request.getParameter("cpf"));
        String nome = texto(request.getParameter("nome"));
        String email = texto(request.getParameter("email"));
        String senha = request.getParameter("senha");
        String nascimento = texto(request.getParameter("dataNascimento"));
        String telefone = digitos(request.getParameter("telefone"));

        preservarFormulario(request, nome, email, cpf, nascimento, telefone);
        if (cpf.length() != 11 || nome.length() < 3 || !email.contains("@") || senha == null
                || senha.length() < 8 || nascimento.isBlank() || telefone.length() < 10) {
            request.setAttribute("erro", "Preencha CPF, nome, e-mail, senha, nascimento e telefone corretamente.");
            doGet(request, response);
            return;
        }

        Usuario paciente = new Usuario();
        paciente.setCpf(cpf);
        paciente.setNome(nome);
        paciente.setEmail(email);
        paciente.setSenhaHash(PasswordUtil.hash(senha));
        paciente.setTelefone(telefone);
        paciente.setAtivo(true);
        try {
            paciente.setDataNascimento(LocalDate.parse(nascimento));
            if (paciente.getDataNascimento().isAfter(LocalDate.now())) {
                throw new IllegalArgumentException("data futura");
            }
            if (usuarioDAO.existeCpf(cpf) || usuarioDAO.existeEmail(email)) {
                request.setAttribute("erro", "CPF ou e-mail já cadastrado.");
                doGet(request, response);
                return;
            }
            usuarioDAO.inserir(paciente);
            try {
                perfilDAO.adicionar(cpf, PerfilUsuario.PACIENTE);
            } catch (SQLException e) {
                usuarioDAO.deletar(cpf);
                throw e;
            }
            request.getSession().setAttribute("cadastroSucesso", "Cadastro realizado com sucesso.");
            request.getSession().setAttribute("cadastroNome", paciente.getNome());
            request.getSession().setAttribute("cadastroCpf", paciente.getCpfFormatado());
            request.getSession().setAttribute("cadastroIdade", paciente.getIdade());
            response.sendRedirect(request.getContextPath() + "/cadastro");
        } catch (IllegalArgumentException e) {
            request.setAttribute("erro", "Data de nascimento inválida.");
            doGet(request, response);
        } catch (SQLIntegrityConstraintViolationException e) {
            request.setAttribute("erro", "CPF ou e-mail já cadastrado.");
            doGet(request, response);
        } catch (SQLException e) {
            throw new ServletException("Erro ao cadastrar paciente.", e);
        }
    }

    private void copiarFlash(HttpServletRequest request, String sessao, String requisicao) {
        Object valor = request.getSession().getAttribute(sessao);
        if (valor != null) {
            request.setAttribute(requisicao, valor);
            request.getSession().removeAttribute(sessao);
        }
    }

    private void preservarFormulario(HttpServletRequest request, String nome, String email, String cpf,
                                     String nascimento, String telefone) {
        request.setAttribute("formNome", nome);
        request.setAttribute("formEmail", email);
        request.setAttribute("formCpf", cpf);
        request.setAttribute("formNascimento", nascimento);
        request.setAttribute("formTelefone", telefone);
    }

    private String texto(String valor) { return valor == null ? "" : valor.trim(); }
    private String digitos(String valor) { return texto(valor).replaceAll("\\D", ""); }
}
