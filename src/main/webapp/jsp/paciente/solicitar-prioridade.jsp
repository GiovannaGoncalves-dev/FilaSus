<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*,br.com.filasus.util.AuthUtil" %>
<%!private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}%>
<%List<ItemFila> itens=(List<ItemFila>)request.getAttribute("itens");List<Documento> documentos=(List<Documento>)request.getAttribute("documentos");if(itens==null)itens=Collections.emptyList();if(documentos==null)documentos=Collections.emptyList();Usuario paciente=AuthUtil.getUsuarioLogado(request);String nome=paciente==null?"Paciente":paciente.getNome();String ctx=request.getContextPath();%>
<%@ include file="/WEB-INF/jspf/icons.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FilaSUS — Solicitar Prioridade</title>
<link rel="stylesheet" href="<%=ctx%>/css/styles.css">
<style>
.criteria-banner{display:flex;align-items:flex-start;gap:14px;background:var(--amber-50);border:1px solid var(--amber-200);border-radius:12px;padding:16px 18px}.criteria-banner__icon{flex-shrink:0;width:38px;height:38px;border-radius:10px;background:var(--amber-100);color:var(--amber-700);display:flex;align-items:center;justify-content:center}.criteria-banner__title{font-size:14px;font-weight:600;color:var(--amber-800)}.criteria-list{list-style:none;padding:0;margin:8px 0 0;display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:4px 16px;font-size:12px;color:var(--amber-800)}.criteria-list li{display:flex;align-items:center;gap:6px}.criteria-list li:before{content:'';width:4px;height:4px;border-radius:50%;background:var(--amber-600);flex-shrink:0}.section-title{display:flex;align-items:center;gap:8px;font-size:16px;font-weight:600;margin-bottom:12px}.section-title__icon{display:inline-flex}.section-title__count{margin-left:auto;font-size:11px;color:var(--text-muted);font-weight:500}.priority-card{display:flex;flex-direction:column;gap:12px;padding:16px;background:var(--surface);border:1px solid var(--border);border-radius:12px}.priority-card__head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px}.priority-card__password{font-family:var(--font-mono);font-size:20px;font-weight:700;letter-spacing:.05em}.priority-card__queue{font-size:12px;color:var(--text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:2px}.priority-card__stats{display:grid;grid-template-columns:1fr 1fr;gap:10px;padding-top:10px;border-top:1px solid var(--border)}.priority-card__stat-label{font-size:11px;color:var(--text-muted)}.priority-card__stat-value{font-size:14px;font-weight:700;margin-top:2px}.requested-card{padding:16px;border-radius:12px;border:1px solid var(--border);border-left-width:4px;background:var(--surface);display:flex;flex-direction:column;gap:12px}.requested-card--pendente{border-left-color:var(--amber-500);background:var(--amber-50);border-color:var(--amber-200)}.requested-card--aprovada{border-left-color:var(--emerald-500);background:var(--emerald-50);border-color:var(--emerald-100)}.requested-card--rejeitada{border-left-color:var(--rose-500);background:var(--rose-50);border-color:var(--rose-100)}.requested-status{display:flex;align-items:flex-start;gap:12px}.requested-status__icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;flex-shrink:0}.requested-card--pendente .requested-status__icon{background:var(--amber-100);color:var(--amber-700)}.requested-card--aprovada .requested-status__icon{background:var(--emerald-100);color:var(--emerald-700)}.requested-card--rejeitada .requested-status__icon{background:var(--rose-100);color:var(--rose-700)}.requested-status__title{font-size:14px;font-weight:600}.requested-status__meta{font-size:12px;color:var(--text-muted);margin-top:2px}.upload-box{border:2px dashed var(--teal-200);border-radius:var(--radius-lg);padding:18px;background:var(--teal-50)}@media(max-width:640px){.criteria-list{grid-template-columns:1fr}.priority-card__stats{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="app-shell">
<header class="header">
<div class="header__title">
<button class="header__mobile-toggle" onclick="toggleMenu()" aria-label="Abrir menu"><%=ico("list")%></button>
<span>Solicitar Prioridade</span>
</div>
<div class="header__actions">
<a href="<%=ctx%>/painel" class="btn btn--outline btn--sm"><%=ico("tv")%> <span class="hidden-mobile">Painel</span>
</a>
</div>
</header>
<div class="app-shell__body">
<aside class="sidebar" id="sidebar">
<div class="sidebar__brand">
<div class="sidebar__brand-icon"><%=ico("heart")%></div>
<div>
<div style="font-weight:700">FilaSUS</div>
<div style="font-size:10px;color:var(--text-muted)">Fila de Atendimento</div>
</div>
</div>
<nav class="sidebar__nav">
<div>
<div class="sidebar__group-label">PACIENTE</div>
<a class="sidebar__item" href="<%=ctx%>/paciente/dashboard">
<span class="sidebar__item-icon"><%=ico("dashboard")%></span>
<span>Minha Fila</span>
</a>
<a class="sidebar__item" href="<%=ctx%>/paciente/meus-dados">
<span class="sidebar__item-icon"><%=ico("user")%></span>
<span>Meus Dados</span>
</a>
<a class="sidebar__item sidebar__item--active" href="<%=ctx%>/documento/solicitar">
<span class="sidebar__item-icon"><%=ico("shield")%></span>
<span>Solicitar Prioridade</span>
</a>
</div>
</nav>
<div class="sidebar__user">
<div class="sidebar__user-card">
<div class="avatar avatar--paciente">
<%=h(nome.substring(0,1).toUpperCase())%>
</div>
<div style="flex:1">
<div style="font-size:13px;font-weight:500">
<%=h(nome)%>
</div>
<div style="font-size:10px;color:var(--text-muted)">Paciente</div>
</div>
<form method="post" action="<%=ctx%>/logout">
<button class="btn btn--ghost btn--icon" title="Sair" aria-label="Sair"><%=ico("logout")%></button>
</form>
</div>
</div>
</aside>
<main class="main">
<div class="main__inner">
<div class="page-heading mb-6">
<div class="page-heading__copy">
<h1 class="page-heading__title">Solicitar Prioridade</h1>
<p class="page-heading__subtitle">Envie um documento comprobatório. A equipe médica avaliará a solicitação.</p>
</div>
</div>
<%if(request.getAttribute("sucesso")!=null){%>
<div class="alert alert--success mb-4">
<div>
<div class="alert__title">Solicitação enviada</div>
<div class="alert__message">
<%=h(request.getAttribute("sucesso"))%>
</div>
</div>
</div>
<%}%>
<%if(request.getAttribute("erro")!=null){%>
<div class="alert alert--danger mb-4">
<div>
<div class="alert__title">Não foi possível enviar</div>
<div class="alert__message">
<%=h(request.getAttribute("erro"))%>
</div>
</div>
</div>
<%}%>
<div class="criteria-banner">
<div class="criteria-banner__icon"><%=ico("alert")%></div>
<div style="flex:1;min-width:0"><div class="criteria-banner__title">Critérios de prioridade</div><ul class="criteria-list"><li>Pessoa idosa (60 anos ou mais)</li><li>Gestante ou puérpera</li><li>Pessoa com deficiência</li><li>Condição clínica prioritária</li><li>Outro motivo previsto em lei</li></ul></div>
</div>
<%if(itens.isEmpty()){%>
<div class="card" style="margin-top:24px">
<div class="empty-state">
<div class="empty-state__icon"><%=ico("shield")%></div>
<div class="empty-state__title">Nenhuma senha elegível</div>
<div class="empty-state__message">Você precisa possuir uma senha ativa para solicitar prioridade.</div>
</div>
</div>
<%}else{%>
<section style="margin-top:24px" aria-labelledby="eligible-title">
<h2 id="eligible-title" class="section-title"><span class="section-title__icon" style="color:var(--amber-600)"><%=ico("alert")%></span> Elegíveis para solicitação <span class="section-title__count"><%=itens.size()%> senha(s)</span></h2>
<div class="grid grid-2"><%for(ItemFila i:itens){%><article class="priority-card"><div class="priority-card__head"><div style="min-width:0"><div class="priority-card__password">F<%=i.getIdFila()%>-<%=String.format("%03d",i.getSequenciaItemFila())%></div><div class="priority-card__queue"><%=h(i.getFila()==null?"Fila":i.getFila().getNome())%></div></div><span class="badge badge--slate">Comum</span></div><div class="priority-card__stats"><div><div class="priority-card__stat-label">Tempo na fila</div><div class="priority-card__stat-value"><%=i.getTempoEsperaMinutos()%> min</div></div><div><div class="priority-card__stat-label">Situação</div><div class="priority-card__stat-value"><%=h(i.getStatus())%></div></div></div><button type="button" class="btn btn--primary btn--block" style="background:var(--amber-600);gap:8px" onclick="var s=document.getElementById('senha');s.value='<%=i.getIdFila()%>:<%=i.getSequenciaItemFila()%>';selecionarSenha(s.value);document.getElementById('form-solicitacao').scrollIntoView({behavior:'smooth',block:'start'});s.focus()"><%=ico("alert")%><span>Solicitar Prioridade</span></button></article><%}%></div>
</section>
<form method="post" enctype="multipart/form-data" action="<%=ctx%>/documento/solicitar">
<section class="card" id="form-solicitacao" style="margin-top:24px">
<div class="card__header">
<div>
<div class="card__title" style="display:flex;align-items:center;gap:8px"><span style="color:var(--amber-600)"><%=ico("fileText")%></span> Dados da solicitação</div>
<div class="card__description">Todos os campos são obrigatórios.</div>
</div>
</div>
<div class="card__body">
<div class="field">
<label class="field__label field__label--required" for="senha">Senha de atendimento</label>
<select class="select" id="senha" required onchange="selecionarSenha(this.value)">
<option value="">Selecione sua senha</option>
<%for(ItemFila i:itens){%>
<option value="<%=i.getIdFila()%>:<%=i.getSequenciaItemFila()%>">F<%=i.getIdFila()%>-<%=String.format("%03d",i.getSequenciaItemFila())%> — <%=h(i.getFila()==null?"Fila":i.getFila().getNome())%>
</option>
<%}%>
</select>
<input type="hidden" name="idFila" id="idFila">
<input type="hidden" name="sequencia" id="sequencia">
</div>
<div class="grid grid-2">
<div class="field">
<label class="field__label field__label--required" for="motivo">Motivo</label>
<select class="select" id="motivo" name="motivo" required>
<option value="">Selecione</option>
<option value="idoso">Pessoa idosa</option>
<option value="gestante">Gestante ou puérpera</option>
<option value="deficiencia">Pessoa com deficiência</option>
<option value="condicao_clinica">Condição clínica prioritária</option>
<option value="outro">Outro motivo legal</option>
</select>
</div>
<div class="field">
<label class="field__label field__label--required" for="tipo">Tipo do documento</label>
<select class="select" id="tipo" name="tipo" required>
<option value="relatorio">Relatório</option>
<option value="exame">Exame</option>
<option value="outro">Outro</option>
</select>
</div>
</div>
<div class="field">
<label class="field__label field__label--required" for="descricao">Descrição</label>
<textarea class="textarea" id="descricao" name="descricao" rows="3" maxlength="500" required>
</textarea>
</div>
<div class="upload-box">
<label class="field__label field__label--required" for="arquivo">Documento comprobatório</label>
<input class="input" id="arquivo" name="arquivo" type="file" accept=".pdf,.jpg,.jpeg,.png" required>
<div class="field__hint">PDF, JPG ou PNG, com até 10 MB.</div>
</div>
</div>
<div class="card__footer" style="justify-content:flex-end">
<button class="btn btn--primary" type="submit" style="background:var(--amber-600);gap:8px"><%=ico("check")%> Enviar solicitação</button>
</div>
</section>
</form>
<%}%>
<%if(!documentos.isEmpty()){%>
<section style="margin-top:24px" aria-labelledby="requested-title">
<h2 id="requested-title" class="section-title"><span class="section-title__icon" style="color:var(--primary)"><%=ico("clock")%></span> Solicitações enviadas <span class="section-title__count"><%=documentos.size()%> registro(s)</span></h2>
<div class="grid grid-2">
<%for(Documento d:documentos){if(d.getIdFila()==null)continue;%>
<%String st=d.getStatusValidacao()==null?"PENDENTE":d.getStatusValidacao().name();String visual="APROVADO".equals(st)?"aprovada":"REJEITADO".equals(st)?"rejeitada":"pendente";%>
<article class="requested-card requested-card--<%=visual%>">
<div class="priority-card__head"><div style="min-width:0"><div class="priority-card__password">F<%=d.getIdFila()%>-<%=String.format("%03d",d.getSequenciaItemFila())%></div><div class="priority-card__queue"><%=h(d.getMotivoPrioridade())%></div></div><span class="badge badge--amber">Prioritário</span></div>
<div class="requested-status"><div class="requested-status__icon"><%="APROVADO".equals(st)?ico("check"):"REJEITADO".equals(st)?ico("x"):ico("clock")%></div><div style="flex:1;min-width:0"><div class="requested-status__title"><%=h(d.getStatusValidacao())%></div><div class="requested-status__meta"><%=h(d.getDescricao())%></div><%if("PENDENTE".equals(st)){%><div class="requested-status__meta" style="margin-top:4px">Aguarde: um médico irá validar sua solicitação.</div><%}%></div></div>
</article>
<%}%>
</div>
</section>
<%}%>
</div>
</main>
</div>
<footer class="footer">FilaSUS © 2026 — Giovanna Gonçalves & Matheus Souza Rosa</footer>
</div>
<script>function selecionarSenha(v){var p=v.split(':');document.getElementById('idFila').value=p[0]||'';document.getElementById('sequencia').value=p[1]||''}function toggleMenu(){var s=document.getElementById('sidebar'),b=document.querySelector('.sidebar-backdrop'),o=!s.classList.contains('open');s.classList.toggle('open',o);s.classList.toggle('sidebar--mobile',o);document.body.classList.toggle('mobile-nav-open',o);if(o&&!b){b=document.createElement('div');b.className='sidebar-backdrop';b.onclick=toggleMenu;document.body.appendChild(b)}else if(!o&&b)b.remove()}</script>
</body>
</html>
