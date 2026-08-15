<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*,br.com.filasus.controller.AtendimentoController.AtendimentoView" %>
<%!private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");}private String hora(java.time.LocalDateTime d){return d==null?"—":d.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));}%>
<%Usuario medico=(Usuario)session.getAttribute("usuarioLogado");AtendimentoView atual=(AtendimentoView)request.getAttribute("atendimentoAtual");List<AtendimentoView> chamados=(List<AtendimentoView>)request.getAttribute("chamados");if(chamados==null)chamados=Collections.emptyList();int prioridadesPendentes=request.getAttribute("prioridadesPendentes")==null?0:(Integer)request.getAttribute("prioridadesPendentes");String ctx=request.getContextPath(),pageTitle="Painel do Médico",activeNav="dashboard";%>
<%@ include file="/WEB-INF/jspf/medico-shell-start.jspf" %>
<style>
@keyframes pulse-dot{0%,100%{box-shadow:0 0 0 0 rgba(16,185,129,.6)}50%{box-shadow:0 0 0 8px rgba(16,185,129,0)}}
.pulse-dot{width:8px;height:8px;border-radius:50%;background:var(--emerald-500);animation:pulse-dot 1.5s infinite;display:inline-block}.call-row{display:flex;align-items:center;gap:12px;padding:12px 16px;border-bottom:1px solid var(--border);transition:background .15s}.call-row:hover{background:var(--slate-50)}.call-row:last-child{border-bottom:0}.dash-grid{display:grid;grid-template-columns:1.4fr 1fr;gap:16px}.greeting-icon{width:52px;height:52px;border-radius:50%;background:var(--teal-100);color:var(--teal-700);display:flex;align-items:center;justify-content:center;flex-shrink:0}.greeting-icon svg{width:26px;height:26px}@media(max-width:1024px){.dash-grid{grid-template-columns:1fr}}@media(max-width:700px){.call-row{align-items:flex-start;flex-wrap:wrap}.call-row form{width:100%}.call-row .btn{width:100%}}
</style>
<%if(request.getAttribute("flashSucesso")!=null){%>
<div class="alert alert--success mb-4">
<%=h(request.getAttribute("flashSucesso"))%>
</div>
<%}if(request.getAttribute("flashErro")!=null||request.getAttribute("erro")!=null){%>
<div class="alert alert--danger mb-4">
<%=h(request.getAttribute("flashErro")!=null?request.getAttribute("flashErro"):request.getAttribute("erro"))%>
</div>
<%}%>
<div class="card mb-6" style="background:linear-gradient(135deg,var(--teal-50),var(--emerald-50));border-color:var(--teal-200)">
<div class="card__body">
<div class="flex items-center justify-between" style="gap:16px;flex-wrap:wrap">
<div style="min-width:0">
<div class="text-sm text-muted" style="font-weight:500">Olá,</div>
<h1 style="font-size:24px;font-weight:700;margin-top:2px;overflow:hidden;text-overflow:ellipsis">
<%=h(medico==null?"Médico":medico.getNome())%>
</h1>
<div class="flex items-center gap-2 mt-3" style="flex-wrap:wrap">
<span class="badge badge--emerald">
<%=h(medico!=null&&medico.getEspecialidade()!=null?medico.getEspecialidade():"Médico")%>
</span>
<span class="text-sm text-muted">Unidade de atendimento ativa</span>
</div>
</div>
<div class="greeting-icon">
<%=ico("stethoscope")%>
</div>
</div>
</div>
</div>
<%if(atual!=null){%>
<div class="card mb-6" style="border-color:var(--emerald-300);background:linear-gradient(135deg,#fff,var(--emerald-50))">
<div class="card__body">
<div class="flex items-center gap-2 mb-3">
<span class="pulse-dot">
</span>
<span class="text-sm font-semibold" style="color:var(--emerald-700);text-transform:uppercase;letter-spacing:.05em">Em atendimento agora</span>
</div>
<div class="flex items-center justify-between" style="gap:16px;flex-wrap:wrap">
<div style="min-width:0">
<div class="font-mono font-bold" style="font-size:36px;color:var(--emerald-700);line-height:1">
<%=h(atual.senha())%>
</div>
<div class="text-md font-medium mt-2">
<%=h(atual.paciente==null?"Paciente":atual.paciente.getNome())%>
</div>
<div class="text-sm text-muted mt-2">
<%=h(atual.fila==null?"Fila":atual.fila.getNome())%>
<%=atual.paciente==null?"":" · CPF "+h(atual.paciente.getCpfFormatado())%>
</div>
<div class="text-xs text-muted mt-3">
<%=ico("clock")%> Iniciado às <%=hora(atual.atendimento.getInicio())%>
</div>
</div>
<div class="flex gap-2" style="flex-wrap:wrap">
<a href="<%=ctx%>/medico/atendimento" class="btn btn--primary btn--lg">
<%=ico("stethoscope")%> Ver atendimento</a>
<form method="post" action="<%=ctx%>/medico/atendimento">
<input type="hidden" name="acao" value="finalizar">
<input type="hidden" name="destino" value="dashboard">
<input type="hidden" name="idAtendimento" value="<%=atual.atendimento.getId()%>">
<button class="btn btn--outline btn--lg" onclick="return confirm('Finalizar este atendimento?')">
<%=ico("check")%> Finalizar</button>
</form>
</div>
</div>
</div>
</div>
<%}%>
<div class="grid grid-4 mb-6">
<div class="stat-card">
<div class="stat-card__icon stat-card__icon--emerald">
<%=ico("check")%>
</div>
<div class="stat-card__label">Atendidos hoje</div>
<div class="stat-card__value">
<%=request.getAttribute("atendidosHoje")%>
</div>
<div class="stat-card__hint">pacientes neste mutirão</div>
</div>
<div class="stat-card">
<div class="stat-card__icon stat-card__icon--teal">
<%=ico("clock")%>
</div>
<div class="stat-card__label">Tempo médio</div>
<div class="stat-card__value">
<%=request.getAttribute("mediaMinutos")%> min</div>
<div class="stat-card__hint">por atendimento</div>
</div>
<div class="stat-card">
<div class="stat-card__icon stat-card__icon--amber">
<%=ico("shield")%>
</div>
<div class="stat-card__label">Validações pendentes</div>
<div class="stat-card__value">
<%=prioridadesPendentes%>
</div>
<div class="stat-card__hint">aguardando análise</div>
</div>
<div class="stat-card">
<div class="stat-card__icon stat-card__icon--violet">
<%=ico("activity")%>
</div>
<div class="stat-card__label">Chamados aguardando</div>
<div class="stat-card__value">
<%=chamados.size()%>
</div>
<div class="stat-card__hint">prontos para atendimento</div>
</div>
</div>
<div class="dash-grid">
<section>
<div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
<h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
<span style="color:var(--violet-600)">
<%=ico("activity")%>
</span> Fila de chamados</h2>
<span class="badge badge--violet">
<%=chamados.size()%> aguardando</span>
</div>
<%if(chamados.isEmpty()){%>
<div class="card">
<div class="empty-state">
<div class="empty-state__icon" style="background:var(--violet-50);color:var(--violet-600)">
<%=ico("check")%>
</div>
<div class="empty-state__title">Nenhum chamado aguardando</div>
<div class="empty-state__message">
<%=atual!=null?"Você já está com um paciente em atendimento. Finalize-o para iniciar o próximo.":"Todos os pacientes chamados já estão em atendimento ou foram atendidos."%>
</div>
</div>
</div>
<%}else{%>
<div class="card" style="padding:0">
<div style="max-height:480px;overflow-y:auto" class="custom-scroll">
<%for(AtendimentoView v:chamados){%>
<div class="call-row">
<div class="font-mono font-bold" style="font-size:16px;color:var(--violet-600);min-width:72px">
<%=h(v.senha())%>
</div>
<div style="flex:1;min-width:0">
<div style="font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
<%=h(v.paciente==null?"Paciente":v.paciente.getNome())%>
</div>
<div class="text-xs text-muted">
<%=h(v.fila==null?"Fila":v.fila.getNome())%>
</div>
</div>
<%if(v.documento!=null){%>
<span class="badge badge--amber">Prioritário</span>
<%}%>
<form method="post" action="<%=ctx%>/medico/atendimento">
<input type="hidden" name="acao" value="iniciar">
<input type="hidden" name="destino" value="dashboard">
<input type="hidden" name="idFila" value="<%=v.item.getIdFila()%>">
<input type="hidden" name="sequencia" value="<%=v.item.getSequenciaItemFila()%>">
<button class="btn btn--primary btn--sm" <%=atual!=null?"disabled title=\"Finalize o atendimento atual primeiro\"":""%>>
<%=ico("play")%> Iniciar atendimento</button>
</form>
</div>
<%}%>
</div>
</div>
<%}%>
</section>
<section>
<div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
<h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
<span style="color:var(--amber-600)">
<%=ico("shield")%>
</span> Validações pendentes</h2>
<a href="<%=ctx%>/medico/prioridades" class="btn btn--ghost btn--sm">Ver todas <%=ico("arrowRight")%>
</a>
</div>
<div class="card">
<%if(prioridadesPendentes==0){%>
<div class="empty-state">
<div class="empty-state__icon" style="background:var(--emerald-50);color:var(--emerald-600)">
<%=ico("check")%>
</div>
<div class="empty-state__title">Tudo em dia</div>
<div class="empty-state__message">Nenhuma validação de prioridade pendente no momento.</div>
</div>
<%}else{%>
<div class="card__body">
<div class="flex items-center gap-3">
<div class="stat-card__icon stat-card__icon--amber">
<%=ico("shield")%>
</div>
<div>
<strong>
<%=prioridadesPendentes%> solicitação(ões)</strong>
<div class="text-sm text-muted mt-2">Documentos aguardando sua análise médica.</div>
</div>
</div>
<a href="<%=ctx%>/medico/prioridades" class="btn btn--outline btn--block mt-4">
<%=ico("shield")%> Analisar solicitações</a>
</div>
<%}%>
</div>
</section>
</div>
<%@ include file="/WEB-INF/jspf/medico-shell-end.jspf" %>
