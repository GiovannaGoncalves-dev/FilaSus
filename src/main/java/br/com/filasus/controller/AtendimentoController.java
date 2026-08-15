package br.com.filasus.controller;

import br.com.filasus.dao.*;
import br.com.filasus.model.*;
import br.com.filasus.model.enums.*;
import br.com.filasus.util.AuthUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.time.*;
import java.util.*;

@WebServlet(urlPatterns = {"/medico", "/medico/dashboard", "/medico/atendimento", "/atendimento"})
public class AtendimentoController extends HttpServlet {
    private final AtendimentoDAO atendimentoDAO = new AtendimentoDAO();
    private final ItemFilaDAO itemFilaDAO = new ItemFilaDAO();
    private final UsuarioDAO usuarioDAO = new UsuarioDAO();
    private final FilaDAO filaDAO = new FilaDAO();
    private final MutiraoDAO mutiraoDAO = new MutiraoDAO();
    private final DocumentoDAO documentoDAO = new DocumentoDAO();

    public static final class AtendimentoView {
        public Atendimento atendimento; public ItemFila item; public Usuario paciente;
        public Fila fila; public Documento documento;
        public String senha() { return "F" + item.getIdFila() + "-" + String.format("%03d", item.getSequenciaItemFila()); }
    }

    @Override protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Usuario medico = AuthUtil.getUsuarioLogado(req);
        Integer unidade = AuthUtil.getUnidadeAtiva(req);
        if (medico == null || unidade == null || !AuthUtil.checarPerfil(req, PerfilUsuario.MEDICO)) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
        try {
            Atendimento atual = atendimentoDAO.buscarEmAndamento(medico.getCpf());
            req.setAttribute("atendimentoAtual", atual == null ? null : enriquecer(atual));
            List<Atendimento> hoje = atendimentoDAO.listarFinalizadosHoje(medico.getCpf());
            req.setAttribute("atendidosHoje", hoje.size());
            long minutos = hoje.stream().filter(a -> a.getInicio() != null && a.getFim() != null)
                    .mapToLong(a -> Duration.between(a.getInicio(), a.getFim()).toMinutes()).sum();
            req.setAttribute("mediaMinutos", hoje.isEmpty() ? 0L : Math.round((double) minutos / hoje.size()));
            req.setAttribute("chamados", listarChamados(unidade));
            req.setAttribute("prioridadesPendentes", contarPendentes(unidade));
            transferirFlash(req);
        } catch (SQLException e) { req.setAttribute("erro", "Não foi possível carregar a área médica."); }
        String jsp = req.getServletPath().endsWith("dashboard") || req.getServletPath().equals("/medico")
                ? "/jsp/medico/dashboard.jsp" : "/jsp/medico/atendimento.jsp";
        req.getRequestDispatcher(jsp).forward(req, resp);
    }

    @Override protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        req.setCharacterEncoding("UTF-8");
        Usuario medico = AuthUtil.getUsuarioLogado(req);
        Integer unidade = AuthUtil.getUnidadeAtiva(req);
        String destino = req.getParameter("destino");
        String rota = "dashboard".equals(destino) ? "/medico/dashboard" : "/medico/atendimento";
        try {
            if (medico == null || unidade == null || !AuthUtil.checarPerfil(req, PerfilUsuario.MEDICO)) throw new SecurityException("Sessão médica inválida.");
            String acao = req.getParameter("acao");
            if ("iniciar".equals(acao)) iniciar(req, medico, unidade);
            else if ("finalizar".equals(acao)) finalizar(req, medico, unidade);
            else throw new IllegalArgumentException("Ação inválida.");
            req.getSession().setAttribute("flashSucesso", "Operação realizada com sucesso.");
        } catch (IllegalArgumentException | SQLException | SecurityException e) {
            req.getSession().setAttribute("flashErro", e.getMessage() == null ? "Não foi possível processar a operação." : e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + rota);
    }

    private void iniciar(HttpServletRequest req, Usuario medico, int unidade) throws SQLException {
        int idFila = inteiro(req, "idFila"), sequencia = inteiro(req, "sequencia");
        ItemFila item = itemFilaDAO.buscarPorChave(idFila, sequencia);
        exigirFilaDaUnidade(idFila, unidade);
        if (item == null || item.getStatus() != StatusItemFila.CHAMADO)
            throw new IllegalArgumentException("A senha não está chamada para atendimento.");
        Atendimento a = new Atendimento();
        a.setIdItemFila(sequencia); a.setIdFila(idFila); a.setSequenciaItemFila(sequencia);
        a.setCpfMedico(medico.getCpf()); atendimentoDAO.iniciarTransacional(a);
    }

    private void finalizar(HttpServletRequest req, Usuario medico, int unidade) throws SQLException {
        Atendimento a = atendimentoDAO.buscarPorId(inteiro(req, "idAtendimento"));
        if (a == null || !medico.getCpf().equals(a.getCpfMedico()) || !a.isEmAndamento())
            throw new SecurityException("Atendimento não pertence ao médico da sessão.");
        exigirFilaDaUnidade(a.getIdFila(), unidade);
        atendimentoDAO.finalizar(a.getId(), LocalDateTime.now());
        itemFilaDAO.atualizarStatus(a.getIdFila(), a.getSequenciaItemFila(), StatusItemFila.ATENDIDO);
    }

    private List<AtendimentoView> listarChamados(int unidade) throws SQLException {
        List<AtendimentoView> resultado = new ArrayList<>();
        for (Mutirao m : mutiraoDAO.listarPorUnidade(unidade)) if (m.getStatus() == StatusMutirao.ABERTO)
            for (Fila f : filaDAO.listarPorMutirao(m.getId()))
                for (ItemFila i : itemFilaDAO.listarPorFilaEStatus(f.getId(), List.of(StatusItemFila.CHAMADO))) {
                    AtendimentoView v = new AtendimentoView(); v.item=i; v.fila=f;
                    v.paciente=usuarioDAO.buscarPorCpf(i.getCpfPaciente()); v.documento=documentoDAO.buscarPorItem(i.getIdFila(), i.getSequenciaItemFila());
                    resultado.add(v);
                }
        return resultado;
    }
    private AtendimentoView enriquecer(Atendimento a) throws SQLException {
        AtendimentoView v = new AtendimentoView(); v.atendimento=a;
        v.item=itemFilaDAO.buscarPorChave(a.getIdFila(), a.getSequenciaItemFila());
        if (v.item != null) { v.paciente=usuarioDAO.buscarPorCpf(v.item.getCpfPaciente()); v.fila=filaDAO.buscarPorId(v.item.getIdFila()); v.documento=documentoDAO.buscarPorItem(v.item.getIdFila(), v.item.getSequenciaItemFila()); }
        return v;
    }
    private int contarPendentes(int unidade) throws SQLException {
        int n=0; for (Documento d : documentoDAO.listarPorStatus(StatusValidacaoDocumento.PENDENTE)) if (documentoDaUnidade(d, unidade)) n++; return n;
    }
    private boolean documentoDaUnidade(Documento d, int unidade) throws SQLException {
        if (d.getIdFila()==null) return false; Fila f=filaDAO.buscarPorId(d.getIdFila()); if(f==null)return false;
        Mutirao m=mutiraoDAO.buscarPorId(f.getIdMutirao()); return m!=null && m.getIdUnidade()==unidade;
    }
    private void exigirFilaDaUnidade(int idFila, int unidade) throws SQLException {
        Fila f=filaDAO.buscarPorId(idFila); Mutirao m=f==null?null:mutiraoDAO.buscarPorId(f.getIdMutirao());
        if(m==null || m.getIdUnidade()!=unidade) throw new SecurityException("Fila de outra unidade.");
    }
    private int inteiro(HttpServletRequest r,String nome){ try{return Integer.parseInt(r.getParameter(nome));}catch(Exception e){throw new IllegalArgumentException("Identificador inválido.");} }
    private void transferirFlash(HttpServletRequest r){ HttpSession s=r.getSession(false); if(s==null)return; for(String k:List.of("flashSucesso","flashErro")){Object v=s.getAttribute(k);if(v!=null){r.setAttribute(k,v);s.removeAttribute(k);}} }
}
