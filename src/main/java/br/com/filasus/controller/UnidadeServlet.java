package br.com.filasus.controller;

import br.com.filasus.dao.UnidadeDAO;
import br.com.filasus.model.Unidade;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Controller responsável pelo CRUD de Unidades de Saúde.
 * Acesso restrito preferencialmente ao perfil ADM_GERAL.
 *
 * Mapeamento: @WebServlet("/unidades")
 */
@WebServlet("/unidades")
public class UnidadeServlet extends HttpServlet {

    private static final String JSP_LISTA = "/jsp/unidades/lista.jsp";
    private static final String JSP_FORMULARIO = "/jsp/unidades/formulario.jsp";

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
            } else {
                tratarSalvar(request, response);
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao salvar/excluir unidade: " + e.getMessage());
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        }
    }

    // ─── Ações de Leitura e Exibição ──────────────────────────────────────────

    private void tratarListar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUnidades(request)) {
            request.setAttribute("erro", "Acesso restrito: Apenas Administradores Gerais (Adm_geral) podem gerenciar Unidades de Saúde.");
        }

        String termo = request.getParameter("termo");
        if (termo == null || termo.isBlank()) {
            termo = request.getParameter("q");
        }

        List<Unidade> unidades;
        if (termo != null && !termo.isBlank()) {
            unidades = unidadeDAO.buscarPorTermo(termo.trim());
            request.setAttribute("termo", termo);
        } else {
            unidades = unidadeDAO.listarTodas();
        }

        String sucesso = request.getParameter("sucesso");
        if ("salvo".equals(sucesso)) {
            request.setAttribute("sucesso", "Unidade de saúde salva com sucesso!");
        } else if ("excluido".equals(sucesso)) {
            request.setAttribute("sucesso", "Unidade de saúde excluída com sucesso!");
        }

        request.setAttribute("unidades", unidades);
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void tratarNovo(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUnidades(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para cadastrar novas Unidades.");
        }

        Unidade unidade = new Unidade();
        request.setAttribute("unidade", unidade);
        request.setAttribute("modo", "novo");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    private void tratarEditar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUnidades(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para editar Unidades.");
        }

        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            request.setAttribute("erro", "Código ID da unidade não informado.");
            tratarListar(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            Unidade unidade = unidadeDAO.buscarPorId(id);

            if (unidade == null) {
                request.setAttribute("erro", "Unidade não encontrada para o código ID: " + id);
                tratarListar(request, response);
                return;
            }

            request.setAttribute("unidade", unidade);
            request.setAttribute("modo", "editar");
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        } catch (NumberFormatException e) {
            request.setAttribute("erro", "Código ID inválido: " + idStr);
            tratarListar(request, response);
        }
    }

    // ─── Ações de Escrita (Salvar e Excluir) ──────────────────────────────────

    private void tratarSalvar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUnidades(request)) {
            request.setAttribute("erro", "Acesso negado: Apenas Administradores Gerais podem cadastrar ou alterar Unidades.");
            tratarListar(request, response);
            return;
        }

        String modo = request.getParameter("modo");
        String idStr = request.getParameter("id");
        String nome = request.getParameter("nome");
        String endereco = request.getParameter("endereco");

        Unidade rascunho = new Unidade();
        if (idStr != null && !idStr.isBlank()) {
            try {
                rascunho.setId(Integer.parseInt(idStr));
            } catch (NumberFormatException ignored) {}
        }
        rascunho.setNome(nome);
        rascunho.setEndereco(endereco);

        if (nome == null || nome.isBlank()) {
            request.setAttribute("erro", "O nome da Unidade de Saúde é obrigatório.");
            request.setAttribute("unidade", rascunho);
            request.setAttribute("modo", modo);
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
            return;
        }

        boolean eEdicao = "editar".equalsIgnoreCase(modo) || (rascunho.getId() > 0);

        if (eEdicao && rascunho.getId() > 0) {
            Unidade unidade = unidadeDAO.buscarPorId(rascunho.getId());
            if (unidade == null) {
                unidade = new Unidade();
                unidade.setId(rascunho.getId());
            }
            unidade.setNome(nome.trim());
            unidade.setEndereco(endereco != null ? endereco.trim() : null);
            unidadeDAO.atualizar(unidade);
        } else {
            Unidade novaUnidade = new Unidade();
            novaUnidade.setNome(nome.trim());
            novaUnidade.setEndereco(endereco != null ? endereco.trim() : null);
            unidadeDAO.inserir(novaUnidade);
        }

        response.sendRedirect(request.getContextPath() + "/unidades?acao=listar&sucesso=salvo");
    }

    private void tratarExcluir(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarUnidades(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios de Administrador Geral para excluir Unidades.");
            tratarListar(request, response);
            return;
        }

        String idStr = request.getParameter("id");
        if (idStr != null && !idStr.isBlank()) {
            try {
                int id = Integer.parseInt(idStr);
                unidadeDAO.deletar(id);
            } catch (NumberFormatException ignored) {}
        }

        response.sendRedirect(request.getContextPath() + "/unidades?acao=listar&sucesso=excluido");
    }

    // ─── Métodos Auxiliares ───────────────────────────────────────────────────

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
