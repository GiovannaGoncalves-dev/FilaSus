<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*,br.com.filasus.controller.AtendimentoController.AtendimentoView" %>
<%!private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");}private String hora(java.time.LocalDateTime d){return d==null?"—":d.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));}%>
<%Usuario medico=(Usuario)session.getAttribute("usuarioLogado");AtendimentoView atual=(AtendimentoView)request.getAttribute("atendimentoAtual");List<AtendimentoView> chamados=(List<AtendimentoView>)request.getAttribute("chamados");if(chamados==null)chamados=Collections.emptyList();int prioridadesPendentes=request.getAttribute("prioridadesPendentes")==null?0:(Integer)request.getAttribute("prioridadesPendentes");String ctx=request.getContextPath(),pageTitle="Atendimento",activeNav="atendimento";%>
<%@ include file="/WEB-INF/jspf/medico-shell-start.jspf" %>
<style>
@keyframes pulse-ring{0%,100%{box-shadow:0 0 0 0 rgba(13,148,136,.5)}50%{box-shadow:0 0 0 10px rgba(13,148,136,0)}}.pulse-ring{animation:pulse-ring 1.6s infinite}.att-grid{display:grid;grid-template-columns:1.4fr 1fr;gap:16px;align-items:start}.info-row{display:flex;gap:10px;align-items:flex-start;padding:6px 0}.info-row__icon{color:var(--text-muted);flex-shrink:0;margin-top:2px}.info-row__label{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--text-muted);font-weight:600}.info-row__value{font-size:14px;font-weight:500}.doc-item{display:flex;align-items:center;gap:12px;padding:10px 12px;border:1px solid var(--border);border-radius:var(--radius);margin-bottom:8px}.doc-item__icon{width:36px;height:36px;border-radius:8px;background:var(--teal-50);color:var(--teal-700);display:flex;align-items:center;justify-content:center;flex-shrink:0}.doc-item__info{flex:1;min-width:0}.doc-item__name{font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.doc-item__desc{font-size:12px;color:var(--text-muted);margin-top:2px}.timeline{position:relative;padding-left:4px}.tl-step{display:flex;gap:14px;position:relative;padding-bottom:22px}.tl-step:last-child{padding-bottom:0}.tl-step:before{content:'';position:absolute;left:9px;top:22px;bottom:-4px;width:2px;background:var(--border)}.tl-step:last-child:before{display:none}.tl-step__node{width:20px;height:20px;border-radius:50%;flex-shrink:0;background:var(--slate-200);border:3px solid var(--surface);box-shadow:0 0 0 1px var(--border);margin-top:2px;z-index:1}.tl-step--done .tl-step__node{background:var(--emerald-500)}.tl-step--current .tl-step__node{background:var(--teal-500);box-shadow:0 0 0 1px var(--teal-200),0 0 0 5px var(--teal-100);animation:pulse-ring 1.6s infinite}.tl-step--pending .tl-step__node{background:var(--surface)}.tl-step--current .tl-step__title{color:var(--teal-700);font-weight:600}.tl-step__title{font-size:14px;font-weight:500}.tl-step__time{font-size:12px;color:var(--text-muted);margin-top:2px}.call-row{display:flex;align-items:center;gap:12px;padding:12px 16px;border-bottom:1px solid var(--border)}.call-row:hover{background:var(--slate-50)}.call-row:last-child{border-bottom:0}@media(max-width:1024px){.att-grid{grid-template-columns:1fr}}@media(max-width:700px){.call-row{align-items:flex-start;flex-wrap:wrap}.call-row form,.call-row .btn{width:100%}}
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
<div class="page-header">
<div>
<h1 class="page-header__title">
<%=atual!=null?"Atendimento em andamento":"Atendimento"%>
</h1>
<p class="page-header__subtitle">
<%=atual!=null?h(atual.fila==null?"Fila de atendimento":atual.fila.getNome()):"Pacientes chamados pelo atendente, aguardando início do atendimento médico"%>
</p>
</div>
<div class="page-header__actions">
<a href="<%=ctx%>/medico/dashboard" class="btn btn--outline btn--sm">
<%=ico("arrowLeft")%> Voltar ao painel</a>
</div>
</div>
<%if(atual!=null){Documento doc=atual.documento;%>
<div class="att-grid">
<div class="flex flex-col gap-4">
<section class="card">
<div class="card__header">
<div class="flex items-center gap-2">
<span class="pulse-ring" style="width:10px;height:10px;border-radius:50%;background:var(--teal-500);display:inline-block">
</span>
<div class="card__title">Paciente em atendimento</div>
</div>
<div class="font-mono font-bold" style="font-size:22px;color:var(--teal-700)">
<%=h(atual.senha())%>
</div>
</div>
<div class="card__body">
<h3 style="font-size:20px;font-weight:700;margin-bottom:12px">
<%=h(atual.paciente==null?"Paciente":atual.paciente.getNome())%>
</h3>
<div class="grid grid-2" style="gap:12px">
<div class="info-row">
<div class="info-row__icon">
<%=ico("idCard")%>
</div>
<div>
<div class="info-row__label">CPF</div>
<div class="info-row__value font-mono">
<%=h(atual.paciente==null?"—":atual.paciente.getCpfFormatado())%>
</div>
</div>
</div>
<div class="info-row">
<div class="info-row__icon">
<%=ico("list")%>
</div>
<div>
<div class="info-row__label">Fila</div>
<div class="info-row__value">
<%=h(atual.fila==null?"—":atual.fila.getNome())%>
</div>
</div>
</div>
</div>
<div class="flex items-center gap-2 mt-4" style="flex-wrap:wrap;padding-top:12px;border-top:1px solid var(--border)">
<%if(doc!=null){%>
<span class="badge badge--amber">Prioritário</span>
<span class="text-sm text-muted">Motivo: <strong style="color:var(--amber-700)">
<%=h(doc.getMotivoPrioridade())%>
</strong>
</span>
<%}else{%>
<span class="badge badge--slate">Comum</span>
<span class="text-sm text-muted">Atendimento comum</span>
<%}%>
<span class="badge badge--teal" style="margin-left:auto">Em atendimento</span>
</div>
</div>
</section>
<section class="card">
<div class="card__header">
<div class="card__title">
<%=ico("fileText")%> Documentos do paciente</div>
<span class="badge badge--slate">
<%=doc==null?0:1%> arquivo(s)</span>
</div>
<div class="card__body">
<%if(doc==null){%>
<div class="empty-state" style="padding:24px">
<div class="empty-state__icon" style="width:40px;height:40px">
<%=ico("fileText")%>
</div>
<div class="empty-state__title" style="font-size:14px">Nenhum documento enviado</div>
<div class="empty-state__message" style="font-size:12px">O paciente não anexou documentos para esta solicitação.</div>
</div>
<%}else{%>
<div class="doc-item">
<div class="doc-item__icon">
<%=ico("fileText")%>
</div>
<div class="doc-item__info">
<div class="doc-item__name">
<%=h(doc.getNomeOriginal())%>
</div>
<div class="doc-item__desc">
<%=h(doc.getDescricao())%>
</div>
</div>
<div class="text-xs text-muted">
<%=h(doc.getEnviadoEm())%>
</div>
</div>
<%}%>
</div>
</section>
<section class="card">
<div class="card__header">
<div class="card__title">
<%=ico("history")%> Linha do tempo</div>
</div>
<div class="card__body">
<div class="timeline">
<div class="tl-step tl-step--done">
<div class="tl-step__node">
</div>
<div>
<div class="tl-step__title">Entrada na fila</div>
<div class="tl-step__time">Senha <%=h(atual.senha())%> registrada</div>
</div>
</div>
<div class="tl-step tl-step--done">
<div class="tl-step__node">
</div>
<div>
<div class="tl-step__title">Chamado pelo atendente</div>
<div class="tl-step__time">Paciente encaminhado para consulta</div>
</div>
</div>
<div class="tl-step tl-step--current">
<div class="tl-step__node">
</div>
<div>
<div class="tl-step__title">Em atendimento <span class="badge badge--teal">agora</span>
</div>
<div class="tl-step__time">Iniciado às <%=hora(atual.atendimento.getInicio())%>
</div>
</div>
</div>
<div class="tl-step tl-step--pending">
<div class="tl-step__node">
</div>
<div>
<div class="tl-step__title" style="color:var(--text-muted)">Finalizado</div>
<div class="tl-step__time">Aguardando encerramento do atendimento</div>
</div>
</div>
</div>
</div>
</section>
</div>
<aside class="flex flex-col gap-4">
<div class="card" style="border-color:var(--emerald-200);background:linear-gradient(135deg,#fff,var(--emerald-50))">
<div class="card__body">
<div class="text-sm text-muted" style="font-weight:600;text-transform:uppercase;letter-spacing:.05em">Tempo de atendimento</div>
<div class="font-mono font-bold atendimento-cronometro" data-inicio="<%=h(atual.atendimento.getInicio())%>" style="font-size:24px;color:var(--emerald-700);margin-top:4px">00:00</div>
<div class="text-xs text-muted mt-2">Iniciado às <%=hora(atual.atendimento.getInicio())%></div>
<form method="post" action="<%=ctx%>/medico/atendimento">
<input type="hidden" name="acao" value="finalizar">
<input type="hidden" name="idAtendimento" value="<%=atual.atendimento.getId()%>">
<button class="btn btn--success btn--block btn--lg mt-4" onclick="return confirm('Finalizar este atendimento?')">
<%=ico("check")%> Finalizar atendimento</button>
</form>
<p class="text-xs text-muted text-center mt-3">O paciente será marcado como atendido e a senha será encerrada.</p>
</div>
</div>
<%if(doc!=null){%>
<div class="card">
<div class="card__header">
<div class="card__title">
<%=ico("shield")%> Prioridade</div>
</div>
<div class="card__body">
<span class="badge badge--amber">Prioritário</span>
<div class="text-sm mt-3">
<strong style="color:var(--amber-700)">
<%=h(doc.getMotivoPrioridade())%>
</strong>
</div>
<div class="text-xs text-muted mt-2">Validação: <%=h(doc.getStatusValidacao())%>
</div>
</div>
</div>
<%}%>
</aside>
</div>
<%}else{%>
<div class="card mb-6" style="background:linear-gradient(135deg,var(--amber-50),#fff);border-color:var(--amber-200)">
<div class="card__body flex items-center gap-3">
<div style="width:44px;height:44px;border-radius:50%;background:var(--amber-100);color:var(--amber-700);display:flex;align-items:center;justify-content:center;flex-shrink:0">
<%=ico("info")%>
</div>
<div>
<div style="font-weight:600;color:var(--amber-800)">Você não está com nenhum paciente em atendimento</div>
<div class="text-sm text-muted mt-2">Selecione um paciente abaixo para iniciar o atendimento. A senha será movida para “Em atendimento”.</div>
</div>
</div>
</div>
<div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
<h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
<span style="color:var(--violet-600)">
<%=ico("activity")%>
</span> Pacientes chamados aguardando atendimento</h2>
<span class="badge badge--violet">
<%=chamados.size()%> aguardando</span>
</div>
<%if(chamados.isEmpty()){%>
<div class="card">
<div class="empty-state">
<div class="empty-state__icon" style="background:var(--emerald-50);color:var(--emerald-600)">
<%=ico("check")%>
</div>
<div class="empty-state__title">Nenhum paciente aguardando</div>
<div class="empty-state__message">No momento não há pacientes chamados pelo atendente.</div>
<a href="<%=ctx%>/medico/dashboard" class="btn btn--outline mt-4">
<%=ico("dashboard")%> Ir para o painel</a>
</div>
</div>
<%}else{%>
<div class="card" style="padding:0;max-height:480px;overflow-y:auto">
<%for(AtendimentoView v:chamados){%>
<div class="call-row">
<div class="font-mono font-bold" style="font-size:18px;color:var(--violet-600);min-width:80px">
<%=h(v.senha())%>
</div>
<div style="flex:1;min-width:0">
<div style="font-size:15px;font-weight:500">
<%=h(v.paciente==null?"Paciente":v.paciente.getNome())%>
</div>
<div class="text-xs text-muted">
<%=h(v.fila==null?"Fila":v.fila.getNome())%>
<%=v.paciente==null?"":" · CPF "+h(v.paciente.getCpfFormatado())%>
</div>
</div>
<%if(v.documento!=null){%>
<span class="badge badge--amber">Prioritário</span>
<%}%>
<form method="post" action="<%=ctx%>/medico/atendimento">
<input type="hidden" name="acao" value="iniciar">
<input type="hidden" name="idFila" value="<%=v.item.getIdFila()%>">
<input type="hidden" name="sequencia" value="<%=v.item.getSequenciaItemFila()%>">
<button class="btn btn--primary">
<%=ico("play")%> Iniciar atendimento</button>
</form>
</div>
<%}%>
</div>
<%}%>
<%}%>
<script>(function(){var el=document.querySelector('.atendimento-cronometro');if(!el)return;var inicio=new Date(el.dataset.inicio);function atualizar(){var total=Math.max(0,Math.floor((Date.now()-inicio.getTime())/1000)),horas=Math.floor(total/3600),minutos=Math.floor(total%3600/60),segundos=total%60;el.textContent=(horas?String(horas).padStart(2,'0')+':':'')+String(minutos).padStart(2,'0')+':'+String(segundos).padStart(2,'0')}atualizar();setInterval(atualizar,1000)})()</script>
<%@ include file="/WEB-INF/jspf/medico-shell-end.jspf" %>
