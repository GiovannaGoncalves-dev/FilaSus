package br.com.filasus.controller;

import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.UnidadeDAO;
import br.com.filasus.dao.UsuarioUnidadeDAO;
import br.com.filasus.model.Unidade;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

/**
 * Cadastro de Unidades de Saúde — exclusivo do Administrador Geral.
 * A exclusão é bloqueada quando a unidade já tem mutirões ou usuários vinculados,
 * para não deixar histórico órfão.
 */
@WebServlet("/admin/unidades")
public class UnidadeController extends HttpServlet {

    private final UnidadeDAO unidadeDAO = new UnidadeDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final UsuarioUnidadeDAO usuarioUnidadeDAO = new UsuarioUnidadeDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!geral(req)) { resp.sendRedirect(req.getContextPath() + "/admin/dashboard"); return; }
        try {
            List<Unidade> unidades = unidadeDAO.listarTodas();
            req.setAttribute("unidades", unidades);
            String idEdicao = req.getParameter("editar");
            if (idEdicao != null && !idEdicao.isBlank()) {
                req.setAttribute("edicao", unidadeDAO.buscarPorId(Integer.parseInt(idEdicao)));
            }
        } catch (SQLException | NumberFormatException e) {
            req.setAttribute("erro", "Não foi possível carregar as unidades.");
        }
        flash(req);
        req.getRequestDispatcher("/jsp/admin/unidades.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!geral(req)) { resp.sendRedirect(req.getContextPath() + "/admin/dashboard"); return; }
        String acao = req.getParameter("acao");
        try {
            if ("excluir".equals(acao)) excluir(id(req));
            else salvar(req, acao);
            req.getSession().setAttribute("flashSucesso", "Operação realizada com sucesso.");
        } catch (Exception e) {
            req.getSession().setAttribute("flashErro", e.getMessage() == null
                    ? "Não foi possível realizar a operação." : e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/unidades");
    }

    private void salvar(HttpServletRequest req, String acao) throws SQLException {
        String nome = texto(req, "nome");
        if (nome.isEmpty()) throw new IllegalArgumentException("Informe o nome da unidade.");
        Unidade unidade = new Unidade();
        unidade.setNome(nome);
        unidade.setEndereco(texto(req, "endereco"));
        if ("editar".equals(acao)) {
            unidade.setId(id(req));
            if (unidadeDAO.buscarPorId(unidade.getId()) == null)
                throw new IllegalArgumentException("Unidade não encontrada.");
            unidadeDAO.atualizar(unidade);
        } else {
            unidadeDAO.inserir(unidade);
        }
    }

    private void excluir(int idUnidade) throws SQLException {
        Unidade unidade = unidadeDAO.buscarPorId(idUnidade);
        if (unidade == null) throw new IllegalArgumentException("Unidade não encontrada.");
        int mutiroes = mutiraoDAO.listarPorUnidade(idUnidade).size();
        int usuarios = usuarioUnidadeDAO.listarUsuariosDaUnidade(idUnidade).size();
        if (mutiroes > 0 || usuarios > 0) {
            throw new IllegalArgumentException("A unidade \"" + unidade.getNome() + "\" não pode ser excluída: "
                    + mutiroes + " mutirão(ões) e " + usuarios + " usuário(s) vinculados. "
                    + "Transfira ou remova esses vínculos antes de excluir.");
        }
        unidadeDAO.deletar(idUnidade);
    }

    private boolean geral(HttpServletRequest req) {
        return AuthUtil.checarPerfil(req, PerfilUsuario.ADM_GERAL);
    }

    private int id(HttpServletRequest req) {
        try {
            return Integer.parseInt(req.getParameter("idUnidade"));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Unidade inválida.");
        }
    }

    private String texto(HttpServletRequest req, String campo) {
        String valor = req.getParameter(campo);
        return valor == null ? "" : valor.trim();
    }

    private void flash(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return;
        for (String chave : List.of("flashSucesso", "flashErro")) {
            Object valor = session.getAttribute(chave);
            if (valor != null) { req.setAttribute(chave, valor); session.removeAttribute(chave); }
        }
    }
}
