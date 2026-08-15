<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*,br.com.filasus.model.enums.StatusItemFila" %>
<%!
private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");}
private String senha(ItemFila i){return "F"+i.getIdFila()+"-"+String.format("%03d",i.getSequenciaItemFila());}
private String nome(ItemFila i){return i.getPaciente()==null?i.getCpfPaciente():i.getPaciente().getNome();}
private String dataHora(java.time.LocalDateTime valor){return valor==null?"—":valor.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM HH:mm"));}
private String badge(StatusItemFila s){return s==StatusItemFila.ATENDIDO?"badge--emerald":s==StatusItemFila.AUSENTE?"badge--rose":"badge--slate";}
%>
<%
Usuario usuario=(Usuario)request.getAttribute("usuario");Mutirao mutirao=(Mutirao)request.getAttribute("mutirao");List<ItemFila> itens=(List<ItemFila>)request.getAttribute("itens");if(itens==null)itens=Collections.emptyList();
String ctx=request.getContextPath(),pageTitle="Histórico",activeNav="historico";String status=request.getParameter("status"),filaParam=request.getParameter("fila");
Map<Integer,String> filasHistorico=new LinkedHashMap<>();for(ItemFila i:itens)filasHistorico.put(i.getIdFila(),i.getFila()==null?"Fila "+i.getIdFila():i.getFila().getNome());
long total=itens.size(),totalAtendidos=itens.stream().filter(i->i.getStatus()==StatusItemFila.ATENDIDO).count(),totalAusentes=itens.stream().filter(i->i.getStatus()==StatusItemFila.AUSENTE).count();
int exibidos=0;for(ItemFila i:itens){if(status!=null&&!status.isBlank()&&!i.getStatus().name().equals(status))continue;if(filaParam!=null&&!filaParam.isBlank()&&!String.valueOf(i.getIdFila()).equals(filaParam))continue;exibidos++;}
%>
<%@ include file="/WEB-INF/jspf/atendente-shell-start.jspf" %>
<style>
.history-table-wrapper{overflow:auto;max-height:520px}.history-table th{position:sticky;top:0;background:var(--surface);z-index:1}.history-table th,.history-table td{white-space:nowrap}.history-table td.wrap{white-space:normal;word-break:break-word}.history-table .td-password{font-family:var(--font-mono);font-weight:700;color:var(--slate-800)}.history-table .td-priority-cell{display:flex;align-items:center;gap:6px;min-width:96px}.history-table .td-time-cell{font-size:12px;color:var(--text-muted)}.history-filters{display:flex;align-items:flex-end;gap:12px;flex-wrap:wrap}.history-filters .field__label{margin-bottom:4px}.history-filters .select,.history-filters .btn{height:38px}@media(max-width:768px){.hide-mobile{display:none}}
</style>
<div class="server-page-heading"><h1>Histórico de Atendimentos</h1><p><%=mutirao==null?"Registros do mutirão atual":h(mutirao.getTipo())%></p></div>
<form method="get" action="<%=ctx%>/atendente/historico" class="card mb-4">
  <div class="card__body history-filters">
    <div style="flex:1;min-width:200px"><label class="field__label" for="status-filter">Filtrar por status</label><select class="select" id="status-filter" name="status" style="min-width:200px"><option value="" <%=status==null||status.isBlank()?"selected":""%>>Todos (<%=total%>)</option><option value="ATENDIDO" <%="ATENDIDO".equals(status)?"selected":""%>>Atendidos (<%=totalAtendidos%>)</option><option value="AUSENTE" <%="AUSENTE".equals(status)?"selected":""%>>Ausentes (<%=totalAusentes%>)</option></select></div>
    <div style="flex:1;min-width:200px"><label class="field__label" for="queue-filter">Filtrar por fila</label><select class="select" id="queue-filter" name="fila" style="min-width:200px"><option value="">Todas as filas</option><%for(Map.Entry<Integer,String> f:filasHistorico.entrySet()){%><option value="<%=f.getKey()%>" <%=String.valueOf(f.getKey()).equals(filaParam)?"selected":""%>><%=h(f.getValue())%></option><%}%></select></div>
    <div class="flex gap-2" style="flex-wrap:wrap"><button class="btn btn--primary btn--sm"><%=ico("search")%> Aplicar filtros</button><a class="btn btn--ghost btn--sm" href="<%=ctx%>/atendente/historico"><%=ico("refresh")%><span class="hidden-mobile"> Limpar</span></a></div>
  </div>
</form>
<section class="card">
  <div class="card__header"><div><div class="card__title">Atendimentos</div><div class="card__description"><%=exibidos%> <%=exibidos==1?"registro":"registros"%></div></div><a class="btn btn--ghost btn--sm" href="<%=ctx%>/atendente/historico<%=(status!=null&&!status.isBlank())?"?status="+h(status):""%>"><%=ico("refresh")%> Atualizar</a></div>
  <%if(exibidos==0){%><div class="card__body"><div class="empty-state"><div class="empty-state__icon"><%=ico("history")%></div><div class="empty-state__title"><%=status==null||status.isBlank()?"Nenhum registro encontrado":"Nenhum registro para este filtro"%></div><div class="empty-state__message">Altere os filtros ou aguarde a conclusão de atendimentos.</div><a href="<%=ctx%>/atendente/fila" class="btn btn--outline btn--sm mt-4"><%=ico("list")%> Ir para a fila</a></div></div><%}else{%>
  <div class="card__body card__body--p0"><div class="history-table-wrapper"><table class="table history-table"><thead><tr><th>Senha</th><th>Paciente</th><th class="hide-mobile">Fila</th><th>Prioridade</th><th class="hide-mobile">Entrada</th><th class="hide-mobile">Conclusão</th><th>Status</th></tr></thead><tbody>
  <%for(ItemFila i:itens){if(status!=null&&!status.isBlank()&&!i.getStatus().name().equals(status))continue;if(filaParam!=null&&!filaParam.isBlank()&&!String.valueOf(i.getIdFila()).equals(filaParam))continue;boolean prioridade=i.getFila()!=null&&i.getFila().getTipo()!=null&&"PRIORITARIO".equals(i.getFila().getTipo().name());%>
    <tr><td class="td-password"><%=senha(i)%></td><td class="wrap"><div style="font-weight:500"><%=h(nome(i))%></div><div class="td-time-cell"><%=h(i.getCpfPaciente())%></div></td><td class="hide-mobile"><%=h(i.getFila()==null?"Fila "+i.getIdFila():i.getFila().getNome())%></td><td><div class="td-priority-cell"><span class="badge <%=prioridade?"badge--amber":"badge--slate"%>"><%=prioridade?ico("shield")+" Prioritário":"Comum"%></span></div></td><td class="hide-mobile td-time-cell"><%=dataHora(i.getEntradaEm())%></td><td class="hide-mobile td-time-cell"><%=dataHora(i.getAtualizadoEm())%></td><td><span class="badge <%=badge(i.getStatus())%>"><%=h(i.getStatus().getDescricao())%></span></td></tr>
  <%}%></tbody></table></div></div><%}%>
</section>
<%@ include file="/WEB-INF/jspf/atendente-shell-end.jspf" %>
