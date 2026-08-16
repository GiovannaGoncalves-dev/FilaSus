package br.com.filasus.controller;

import br.com.filasus.dao.*;
import br.com.filasus.model.*;
import br.com.filasus.model.enums.StatusValidacaoDocumento;
import br.com.filasus.model.enums.PerfilUsuario;
import br.com.filasus.util.AuthUtil;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.util.*;

@WebServlet(urlPatterns={"/medico/prioridades","/documento/validar"})
public class ValidarPrioridadeController extends HttpServlet {
    private final DocumentoDAO documentoDAO=new DocumentoDAO(); private final UsuarioDAO usuarioDAO=new UsuarioDAO();
    private final FilaDAO filaDAO=new FilaDAO(); private final MutiraoDAO mutiraoDAO=new MutiraoDAO();
    public static final class PrioridadeView { public Documento documento; public Usuario paciente; public Fila fila; }
    @Override protected void doGet(HttpServletRequest req,HttpServletResponse resp)throws ServletException,IOException{
        Integer unidade=AuthUtil.getUnidadeAtiva(req); if(unidade==null||!AuthUtil.checarPerfil(req,PerfilUsuario.MEDICO)){resp.sendRedirect(req.getContextPath()+"/login");return;}
        try{List<PrioridadeView> lista=new ArrayList<>(); for(Documento d:documentoDAO.listarPorStatus(StatusValidacaoDocumento.PENDENTE)){
            Fila f=filaDoDocumento(d); if(f==null||mutiraoDAO.buscarPorId(f.getIdMutirao()).getIdUnidade()!=unidade)continue;
            PrioridadeView v=new PrioridadeView();v.documento=d;v.fila=f;v.paciente=usuarioDAO.buscarPorCpf(d.getCpfUsuario());lista.add(v);}
            req.setAttribute("pendentes",lista); transferirFlash(req);
        }catch(SQLException e){req.setAttribute("erro","Não foi possível carregar as solicitações.");}
        req.getRequestDispatcher("/jsp/medico/validar-prioridade.jsp").forward(req,resp);
    }
    @Override protected void doPost(HttpServletRequest req,HttpServletResponse resp)throws IOException{
        Usuario medico=AuthUtil.getUsuarioLogado(req);Integer unidade=AuthUtil.getUnidadeAtiva(req);
        try{int id=Integer.parseInt(req.getParameter("idDocumento"));Documento d=documentoDAO.buscarPorId(id);
            if(medico==null||unidade==null||!AuthUtil.checarPerfil(req,PerfilUsuario.MEDICO)||d==null||d.getStatusValidacao()!=StatusValidacaoDocumento.PENDENTE)throw new SecurityException("Solicitação inexistente ou já processada.");
            Fila f=filaDoDocumento(d);Mutirao m=f==null?null:mutiraoDAO.buscarPorId(f.getIdMutirao());if(m==null||m.getIdUnidade()!=unidade)throw new SecurityException("Solicitação de outra unidade.");
            String decisao=req.getParameter("decisao");StatusValidacaoDocumento status="aprovar".equals(decisao)?StatusValidacaoDocumento.APROVADO:"rejeitar".equals(decisao)?StatusValidacaoDocumento.REJEITADO:null;
            if(status==null)throw new IllegalArgumentException("Decisão inválida.");documentoDAO.validar(id,status,medico.getCpf());req.getSession().setAttribute("flashSucesso","Solicitação validada.");
        }catch(Exception e){req.getSession().setAttribute("flashErro",e.getMessage()==null?"Não foi possível validar.":e.getMessage());}
        resp.sendRedirect(req.getContextPath()+"/medico/prioridades");
    }
    private Fila filaDoDocumento(Documento d)throws SQLException{return d.getIdFila()==null?null:filaDAO.buscarPorId(d.getIdFila());}
    private void transferirFlash(HttpServletRequest r){HttpSession s=r.getSession(false);if(s==null)return;for(String k:List.of("flashSucesso","flashErro")){Object v=s.getAttribute(k);if(v!=null){r.setAttribute(k,v);s.removeAttribute(k);}}}
}
