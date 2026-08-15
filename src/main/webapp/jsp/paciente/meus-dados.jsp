<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*,br.com.filasus.controller.PacienteController" %>
<%!private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}private String dataBr(java.time.LocalDate d){return d==null?"—":d.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));}%>
<%Usuario paciente=(Usuario)request.getAttribute("paciente");List<Documento> documentos=(List<Documento>)request.getAttribute("documentos");if(documentos==null)documentos=Collections.emptyList();String ctx=request.getContextPath();String nome=paciente==null?"Paciente":paciente.getNome();%>
<%@ include file="/WEB-INF/jspf/icons.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FilaSUS — Meus Dados</title>
<link rel="stylesheet" href="<%=ctx%>/css/styles.css">
<style>
.data-field{display:flex;flex-direction:column;gap:4px;background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:12px 14px}.data-field__label{display:flex;align-items:center;gap:6px;color:var(--text-muted);font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.05em}.data-field__label svg{color:var(--teal-600)}.data-field__value{font-size:14px;font-weight:500;color:var(--text);word-break:break-word}.data-field__value--mono{font-family:var(--font-mono);letter-spacing:.02em}.data-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.docs-list{list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:8px}.docs-list li{display:flex;align-items:flex-start;gap:10px;background:var(--surface-2);border:1px solid var(--border);border-radius:10px;padding:10px 12px}.docs-list li svg{color:var(--text-muted);margin-top:2px;flex-shrink:0}.docs-list__name{font-size:13px;font-weight:500;word-break:break-all}.docs-list__desc{font-size:11px;color:var(--text-muted);margin-top:2px}.docs-list__time{font-size:10px;color:var(--text-muted);margin-top:2px}.info-banner{display:flex;align-items:flex-start;gap:14px;border-radius:12px;padding:16px 18px}.info-banner--teal{background:var(--teal-50);border:1px solid var(--teal-200)}.info-banner__icon{flex-shrink:0;width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center}.info-banner--teal .info-banner__icon{background:var(--teal-100);color:var(--teal-700)}.info-banner--teal .info-banner__title{color:var(--teal-800)}.info-banner--teal .info-banner__message{color:var(--teal-700)}.info-banner__title{font-size:14px;font-weight:600}.info-banner__message{font-size:12.5px;margin-top:2px;line-height:1.5}@media(max-width:640px){.data-grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="app-shell">
<header class="header">
<div class="header__title">
<button class="header__mobile-toggle" onclick="toggleMenu()" aria-label="Abrir menu"><%=ico("list")%></button>
<span>Meus Dados</span>
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
<a class="sidebar__item sidebar__item--active" href="<%=ctx%>/paciente/meus-dados">
<span class="sidebar__item-icon"><%=ico("user")%></span>
<span>Meus Dados</span>
</a>
<a class="sidebar__item" href="<%=ctx%>/documento/solicitar">
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
<h1 class="page-heading__title">Meus Dados</h1>
<p class="page-heading__subtitle">Confira seus dados cadastrados no sistema. Para alterações, procure um atendente.</p>
</div>
</div>
<div class="info-banner info-banner--teal" aria-labelledby="how-to-title">
<div class="info-banner__icon"><%=ico("info")%></div>
<div style="min-width:0">
<div id="how-to-title" class="info-banner__title">Como entrar em uma fila de atendimento</div>
<p class="info-banner__message">O sistema não permite que pacientes entrem em filas diretamente. No dia do mutirão, dirija-se à recepção, apresente seu CPF e o atendente irá inseri-lo na fila adequada, gerando sua senha de atendimento.</p>
</div>
</div>
<section class="card" style="margin-top:16px">
<div class="card__header">
<div class="card__title" style="display:flex;align-items:center;gap:8px"><span style="color:var(--primary)"><%=ico("idCard")%></span> Dados pessoais</div>
<div class="card__description">Informações cadastrais vinculadas ao seu CPF.</div>
</div>
<div class="card__body">
<div class="data-grid">
<div class="data-field">
<div class="data-field__label"><%=ico("user")%><span>Nome completo</span></div>
<div class="data-field__value">
<%=h(nome)%>
</div>
</div>
<div class="data-field">
<div class="data-field__label"><%=ico("clock")%><span>Idade</span></div>
<div class="data-field__value"><%=paciente==null?0:paciente.getIdade()%> anos
</div>
</div>
<div class="data-field">
<div class="data-field__label"><%=ico("idCard")%><span>CPF</span></div>
<div class="data-field__value data-field__value--mono">
<%=h(paciente==null?"—":paciente.getCpfFormatado())%>
</div>
</div>
<div class="data-field">
<div class="data-field__label"><%=ico("heart")%><span>CNS</span></div>
<div class="data-field__value data-field__value--mono">Não informado</div>
</div>
<div class="data-field">
<div class="data-field__label"><%=ico("calendar")%><span>Data de nascimento</span></div>
<div class="data-field__value">
<%=paciente==null?"—":dataBr(paciente.getDataNascimento())%>
</div>
</div>
<div class="data-field">
<div class="data-field__label"><%=ico("phone")%><span>Telefone</span></div>
<div class="data-field__value data-field__value--mono">
<%=h(paciente==null?"—":paciente.getTelefoneFormatado())%>
</div>
</div>
</div>
<%if(!documentos.isEmpty()){%>
<div style="margin-top:18px;padding-top:14px;border-top:1px solid var(--border)">
<div style="font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;color:var(--text-muted);margin-bottom:10px">Documentos anexados (<%=documentos.size()%>)</div>
<ul class="docs-list custom-scroll" style="max-height:280px;overflow-y:auto">
<%for(Documento d:documentos){%>
<li><span><%=ico("fileText")%></span><div style="min-width:0;flex:1"><div class="docs-list__name"><%=h(PacienteController.nomeDocumento(d))%></div><div class="docs-list__desc"><%=h(d.getDescricao())%></div><%if(d.getEnviadoEm()!=null){%><div class="docs-list__time">Enviado em <%=dataBr(d.getEnviadoEm().toLocalDate())%></div><%}%></div><span class="badge badge--slate"><%=h(d.getStatusValidacao())%></span></li>
<%}%>
</ul>
</div>
<%}%>
</div>
<div class="card__footer" style="display:flex;align-items:center;gap:8px"><span style="color:var(--amber-700);display:inline-flex"><%=ico("alert")%></span><span style="font-size:12px;color:var(--text-muted)">Para alterar seus dados, procure um atendente na recepção do mutirão.</span></div>
</section>
</div>
</main>
</div>
<footer class="footer">FilaSUS © 2026 — Giovanna Gonçalves & Matheus Souza Rosa</footer>
</div>
<script>function toggleMenu(){var s=document.getElementById('sidebar'),b=document.querySelector('.sidebar-backdrop'),o=!s.classList.contains('open');s.classList.toggle('open',o);s.classList.toggle('sidebar--mobile',o);document.body.classList.toggle('mobile-nav-open',o);if(o&&!b){b=document.createElement('div');b.className='sidebar-backdrop';b.onclick=toggleMenu;document.body.appendChild(b)}else if(!o&&b)b.remove()}</script>
</body>
</html>
