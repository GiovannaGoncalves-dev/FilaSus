package br.com.filasus.controller;

import br.com.filasus.dao.FilaDAO;
import br.com.filasus.dao.ItemFilaDAO;
import br.com.filasus.dao.MutiraoDAO;
import br.com.filasus.dao.UsuarioDAO;
import br.com.filasus.dao.UsuarioPerfilDAO;
import br.com.filasus.model.Fila;
import br.com.filasus.model.ItemFila;
import br.com.filasus.model.Mutirao;
import br.com.filasus.model.Usuario;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.model.enums.StatusItemFila;
import br.com.filasus.model.enums.StatusMutirao;
import br.com.filasus.util.AuthUtil;
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
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/atendente/dashboard", "/atendente/cadastrar-paciente",
        "/atendente/fila", "/atendente/historico", "/atendente/fila/status"})
public class AtendenteController extends HttpServlet {
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final UsuarioPerfilDAO perfilDAO = new UsuarioPerfilDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (!autorizar(request, response)) return;
        try {
            prepararBase(request);
            String path = request.getServletPath();
            if ("/atendente/cadastrar-paciente".equals(path)) prepararCadastro(request);
            else if ("/atendente/fila".equals(path)) prepararFila(request, false);
            else if ("/atendente/historico".equals(path)) prepararFila(request, true);
            else prepararFila(request, false);
            moverFlash(request);
            request.getRequestDispatcher(jsp(path)).forward(request, response);
        } catch (SQLException e) {
            throw new ServletException("Não foi possível carregar a área do atendente.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        if (!autorizar(request, response)) return;
        try {
            if ("/atendente/cadastrar-paciente".equals(request.getServletPath())) cadastrar(request);
            else if ("/atendente/fila/status".equals(request.getServletPath())) alterarStatus(request);
            else {
                response.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
                return;
            }
        } catch (IllegalArgumentException e) {
            flash(request, "erro", e.getMessage());
        } catch (SQLIntegrityConstraintViolationException e) {
            flash(request, "erro", "CPF ou e-mail já cadastrado.");
        } catch (SQLException e) {
            throw new ServletException("Não foi possível concluir a operação.", e);
        }
        String destino = "/atendente/fila/status".equals(request.getServletPath())
                ? "/atendente/fila" : "/atendente/cadastrar-paciente";
        String filaSelecionada = texto(request.getParameter("filaSelecionada"));
        if (destino.endsWith("/fila") && filaSelecionada.matches("\\d+")) destino += "?fila=" + filaSelecionada;
        response.sendRedirect(request.getContextPath() + destino);
    }

    private boolean autorizar(HttpServletRequest request, HttpServletResponse response) throws IOException {
        if (!AuthUtil.checarPerfil(request, PerfilUsuario.ATENDENTE)) {
            response.sendRedirect(request.getContextPath() + "/login");
            return false;
        }
        return true;
    }

    private void prepararBase(HttpServletRequest request) throws SQLException {
        Integer unidade = AuthUtil.getUnidadeAtiva(request);
        if (unidade == null) {
            request.setAttribute("usuario", AuthUtil.getUsuarioLogado(request));
            request.setAttribute("mutirao", null);
            request.setAttribute("filas", List.of());
            request.setAttribute("erro", "Selecione uma unidade para continuar.");
            return;
        }
        Mutirao ativo = null;
        for (Mutirao mutirao : mutiraoDAO.listarPorUnidade(unidade)) {
            if (mutirao.getStatus() == StatusMutirao.ABERTO) { ativo = mutirao; break; }
        }
        request.setAttribute("usuario", AuthUtil.getUsuarioLogado(request));
        request.setAttribute("mutirao", ativo);
        request.setAttribute("filas", ativo == null ? List.of() : filaDAO.listarPorMutirao(ativo.getId()));
    }

    private void prepararCadastro(HttpServletRequest request) throws SQLException {
        String busca = texto(request.getParameter("busca"));
        request.setAttribute("busca", busca);
        if (!busca.isBlank()) request.setAttribute("pacientes", usuarioDAO.buscarPacientes(busca));
    }

    private void prepararFila(HttpServletRequest request, boolean historico) throws SQLException {
        @SuppressWarnings("unchecked") List<Fila> filas = (List<Fila>) request.getAttribute("filas");
        List<ItemFila> itens = new ArrayList<>();
        for (Fila fila : filas) {
            for (ItemFila item : itemFilaDAO.listarPorFila(fila.getId())) {
                boolean encerrado = item.getStatus() == StatusItemFila.ATENDIDO
                        || item.getStatus() == StatusItemFila.AUSENTE;
                if (historico != encerrado) continue;
                item.setFila(fila);
                item.setPaciente(usuarioDAO.buscarPorCpf(item.getCpfPaciente()));
                itens.add(item);
            }
        }
        request.setAttribute("itens", itens);
        request.setAttribute("totalAguardando", itens.stream().filter(ItemFila::isAguardando).count());
        request.setAttribute("totalChamados", itens.stream().filter(i -> i.getStatus() == StatusItemFila.CHAMADO).count());
    }

    private void cadastrar(HttpServletRequest request) throws SQLException {
        String cpf = texto(request.getParameter("cpf")).replaceAll("\\D", "");
        String nome = texto(request.getParameter("nome"));
        String email = texto(request.getParameter("email"));
        String telefone = texto(request.getParameter("telefone")).replaceAll("\\D", "");
        String nascimento = texto(request.getParameter("dataNascimento"));
        String senha = texto(request.getParameter("senha"));
        if (cpf.length() != 11 || nome.length() < 3 || !email.contains("@") || telefone.length() < 10
                || nascimento.isBlank() || senha.length() < 8) {
            throw new IllegalArgumentException("Preencha corretamente CPF, nome, e-mail, telefone, nascimento e senha.");
        }
        if (usuarioDAO.existeCpf(cpf) || usuarioDAO.existeEmail(email))
            throw new IllegalArgumentException("CPF ou e-mail já cadastrado.");
        Usuario paciente = new Usuario();
        paciente.setCpf(cpf); paciente.setNome(nome); paciente.setEmail(email);
        paciente.setTelefone(telefone); paciente.setDataNascimento(LocalDate.parse(nascimento));
        paciente.setSenhaHash(PasswordUtil.hash(senha)); paciente.setAtivo(true);
        usuarioDAO.inserir(paciente);
        try { perfilDAO.adicionar(cpf, PerfilUsuario.PACIENTE); }
        catch (SQLException e) { usuarioDAO.deletar(cpf); throw e; }
        flash(request, "sucesso", "Paciente cadastrado com sucesso.");
    }

    private void alterarStatus(HttpServletRequest request) throws SQLException {
        int idFila = inteiro(request.getParameter("idFila"), "Fila inválida.");
        int sequencia = inteiro(request.getParameter("sequencia"), "Senha inválida.");
        Fila fila = filaDaUnidade(request, idFila);
        ItemFila item = itemFilaDAO.buscarPorChave(fila.getId(), sequencia);
        if (item == null) throw new IllegalArgumentException("Senha não encontrada.");
        String acao = texto(request.getParameter("acao"));
        if ("chamar_novamente".equals(acao) && item.getStatus() == StatusItemFila.CHAMADO) {
            if (!itemFilaDAO.repetirChamada(idFila, sequencia))
                throw new IllegalArgumentException("A senha não está disponível para nova chamada.");
        } else if ("ausente".equals(acao) && item.getStatus() == StatusItemFila.CHAMADO) {
            itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.AUSENTE);
        } else if ("aguardando".equals(acao)
                && (item.getStatus() == StatusItemFila.CHAMADO || item.getStatus() == StatusItemFila.AUSENTE)) {
            itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.AGUARDANDO);
        } else if ("remarcar".equals(acao)) {
            if (item.getStatus() != StatusItemFila.CHAMADO && item.getStatus() != StatusItemFila.AUSENTE)
                throw new IllegalArgumentException("Esta senha nao pode ser remarcada no estado atual.");
            itemFilaDAO.atualizarStatus(idFila, sequencia, StatusItemFila.AUSENTE);
            ItemFila novo = new ItemFila();
            novo.setId(new br.com.filasus.model.ItemFilaId(idFila, 0));
            novo.setCpfPaciente(item.getCpfPaciente()); novo.setStatus(StatusItemFila.AGUARDANDO);
            itemFilaDAO.inserir(novo);
        } else throw new IllegalArgumentException("Acao invalida para o estado atual da senha.");
        flash(request, "sucesso", "Situação da senha atualizada.");
    }

    private Fila filaDaUnidade(HttpServletRequest request, int idFila) throws SQLException {
        Fila fila = filaDAO.buscarPorId(idFila);
        Mutirao mutirao = fila == null ? null : mutiraoDAO.buscarPorId(fila.getIdMutirao());
        Integer unidade = AuthUtil.getUnidadeAtiva(request);
        if (mutirao == null || unidade == null || mutirao.getIdUnidade() != unidade)
            throw new IllegalArgumentException("Fila não pertence à unidade ativa.");
        return fila;
    }

    private String jsp(String path) {
        if (path.endsWith("cadastrar-paciente")) return "/jsp/atendente/cadastrar-paciente.jsp";
        if (path.endsWith("/fila")) return "/jsp/atendente/gerenciar-fila.jsp";
        if (path.endsWith("historico")) return "/jsp/atendente/historico.jsp";
        return "/jsp/atendente/dashboard.jsp";
    }
    private int inteiro(String valor, String erro) {
        try { return Integer.parseInt(valor); } catch (Exception e) { throw new IllegalArgumentException(erro); }
    }
    private String texto(String valor) { return valor == null ? "" : valor.trim(); }
    private void flash(HttpServletRequest r, String chave, String valor) { r.getSession().setAttribute("flash_" + chave, valor); }
    private void moverFlash(HttpServletRequest r) {
        for (String chave : List.of("sucesso", "erro")) {
            Object valor = r.getSession().getAttribute("flash_" + chave);
            if (valor != null) { r.setAttribute(chave, valor); r.getSession().removeAttribute("flash_" + chave); }
        }
    }
}
