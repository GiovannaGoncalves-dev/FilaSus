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
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

/**
 * Controller responsável pelo CRUD de Pacientes.
 * Mapeamento: @WebServlet("/pacientes")
 */
@WebServlet("/pacientes")
public class PacienteServlet extends HttpServlet {

    private static final String JSP_LISTA = "/jsp/pacientes/lista.jsp";
    private static final String JSP_FORMULARIO = "/jsp/pacientes/formulario.jsp";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String acao = obtermAcao(request);

        try {
            switch (acao) {
                case "novo":
                case "cadastrar":
                    tratarNovo(request, response);
                    break;
                case "editar":
                    tratarEditar(request, response);
                    break;
                case "excluir":
                case "deletar":
                    tratarExcluir(request, response);
                    break;
                case "listar":
                case "list":
                default:
                    tratarListar(request, response);
                    break;
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro de banco de dados: " + e.getMessage());
            request.getRequestDispatcher(JSP_LISTA).forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        String acao = obtermAcao(request);

        try {
            if ("excluir".equalsIgnoreCase(acao) || "deletar".equalsIgnoreCase(acao)) {
                tratarExcluir(request, response);
            } else {
                tratarSalvar(request, response);
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao salvar/excluir paciente: " + e.getMessage());
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        }
    }

    private void tratarListar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String termo = request.getParameter("termo");
        if (termo == null || termo.isBlank()) {
            termo = request.getParameter("q");
        }

        String cpfParam = request.getParameter("cpf");
        List<Usuario> pacientes;

        if (cpfParam != null && !cpfParam.isBlank()) {
            String cpfClean = CpfUtil.desformatar(cpfParam);
            Usuario paciente = usuarioDAO.buscarPorCpf(cpfClean);
            pacientes = new ArrayList<>();
            if (paciente != null && paciente.temPerfil(PerfilUsuario.PACIENTE)) {
                pacientes.add(paciente);
            }
            request.setAttribute("cpfBusca", cpfParam);
        } else if (termo != null && !termo.isBlank()) {
            pacientes = usuarioDAO.buscarPacientes(termo.trim());
            request.setAttribute("termo", termo);
        } else {
            pacientes = usuarioDAO.listarPacientes();
        }

        String sucesso = request.getParameter("sucesso");
        if ("salvo".equals(sucesso)) {
            request.setAttribute("sucesso", "Paciente salvo com sucesso!");
        } else if ("excluido".equals(sucesso)) {
            request.setAttribute("sucesso", "Paciente excluído com sucesso!");
        }

        request.setAttribute("pacientes", pacientes);
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void tratarNovo(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarPacientes(request)) {
            request.setAttribute("erro", "Você não tem permissão para cadastrar novos pacientes.");
        }

        Usuario paciente = new Usuario();
        paciente.setAtivo(true);

        request.setAttribute("paciente", paciente);
        request.setAttribute("modo", "novo");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    private void tratarEditar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarPacientes(request)) {
            request.setAttribute("erro", "Você não tem permissão para editar dados de pacientes.");
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam == null || cpfParam.isBlank()) {
            request.setAttribute("erro", "CPF do paciente não informado.");
            tratarListar(request, response);
            return;
        }

        String cpfClean = CpfUtil.desformatar(cpfParam);
        Usuario paciente = usuarioDAO.buscarPorCpf(cpfClean);

        if (paciente == null) {
            request.setAttribute("erro", "Paciente não encontrado para o CPF informado: " + cpfParam);
            tratarListar(request, response);
            return;
        }

        request.setAttribute("paciente", paciente);
        request.setAttribute("modo", "editar");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    private void tratarSalvar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarPacientes(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios para cadastrar ou alterar pacientes.");
            tratarListar(request, response);
            return;
        }

        String modo = request.getParameter("modo");
        String cpfRaw = request.getParameter("cpf");
        String nome = request.getParameter("nome");
        String email = request.getParameter("email");
        String telefone = request.getParameter("telefone");
        String dataNascStr = request.getParameter("dataNascimento");
        String senha = request.getParameter("senha");
        String ativoStr = request.getParameter("ativo");

        Usuario rascunho = new Usuario();
        rascunho.setCpf(cpfRaw);
        rascunho.setNome(nome);
        rascunho.setEmail(email);
        rascunho.setTelefone(telefone);
        rascunho.setAtivo(ativoStr == null || "true".equalsIgnoreCase(ativoStr) || "1".equals(ativoStr) || "on".equalsIgnoreCase(ativoStr));

        if (dataNascStr != null && !dataNascStr.isBlank()) {
            try {
                rascunho.setDataNascimento(LocalDate.parse(dataNascStr));
            } catch (DateTimeParseException ignored) {}
        }

        if (cpfRaw == null || cpfRaw.isBlank() || !CpfUtil.isValido(cpfRaw)) {
            request.setAttribute("erro", "CPF inválido. Informe um CPF válido com 11 dígitos.");
            request.setAttribute("paciente", rascunho);
            request.setAttribute("modo", modo);
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
            return;
        }

        if (nome == null || nome.isBlank()) {
            request.setAttribute("erro", "O nome do paciente é obrigatório.");
            request.setAttribute("paciente", rascunho);
            request.setAttribute("modo", modo);
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
            return;
        }

        String cpfClean = CpfUtil.desformatar(cpfRaw);
        boolean eEdicao = "editar".equalsIgnoreCase(modo) || usuarioDAO.existeCpf(cpfClean);

        if (eEdicao) {
            Usuario paciente = usuarioDAO.buscarPorCpf(cpfClean);
            if (paciente == null) {
                paciente = new Usuario();
                paciente.setCpf(cpfClean);
            }

            paciente.setNome(nome.trim());
            paciente.setEmail(email != null ? email.trim() : "");
            paciente.setTelefone(telefone != null ? CpfUtil.desformatar(telefone) : null);
            paciente.setDataNascimento(rascunho.getDataNascimento());
            paciente.setAtivo(rascunho.isAtivo());

            if (senha != null && !senha.isBlank()) {
                paciente.setSenhaHash(senha);
            }

            usuarioDAO.atualizar(paciente);
        } else {
            if (usuarioDAO.existeCpf(cpfClean)) {
                request.setAttribute("erro", "Já existe um usuário cadastrado com o CPF informado.");
                request.setAttribute("paciente", rascunho);
                request.setAttribute("modo", "novo");
                request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
                return;
            }

            if (email != null && !email.isBlank() && usuarioDAO.existeEmail(email.trim())) {
                request.setAttribute("erro", "O e-mail informado já está cadastrado no sistema.");
                request.setAttribute("paciente", rascunho);
                request.setAttribute("modo", "novo");
                request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
                return;
            }

            Usuario novoPaciente = new Usuario();
            novoPaciente.setCpf(cpfClean);
            novoPaciente.setNome(nome.trim());
            novoPaciente.setEmail(email != null && !email.isBlank() ? email.trim() : cpfClean + "@paciente.local");
            novoPaciente.setTelefone(telefone != null ? CpfUtil.desformatar(telefone) : null);
            novoPaciente.setDataNascimento(rascunho.getDataNascimento());
            novoPaciente.setAtivo(rascunho.isAtivo());
            novoPaciente.setSenhaHash(senha != null && !senha.isBlank() ? senha : "123456");

            usuarioDAO.inserir(novoPaciente);
            perfilDAO.adicionar(cpfClean, PerfilUsuario.PACIENTE);
        }

        response.sendRedirect(request.getContextPath() + "/pacientes?acao=listar&sucesso=salvo");
    }

    private void tratarExcluir(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarPacientes(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios para excluir pacientes.");
            tratarListar(request, response);
            return;
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam != null && !cpfParam.isBlank()) {
            String cpfClean = CpfUtil.desformatar(cpfParam);
            usuarioDAO.deletar(cpfClean);
        }

        response.sendRedirect(request.getContextPath() + "/pacientes?acao=listar&sucesso=excluido");
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
