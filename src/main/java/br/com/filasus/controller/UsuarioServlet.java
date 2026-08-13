package br.com.filasus.controller;

import br.com.filasus.dao.UnidadeDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.dao.UsuarioUnidadeDAO;
import br.com.filasus.model.Unidade;
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
import java.util.*;

/**
 * Controller responsável pelo CRUD de Usuários da equipe,
 * gerenciamento de seus perfis e vínculo com Unidades de Saúde.
 *
 * Mapeamento: @WebServlet("/usuarios")
 */
@WebServlet("/usuarios")
public class UsuarioServlet extends HttpServlet {

    private static final String JSP_LISTA = "/jsp/usuarios/lista.jsp";
    private static final String JSP_FORMULARIO = "/jsp/usuarios/formulario.jsp";

    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();
    private final UsuarioUnidadeDAO usuarioUnidadeDAO = new UsuarioUnidadeDAO();
    private final UnidadeDAO unidadeDAO = new UnidadeDAO();

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
            } else if ("vincularunidade".equalsIgnoreCase(acao)) {
                tratarVincularUnidade(request, response);
            } else if ("desvincularunidade".equalsIgnoreCase(acao)) {
                tratarDesvincularUnidade(request, response);
            } else {
                tratarSalvar(request, response);
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao salvar/atualizar usuário: " + e.getMessage());
            try {
                prepararAtributosFormulario(request);
            } catch (SQLException ignored) {}
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        }
    }

    // ─── Métodos de Leitura ───────────────────────────────────────────────────

    private void tratarListar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso restrito: Apenas administradores (Geral ou de Unidade) podem gerenciar usuários da equipe.");
        }

        String termo = request.getParameter("termo");
        if (termo == null || termo.isBlank()) {
            termo = request.getParameter("q");
        }

        String perfilFiltro = request.getParameter("perfil");
        List<Usuario> usuarios;

        if (perfilFiltro != null && !perfilFiltro.isBlank()) {
            try {
                PerfilUsuario p = PerfilUsuario.valueOf(perfilFiltro.trim().toUpperCase());
                usuarios = usuarioDAO.listarPorPerfil(p);
                request.setAttribute("perfilFiltro", perfilFiltro);
            } catch (IllegalArgumentException e) {
                usuarios = usuarioDAO.listarEquipe();
            }
        } else if (termo != null && !termo.isBlank()) {
            usuarios = usuarioDAO.buscarUsuarios(termo.trim());
            request.setAttribute("termo", termo);
        } else {
            usuarios = usuarioDAO.listarEquipe();
        }

        String sucesso = request.getParameter("sucesso");
        if ("salvo".equals(sucesso)) {
            request.setAttribute("sucesso", "Usuário salvo com sucesso!");
        } else if ("excluido".equals(sucesso)) {
            request.setAttribute("sucesso", "Usuário excluído com sucesso!");
        }

        request.setAttribute("usuarios", usuarios);
        request.setAttribute("unidades", unidadeDAO.listarTodas());
        request.setAttribute("todosPerfis", PerfilUsuario.values());
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void tratarNovo(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para cadastrar usuários da equipe.");
        }

        Usuario usuario = new Usuario();
        usuario.setAtivo(true);

        prepararAtributosFormulario(request);
        request.setAttribute("usuario", usuario);
        request.setAttribute("modo", "novo");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    private void tratarEditar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para editar usuários.");
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam == null || cpfParam.isBlank()) {
            request.setAttribute("erro", "CPF do usuário não informado.");
            tratarListar(request, response);
            return;
        }

        String cpfClean = CpfUtil.desformatar(cpfParam);
        Usuario usuario = usuarioDAO.buscarPorCpf(cpfClean);

        if (usuario == null) {
            request.setAttribute("erro", "Usuário não encontrado para o CPF: " + cpfParam);
            tratarListar(request, response);
            return;
        }

        prepararAtributosFormulario(request);
        request.setAttribute("usuario", usuario);
        request.setAttribute("perfisDoUsuario", usuario.getPerfis());
        request.setAttribute("unidadesDoUsuario", usuario.getUnidadeIds());
        request.setAttribute("modo", "editar");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    // ─── Métodos de Escrita (Salvar, Excluir e Vínculos) ──────────────────────

    private void tratarSalvar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios de Administrador para realizar esta alteração.");
            tratarListar(request, response);
            return;
        }

        String modo = request.getParameter("modo");
        String cpfRaw = request.getParameter("cpf");
        String nome = request.getParameter("nome");
        String email = request.getParameter("email");
        String especialidade = request.getParameter("especialidade");
        String telefone = request.getParameter("telefone");
        String dataNascStr = request.getParameter("dataNascimento");
        String senha = request.getParameter("senha");
        String ativoStr = request.getParameter("ativo");

        String[] perfisSelecionados = request.getParameterValues("perfis");
        String[] unidadesSelecionadas = request.getParameterValues("unidades");

        // Validação de CPF
        if (cpfRaw == null || cpfRaw.isBlank() || !CpfUtil.isValido(cpfRaw)) {
            request.setAttribute("erro", "CPF inválido. Informe um CPF válido com 11 dígitos.");
            montarRascunhoEForward(request, response, modo, cpfRaw, nome, email, especialidade, telefone, dataNascStr, ativoStr);
            return;
        }

        // Validação de Nome e Email
        if (nome == null || nome.isBlank()) {
            request.setAttribute("erro", "O nome do usuário é obrigatório.");
            montarRascunhoEForward(request, response, modo, cpfRaw, nome, email, especialidade, telefone, dataNascStr, ativoStr);
            return;
        }

        if (email == null || email.isBlank()) {
            request.setAttribute("erro", "O e-mail do usuário é obrigatório.");
            montarRascunhoEForward(request, response, modo, cpfRaw, nome, email, especialidade, telefone, dataNascStr, ativoStr);
            return;
        }

        String cpfClean = CpfUtil.desformatar(cpfRaw);
        boolean eEdicao = "editar".equalsIgnoreCase(modo) || usuarioDAO.existeCpf(cpfClean);

        LocalDate dataNasc = null;
        if (dataNascStr != null && !dataNascStr.isBlank()) {
            try {
                dataNasc = LocalDate.parse(dataNascStr);
            } catch (DateTimeParseException ignored) {}
        }
        boolean ativo = ativoStr == null || "true".equalsIgnoreCase(ativoStr) || "1".equals(ativoStr) || "on".equalsIgnoreCase(ativoStr);

        if (eEdicao) {
            Usuario usuario = usuarioDAO.buscarPorCpf(cpfClean);
            if (usuario == null) {
                usuario = new Usuario();
                usuario.setCpf(cpfClean);
            }

            usuario.setNome(nome.trim());
            usuario.setEmail(email.trim());
            usuario.setEspecialidade(especialidade != null ? especialidade.trim() : null);
            usuario.setTelefone(telefone != null ? CpfUtil.desformatar(telefone) : null);
            usuario.setDataNascimento(dataNasc);
            usuario.setAtivo(ativo);

            if (senha != null && !senha.isBlank()) {
                usuario.setSenhaHash(senha);
            }

            usuarioDAO.atualizar(usuario);
        } else {
            if (usuarioDAO.existeCpf(cpfClean)) {
                request.setAttribute("erro", "Já existe um usuário cadastrado com o CPF informado.");
                montarRascunhoEForward(request, response, "novo", cpfRaw, nome, email, especialidade, telefone, dataNascStr, ativoStr);
                return;
            }

            if (usuarioDAO.existeEmail(email.trim())) {
                request.setAttribute("erro", "O e-mail informado já está cadastrado em outra conta.");
                montarRascunhoEForward(request, response, "novo", cpfRaw, nome, email, especialidade, telefone, dataNascStr, ativoStr);
                return;
            }

            Usuario novoUsuario = new Usuario();
            novoUsuario.setCpf(cpfClean);
            novoUsuario.setNome(nome.trim());
            novoUsuario.setEmail(email.trim());
            novoUsuario.setEspecialidade(especialidade != null ? especialidade.trim() : null);
            novoUsuario.setTelefone(telefone != null ? CpfUtil.desformatar(telefone) : null);
            novoUsuario.setDataNascimento(dataNasc);
            novoUsuario.setAtivo(ativo);
            novoUsuario.setSenhaHash(senha != null && !senha.isBlank() ? senha : "123456");

            usuarioDAO.inserir(novoUsuario);
        }

        // Sincronização de Perfis
        sincronizarPerfis(cpfClean, perfisSelecionados);

        // Sincronização de Unidades
        sincronizarUnidades(cpfClean, unidadesSelecionadas);

        response.sendRedirect(request.getContextPath() + "/usuarios?acao=listar&sucesso=salvo");
    }

    private void tratarExcluir(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUsuarios(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios de Administrador para excluir usuários.");
            tratarListar(request, response);
            return;
        }

        String cpfParam = request.getParameter("cpf");
        if (cpfParam != null && !cpfParam.isBlank()) {
            String cpfClean = CpfUtil.desformatar(cpfParam);
            usuarioDAO.deletar(cpfClean);
        }

        response.sendRedirect(request.getContextPath() + "/usuarios?acao=listar&sucesso=excluido");
    }

    private void tratarVincularUnidade(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String cpfClean = CpfUtil.desformatar(request.getParameter("cpf"));
        String idUnidadeStr = request.getParameter("idUnidade");

        if (cpfClean != null && idUnidadeStr != null) {
            try {
                int idUnidade = Integer.parseInt(idUnidadeStr);
                usuarioUnidadeDAO.vincular(cpfClean, idUnidade);
            } catch (NumberFormatException ignored) {}
        }

        response.sendRedirect(request.getContextPath() + "/usuarios?acao=editar&cpf=" + cpfClean);
    }

    private void tratarDesvincularUnidade(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String cpfClean = CpfUtil.desformatar(request.getParameter("cpf"));
        String idUnidadeStr = request.getParameter("idUnidade");

        if (cpfClean != null && idUnidadeStr != null) {
            try {
                int idUnidade = Integer.parseInt(idUnidadeStr);
                usuarioUnidadeDAO.desvincular(cpfClean, idUnidade);
            } catch (NumberFormatException ignored) {}
        }

        response.sendRedirect(request.getContextPath() + "/usuarios?acao=editar&cpf=" + cpfClean);
    }

    // ─── Métodos Auxiliares ───────────────────────────────────────────────────

    private void sincronizarPerfis(String cpfUsuario, String[] perfisSelecionados) throws SQLException {
        Set<PerfilUsuario> novosPerfis = new HashSet<>();
        if (perfisSelecionados != null) {
            for (String p : perfisSelecionados) {
                try {
                    novosPerfis.add(PerfilUsuario.valueOf(p.trim().toUpperCase()));
                } catch (IllegalArgumentException ignored) {}
            }
        }

        // Se nenhum perfil foi selecionado no cadastro de equipe, atribui ATENDENTE por padrão
        if (novosPerfis.isEmpty()) {
            novosPerfis.add(PerfilUsuario.ATENDENTE);
        }

        List<PerfilUsuario> perfisAtuais = perfilDAO.listarPerfis(cpfUsuario);

        // Remove os perfis desmarcados (mantendo PACIENTE se existir)
        for (PerfilUsuario pAtual : perfisAtuais) {
            if (!novosPerfis.contains(pAtual) && pAtual != PerfilUsuario.PACIENTE) {
                perfilDAO.remover(cpfUsuario, pAtual);
            }
        }

        // Adiciona novos perfis marcados
        for (PerfilUsuario pNovo : novosPerfis) {
            perfilDAO.adicionar(cpfUsuario, pNovo);
        }
    }

    private void sincronizarUnidades(String cpfUsuario, String[] unidadesSelecionadas) throws SQLException {
        Set<Integer> novasUnidades = new HashSet<>();
        if (unidadesSelecionadas != null) {
            for (String uId : unidadesSelecionadas) {
                try {
                    novasUnidades.add(Integer.parseInt(uId.trim()));
                } catch (NumberFormatException ignored) {}
            }
        }

        List<Integer> unidadesAtuais = usuarioUnidadeDAO.listarUnidadesDoUsuario(cpfUsuario);

        for (Integer uAtual : unidadesAtuais) {
            if (!novasUnidades.contains(uAtual)) {
                usuarioUnidadeDAO.desvincular(cpfUsuario, uAtual);
            }
        }

        for (Integer uNova : novasUnidades) {
            usuarioUnidadeDAO.vincular(cpfUsuario, uNova);
        }
    }

    private void prepararAtributosFormulario(HttpServletRequest request) throws SQLException {
        request.setAttribute("todosPerfis", PerfilUsuario.values());
        request.setAttribute("todasUnidades", unidadeDAO.listarTodas());
    }

    private void montarRascunhoEForward(HttpServletRequest request, HttpServletResponse response,
                                         String modo, String cpfRaw, String nome, String email,
                                         String especialidade, String telefone, String dataNascStr,
                                         String ativoStr) throws ServletException, IOException, SQLException {
        Usuario rascunho = new Usuario();
        rascunho.setCpf(cpfRaw);
        rascunho.setNome(nome);
        rascunho.setEmail(email);
        rascunho.setEspecialidade(especialidade);
        rascunho.setTelefone(telefone);
        rascunho.setAtivo(ativoStr == null || "true".equalsIgnoreCase(ativoStr) || "1".equals(ativoStr) || "on".equalsIgnoreCase(ativoStr));
        if (dataNascStr != null && !dataNascStr.isBlank()) {
            try {
                rascunho.setDataNascimento(LocalDate.parse(dataNascStr));
            } catch (DateTimeParseException ignored) {}
        }

        prepararAtributosFormulario(request);
        request.setAttribute("usuario", rascunho);
        request.setAttribute("modo", modo);
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
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
