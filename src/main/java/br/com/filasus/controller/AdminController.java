package br.com.filasus.controller;

import br.com.filasus.dao.*;
import br.com.filasus.model.*;
import br.com.filasus.model.enums.*;
import br.com.filasus.util.*;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.*;

@WebServlet(urlPatterns={"/admin/dashboard","/admin/filas","/admin/mutiroes","/admin/usuarios","/admin/relatorios"})
public class AdminController extends HttpServlet {
 private final MutiraoDAO mutiraoDAO=new MutiraoDAO(); private final FilaDAO filaDAO=new FilaDAO(); private final ItemFilaDAO itemDAO=new ItemFilaDAO();
 private final UsuarioDAO usuarioDAO=new UsuarioDAO(); private final UsuarioPerfilDAO perfilDAO=new UsuarioPerfilDAO(); private final UsuarioUnidadeDAO usuarioUnidadeDAO=new UsuarioUnidadeDAO(); private final UnidadeDAO unidadeDAO=new UnidadeDAO();

 @Override protected void doGet(HttpServletRequest r,HttpServletResponse p)throws ServletException,IOException{
  if(!admin(r)){p.sendRedirect(r.getContextPath()+"/login");return;}
  try{
   List<Mutirao> todos=mutiroesPermitidos(r),ms=todos;
   if(r.getServletPath().endsWith("relatorios")&&r.getParameter("idMutirao")!=null&&!r.getParameter("idMutirao").isBlank())ms=List.of(exigirMutirao(r,num(r,"idMutirao")));
   List<Fila> fs=filas(ms);r.setAttribute("mutiroes",ms);r.setAttribute("todosMutiroes",todos);r.setAttribute("filas",fs);r.setAttribute("unidades",unidadesPermitidas(r));
   if(r.getServletPath().endsWith("usuarios"))r.setAttribute("usuarios",usuariosPermitidos(r));
   if(r.getServletPath().endsWith("dashboard")||r.getServletPath().endsWith("relatorios"))carregarMetricas(r,ms,fs);
   flash(r);
  }catch(SQLException|IllegalArgumentException|SecurityException e){r.setAttribute("erro",e.getMessage()==null?"Não foi possível carregar os dados administrativos.":e.getMessage());}
  String nome=r.getServletPath().substring(r.getServletPath().lastIndexOf('/')+1);
  if("mutiroes".equals(nome)) nome="multiroes"; // preserva o nome da tela visual original
  r.getRequestDispatcher("/jsp/admin/"+nome+".jsp").forward(r,p);
 }
 @Override protected void doPost(HttpServletRequest r,HttpServletResponse p)throws IOException{
  r.setCharacterEncoding("UTF-8");String rota=r.getServletPath();
  try{if(!admin(r))throw new SecurityException("Perfil sem permissão.");String a=r.getParameter("acao");
   if(rota.endsWith("filas"))fila(r,a);else if(rota.endsWith("mutiroes"))mutirao(r,a);else if(rota.endsWith("usuarios"))usuario(r,a);else throw new IllegalArgumentException("Operação inválida.");
   r.getSession().setAttribute("flashSucesso","Operação realizada com sucesso.");
  }catch(Exception e){r.getSession().setAttribute("flashErro",e.getMessage()==null?"Não foi possível realizar a operação.":e.getMessage());}
  p.sendRedirect(r.getContextPath()+rota);
 }
 private void fila(HttpServletRequest r,String a)throws SQLException{
  if("criar".equals(a)){int mid=num(r,"idMutirao");exigirMutirao(r,mid);Fila f=new Fila();f.setIdMutirao(mid);f.setNome(obrig(r,"nome"));f.setTipo(TipoFila.fromJson(r.getParameter("tipo")));filaDAO.inserir(f);}
  else{int id=num(r,"idFila");Fila f=exigirFila(r,id);if("editar".equals(a)){f.setNome(obrig(r,"nome"));f.setTipo(TipoFila.fromJson(r.getParameter("tipo")));filaDAO.atualizar(f);}else if("excluir".equals(a))filaDAO.deletar(id);else throw new IllegalArgumentException("Ação inválida.");}
 }
 private void mutirao(HttpServletRequest r,String a)throws SQLException{
  if("criar".equals(a)){int unidade=unidadeEscolhida(r);Mutirao m=new Mutirao();m.setIdUnidade(unidade);m.setTipo(obrig(r,"tipo"));m.setLocal(obrig(r,"local"));m.setData(LocalDate.parse(obrig(r,"data")));m.setDuracaoMinutos(num(r,"duracao"));m.setStatus(StatusMutirao.AGENDADO);mutiraoDAO.inserir(m);}
  else{int id=num(r,"idMutirao");exigirMutirao(r,id);StatusMutirao s=StatusMutirao.fromJson(r.getParameter("status"));mutiraoDAO.atualizarStatus(id,s);}
 }
 private void usuario(HttpServletRequest r,String a)throws SQLException{
  if("criar".equals(a)){String cpf=obrig(r,"cpf").replaceAll("\\D","");String email=obrig(r,"email"),senha=obrig(r,"senha");PerfilUsuario perfil=PerfilUsuario.fromJson(r.getParameter("perfil"));
   if(cpf.length()!=11||!email.contains("@")||senha.length()<8)throw new IllegalArgumentException("CPF, e-mail ou senha inválidos.");if(usuarioDAO.existeCpf(cpf)||usuarioDAO.existeEmail(email))throw new IllegalArgumentException("CPF ou e-mail já cadastrado.");
   if(!geral(r)&&perfil!=PerfilUsuario.ATENDENTE&&perfil!=PerfilUsuario.MEDICO)
       throw new SecurityException("O administrador de unidade só pode cadastrar atendentes e médicos.");
   Integer unidade=perfil==PerfilUsuario.PACIENTE?null:unidadeEscolhida(r);Usuario u=new Usuario();u.setCpf(cpf);u.setNome(obrig(r,"nome"));u.setEmail(email);u.setSenhaHash(PasswordUtil.hash(senha));u.setEspecialidade(r.getParameter("especialidade"));u.setAtivo(true);usuarioDAO.inserir(u);
   try{perfilDAO.adicionar(cpf,perfil);if(unidade!=null)usuarioUnidadeDAO.vincular(cpf,unidade);}catch(SQLException e){usuarioDAO.deletar(cpf);throw e;}
  }else if("alternar".equals(a)){Usuario u=usuarioDAO.buscarPorCpf(obrig(r,"cpf").replaceAll("\\D",""));exigirUsuario(r,u);u.setAtivo(!u.isAtivo());usuarioDAO.atualizar(u);}else throw new IllegalArgumentException("Ação inválida.");
 }
 private void carregarMetricas(HttpServletRequest r,List<Mutirao> ms,List<Fila> fs)throws SQLException{
  Map<String,Integer> por=new LinkedHashMap<>();int total=0;for(StatusItemFila s:StatusItemFila.values()){int n=0;for(Fila f:fs)n+=itemDAO.listarPorFilaEStatus(f.getId(),List.of(s)).size();por.put(s.getDescricao(),n);total+=n;}r.setAttribute("porStatus",por);r.setAttribute("totalItens",total);r.setAttribute("totalMutiroes",ms.size());r.setAttribute("totalFilas",fs.size());
 }
 private List<Mutirao> mutiroesPermitidos(HttpServletRequest r)throws SQLException{return geral(r)?mutiraoDAO.listarTodos():mutiraoDAO.listarPorUnidade(unidadeAtiva(r));}
 private List<Fila> filas(List<Mutirao> ms)throws SQLException{List<Fila>x=new ArrayList<>();for(Mutirao m:ms)x.addAll(filaDAO.listarPorMutirao(m.getId()));return x;}
 private List<Usuario> usuariosPermitidos(HttpServletRequest r)throws SQLException{Map<String,Usuario>x=new TreeMap<>();for(PerfilUsuario p:PerfilUsuario.values())for(Usuario u:usuarioDAO.listarPorPerfil(p))if(geral(r)||gerenciavelPorAdminUnidade(r,u))x.put(u.getCpf(),u);return new ArrayList<>(x.values());}
 private List<Unidade> unidadesPermitidas(HttpServletRequest r)throws SQLException{return geral(r)?unidadeDAO.listarTodas():List.of(unidadeDAO.buscarPorId(unidadeAtiva(r)));}
 private Mutirao exigirMutirao(HttpServletRequest r,int id)throws SQLException{Mutirao m=mutiraoDAO.buscarPorId(id);if(m==null||(!geral(r)&&m.getIdUnidade()!=unidadeAtiva(r)))throw new SecurityException("Mutirão de outra unidade.");return m;}
 private Fila exigirFila(HttpServletRequest r,int id)throws SQLException{Fila f=filaDAO.buscarPorId(id);if(f==null)throw new IllegalArgumentException("Fila inexistente.");exigirMutirao(r,f.getIdMutirao());return f;}
 private void exigirUsuario(HttpServletRequest r,Usuario u){if(u==null)throw new SecurityException("Usuario inexistente.");Usuario atual=AuthUtil.getUsuarioLogado(r);if(atual!=null&&atual.getCpf().equals(u.getCpf()))throw new SecurityException("Nao e permitido alterar a propria conta.");if(!geral(r)&&!gerenciavelPorAdminUnidade(r,u))throw new SecurityException("Usuario fora da hierarquia desta unidade.");}
 private boolean gerenciavelPorAdminUnidade(HttpServletRequest r,Usuario u){return u!=null&&!u.temPerfil(PerfilUsuario.ADM_GERAL)&&!u.temPerfil(PerfilUsuario.ADM_UNIDADE)&&!u.temPerfil(PerfilUsuario.PACIENTE)&&u.getUnidadeIds().contains(unidadeAtiva(r));}
 private int unidadeEscolhida(HttpServletRequest r)throws SQLException{int id=geral(r)?num(r,"idUnidade"):unidadeAtiva(r);if(unidadeDAO.buscarPorId(id)==null)throw new IllegalArgumentException("Unidade inválida.");return id;}
 private int unidadeAtiva(HttpServletRequest r){Integer x=AuthUtil.getUnidadeAtiva(r);if(x==null)throw new SecurityException("Selecione uma unidade.");return x;}
 private boolean geral(HttpServletRequest r){return AuthUtil.checarPerfil(r,PerfilUsuario.ADM_GERAL);} private boolean admin(HttpServletRequest r){return AuthUtil.checarPerfil(r,PerfilUsuario.ADM_GERAL,PerfilUsuario.ADM_UNIDADE);}
 private int num(HttpServletRequest r,String n){try{return Integer.parseInt(r.getParameter(n));}catch(Exception e){throw new IllegalArgumentException("Identificador inválido.");}} private String obrig(HttpServletRequest r,String n){String v=r.getParameter(n);if(v==null||v.isBlank())throw new IllegalArgumentException("Preencha todos os campos obrigatórios.");return v.trim();}
 private void flash(HttpServletRequest r){HttpSession s=r.getSession(false);if(s==null)return;for(String k:List.of("flashSucesso","flashErro")){Object v=s.getAttribute(k);if(v!=null){r.setAttribute(k,v);s.removeAttribute(k);}}}
}
