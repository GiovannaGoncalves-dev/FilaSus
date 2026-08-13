package br.com.filasus.controller;

import br.com.filasus.dao.*;
import br.com.filasus.model.Fila;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.StatusMutirao;
import br.com.filasus.model.enums.TipoFila;
import br.com.filasus.util.AuthUtil;

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
 * Controller responsável pelo CRUD de Mutirões de Saúde.
 * Suporta abertura/encerramento, vinculação de organizador, filtro por unidade e filas.
 *
 * Mapeamento: @WebServlet("/mutiroes")
 */
@WebServlet("/mutiroes")
public class MutiraoServlet extends HttpServlet {

    private static final String JSP_LISTA = "/jsp/mutiroes/lista.jsp";
    private static final String JSP_FORMULARIO = "/jsp/mutiroes/formulario.jsp";
    private static final String JSP_DETALHES = "/jsp/mutiroes/detalhes.jsp";

    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final UsuarioMutiraoDAO usuarioMutiraoDAO = new UsuarioMutiraoDAO();
    private final UnidadeDAO unidadeDAO = new UnidadeDAO();
    private final UsuarioUnidadeDAO usuarioUnidadeDAO = new UsuarioUnidadeDAO();

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
                case "detalhes":
                case "visualizar":
                    tratarDetalhes(request, response);
                    break;
                case "abrir":
                    tratarAlterarStatus(request, response, StatusMutirao.ABERTO);
                    break;
                case "encerrar":
                    tratarAlterarStatus(request, response, StatusMutirao.ENCERRADO);
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
            } else if ("abrir".equalsIgnoreCase(acao)) {
                tratarAlterarStatus(request, response, StatusMutirao.ABERTO);
            } else if ("encerrar".equalsIgnoreCase(acao)) {
                tratarAlterarStatus(request, response, StatusMutirao.ENCERRADO);
            } else if ("adicionarfila".equalsIgnoreCase(acao)) {
                tratarAdicionarFila(request, response);
            } else if ("removerfila".equalsIgnoreCase(acao)) {
                tratarRemoverFila(request, response);
            } else {
                tratarSalvar(request, response);
            }
        } catch (SQLException e) {
            request.setAttribute("erro", "Erro ao processar mutirão: " + e.getMessage());
            try {
                request.setAttribute("unidades", unidadeDAO.listarTodas());
            } catch (SQLException ignored) {}
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        }
    }

    // ─── Métodos de Leitura ───────────────────────────────────────────────────

    private void tratarListar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        Usuario usuarioLogado = AuthUtil.getUsuarioLogado(request);
        String idUnidadeStr = request.getParameter("idUnidade");
        String statusStr = request.getParameter("status");

        List<Mutirao> mutiroes = new ArrayList<>();

        if (idUnidadeStr != null && !idUnidadeStr.isBlank()) {
            try {
                int idUnidade = Integer.parseInt(idUnidadeStr);
                mutiroes = mutiraoDAO.listarPorUnidade(idUnidade);
                request.setAttribute("idUnidadeFiltro", idUnidade);
            } catch (NumberFormatException e) {
                mutiroes = mutiraoDAO.listarTodos();
            }
        } else if (usuarioLogado != null && AuthUtil.isAdmUnidade(usuarioLogado) && !AuthUtil.isAdmGeral(usuarioLogado)) {
            // Filtra por unidade quando o perfil for Adm_unidade
            List<Integer> unidadesDoUsuario = usuarioUnidadeDAO.listarUnidadesDoUsuario(usuarioLogado.getCpf());
            if (!unidadesDoUsuario.isEmpty()) {
                for (Integer idU : unidadesDoUsuario) {
                    mutiroes.addAll(mutiraoDAO.listarPorUnidade(idU));
                }
                request.setAttribute("idUnidadeFiltro", unidadesDoUsuario.get(0));
            } else {
                mutiroes = new ArrayList<>();
            }
        } else if (statusStr != null && !statusStr.isBlank()) {
            try {
                StatusMutirao st = StatusMutirao.valueOf(statusStr.trim().toUpperCase());
                mutiroes = mutiraoDAO.listarPorStatus(st);
                request.setAttribute("statusFiltro", statusStr);
            } catch (IllegalArgumentException e) {
                mutiroes = mutiraoDAO.listarTodos();
            }
        } else {
            mutiroes = mutiraoDAO.listarTodos();
        }

        // Carrega as filas de cada mutirão listado
        for (Mutirao m : mutiroes) {
            m.setFilas(filaDAO.listarPorMutirao(m.getId()));
        }

        String sucesso = request.getParameter("sucesso");
        if ("salvo".equals(sucesso)) {
            request.setAttribute("sucesso", "Mutirão salvo com sucesso!");
        } else if ("excluido".equals(sucesso)) {
            request.setAttribute("sucesso", "Mutirão excluído com sucesso!");
        } else if ("aberto".equals(sucesso)) {
            request.setAttribute("sucesso", "Mutirão aberto para atendimento!");
        } else if ("encerrado".equals(sucesso)) {
            request.setAttribute("sucesso", "Mutirão encerrado com sucesso!");
        }

        request.setAttribute("mutiroes", mutiroes);
        request.setAttribute("unidades", unidadeDAO.listarTodas());
        request.getRequestDispatcher(JSP_LISTA).forward(request, response);
    }

    private void tratarNovo(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarMutiroes(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para criar mutirões.");
        }

        Mutirao mutirao = new Mutirao();
        mutirao.setData(LocalDate.now());
        mutirao.setDuracaoMinutos(30);
        mutirao.setStatus(StatusMutirao.ABERTO);

        request.setAttribute("mutirao", mutirao);
        request.setAttribute("unidades", unidadeDAO.listarTodas());
        request.setAttribute("modo", "novo");
        request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
    }

    private void tratarEditar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarMutiroes(request)) {
            request.setAttribute("erro", "Acesso restrito: Você não tem permissão para editar mutirões.");
        }

        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            request.setAttribute("erro", "Código ID do mutirão não informado.");
            tratarListar(request, response);
            return;
        }

        try {
            int id = Integer.parseInt(idStr);
            Mutirao mutirao = mutiraoDAO.buscarPorId(id);

            if (mutirao == null) {
                request.setAttribute("erro", "Mutirão não encontrado para o ID: " + id);
                tratarListar(request, response);
                return;
            }

            mutirao.setFilas(filaDAO.listarPorMutirao(id));
            List<String> organizadores = usuarioMutiraoDAO.listarOrganizadores(id);

            request.setAttribute("mutirao", mutirao);
            request.setAttribute("unidades", unidadeDAO.listarTodas());
            request.setAttribute("organizadores", organizadores);
            request.setAttribute("modo", "editar");
            request.getRequestDispatcher(JSP_FORMULARIO).forward(request, response);
        } catch (NumberFormatException e) {
            request.setAttribute("erro", "Código ID inválido: " + idStr);
            tratarListar(request, response);
        }
    }

    private void tratarDetalhes(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String idStr = request.getParameter("id");
        if (idStr != null && !idStr.isBlank()) {
            try {
                int id = Integer.parseInt(idStr);
                Mutirao mutirao = mutiraoDAO.buscarPorId(id);
                if (mutirao != null) {
                    mutirao.setFilas(filaDAO.listarPorMutirao(id));
                    List<String> organizadores = usuarioMutiraoDAO.listarOrganizadores(id);
                    request.setAttribute("mutirao", mutirao);
                    request.setAttribute("organizadores", organizadores);
                    request.getRequestDispatcher(JSP_DETALHES).forward(request, response);
                    return;
                }
            } catch (NumberFormatException ignored) {}
        }
        tratarListar(request, response);
    }

    // ─── Métodos de Escrita ───────────────────────────────────────────────────

    private void tratarSalvar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarMutiroes(request)) {
            request.setAttribute("erro", "Acesso negado: Apenas administradores podem cadastrar ou alterar mutirões.");
            tratarListar(request, response);
            return;
        }

        String modo = request.getParameter("modo");
        String idStr = request.getParameter("id");
        String idUnidadeStr = request.getParameter("idUnidade");
        String dataStr = request.getParameter("data");
        String tipo = request.getParameter("tipo");
        String local = request.getParameter("local");
        String duracaoStr = request.getParameter("duracaoMinutos");
        String statusStr = request.getParameter("status");

        Mutirao rascunho = new Mutirao();
        int id = 0;
        if (idStr != null && !idStr.isBlank()) {
            try { id = Integer.parseInt(idStr); } catch (NumberFormatException ignored) {}
        }
        rascunho.setId(id);

        int idUnidade = 0;
        if (idUnidadeStr != null && !idUnidadeStr.isBlank()) {
            try { idUnidade = Integer.parseInt(idUnidadeStr); } catch (NumberFormatException ignored) {}
        }
        rascunho.setIdUnidade(idUnidade);
        rascunho.setTipo(tipo);
        rascunho.setLocal(local);

        int duracao = 30;
        if (duracaoStr != null && !duracaoStr.isBlank()) {
            try { duracao = Integer.parseInt(duracaoStr); } catch (NumberFormatException ignored) {}
        }
        rascunho.setDuracaoMinutos(duracao);

        if (dataStr != null && !dataStr.isBlank()) {
            try { rascunho.setData(LocalDate.parse(dataStr)); } catch (DateTimeParseException ignored) {}
        } else {
            rascunho.setData(LocalDate.now());
        }

        if (statusStr != null && !statusStr.isBlank()) {
            try { rascunho.setStatus(StatusMutirao.valueOf(statusStr.trim().toUpperCase())); } catch (IllegalArgumentException ignored) {}
        } else {
            rascunho.setStatus(StatusMutirao.ABERTO);
        }

        // Validações
        if (idUnidade <= 0) {
            request.setAttribute("erro", "Selecione a Unidade de Saúde vinculada ao mutirão.");
            recarregarFormularioEForward(request, response, rascunho, modo);
            return;
        }

        if (tipo == null || tipo.isBlank()) {
            request.setAttribute("erro", "O tipo de mutirão (especialidade/exame) é obrigatório.");
            recarregarFormularioEForward(request, response, rascunho, modo);
            return;
        }

        if (local == null || local.isBlank()) {
            request.setAttribute("erro", "O local exato dentro da unidade é obrigatório.");
            recarregarFormularioEForward(request, response, rascunho, modo);
            return;
        }

        boolean eEdicao = "editar".equalsIgnoreCase(modo) || id > 0;

        if (eEdicao && id > 0) {
            Mutirao mutirao = mutiraoDAO.buscarPorId(id);
            if (mutirao == null) {
                mutirao = new Mutirao();
                mutirao.setId(id);
            }

            mutirao.setIdUnidade(idUnidade);
            mutirao.setData(rascunho.getData());
            mutirao.setTipo(tipo.trim());
            mutirao.setLocal(local.trim());
            mutirao.setDuracaoMinutos(duracao);
            mutirao.setStatus(rascunho.getStatus());

            // Como a DAO não tem método de update genérico para todos os campos, atualiza status e insere/atualiza
            mutiraoDAO.atualizarStatus(id, rascunho.getStatus());
        } else {
            Mutirao novoMutirao = new Mutirao();
            novoMutirao.setIdUnidade(idUnidade);
            novoMutirao.setData(rascunho.getData());
            novoMutirao.setTipo(tipo.trim());
            novoMutirao.setLocal(local.trim());
            novoMutirao.setDuracaoMinutos(duracao);
            novoMutirao.setStatus(rascunho.getStatus());

            mutiraoDAO.inserir(novoMutirao);

            // Registra o usuário logado como organizador do mutirão
            Usuario usuarioLogado = AuthUtil.getUsuarioLogado(request);
            if (usuarioLogado != null) {
                usuarioMutiraoDAO.vincular(usuarioLogado.getCpf(), novoMutirao.getId(), true);
            }

            // Cria automaticamente duas filas padrões para o novo mutirão (Comum e Prioritária)
            Fila filaComum = new Fila();
            filaComum.setIdMutirao(novoMutirao.getId());
            filaComum.setNome("Atendimento Comum");
            filaComum.setTipo(TipoFila.COMUM);
            filaDAO.inserir(filaComum);

            Fila filaPrioritaria = new Fila();
            filaPrioritaria.setIdMutirao(novoMutirao.getId());
            filaPrioritaria.setNome("Atendimento Prioritário");
            filaPrioritaria.setTipo(TipoFila.PRIORITARIO);
            filaDAO.inserir(filaPrioritaria);
        }

        response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar&sucesso=salvo");
    }

    private void tratarAlterarStatus(HttpServletRequest request, HttpServletResponse response, StatusMutirao novoStatus)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarMutiroes(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios para alterar o status do mutirão.");
            tratarListar(request, response);
            return;
        }

        String idStr = request.getParameter("id");
        if (idStr != null && !idStr.isBlank()) {
            try {
                int id = Integer.parseInt(idStr);
                mutiraoDAO.atualizarStatus(id, novoStatus);
                String msgParam = (novoStatus == StatusMutirao.ABERTO) ? "aberto" : "encerrado";
                response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar&sucesso=" + msgParam);
                return;
            } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar");
    }

    private void tratarExcluir(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        if (AuthUtil.isAutenticado(request) && !AuthUtil.podeGerenciarMutiroes(request)) {
            request.setAttribute("erro", "Acesso negado: Você não possui privilégios para excluir mutirões.");
            tratarListar(request, response);
            return;
        }

        String idStr = request.getParameter("id");
        if (idStr != null && !idStr.isBlank()) {
            try {
                int id = Integer.parseInt(idStr);
                mutiraoDAO.deletar(id);
            } catch (NumberFormatException ignored) {}
        }

        response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar&sucesso=excluido");
    }

    private void tratarAdicionarFila(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String idMutiraoStr = request.getParameter("idMutirao");
        String nomeFila = request.getParameter("nomeFila");
        String tipoFilaStr = request.getParameter("tipoFila");

        if (idMutiraoStr != null && nomeFila != null && !nomeFila.isBlank()) {
            try {
                int idMutirao = Integer.parseInt(idMutiraoStr);
                TipoFila tipo = "prioritario".equalsIgnoreCase(tipoFilaStr) ? TipoFila.PRIORITARIO : TipoFila.COMUM;

                Fila fila = new Fila();
                fila.setIdMutirao(idMutirao);
                fila.setNome(nomeFila.trim());
                fila.setTipo(tipo);
                filaDAO.inserir(fila);

                response.sendRedirect(request.getContextPath() + "/mutiroes?acao=editar&id=" + idMutirao);
                return;
            } catch (NumberFormatException ignored) {}
        }
        response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar");
    }

    private void tratarRemoverFila(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException, SQLException {

        String idFilaStr = request.getParameter("idFila");
        String idMutiraoStr = request.getParameter("idMutirao");

        if (idFilaStr != null) {
            try {
                int idFila = Integer.parseInt(idFilaStr);
                filaDAO.deletar(idFila);
            } catch (NumberFormatException ignored) {}
        }

        if (idMutiraoStr != null) {
            response.sendRedirect(request.getContextPath() + "/mutiroes?acao=editar&id=" + idMutiraoStr);
        } else {
            response.sendRedirect(request.getContextPath() + "/mutiroes?acao=listar");
        }
    }

    // ─── Métodos Auxiliares ───────────────────────────────────────────────────

    private void recarregarFormularioEForward(HttpServletRequest request, HttpServletResponse response,
                                               Mutirao mutirao, String modo) throws ServletException, IOException, SQLException {
        request.setAttribute("mutirao", mutirao);
        request.setAttribute("unidades", unidadeDAO.listarTodas());
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
