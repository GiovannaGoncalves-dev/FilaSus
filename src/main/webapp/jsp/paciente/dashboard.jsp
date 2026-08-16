<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.Usuario,br.com.filasus.controller.PacienteController.SenhaPaciente" %>
<%!
private String h(Object value){if(value==null)return "";return value.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;").replace("'","&#39;");}
private String statusClass(String status){if("atendido".equals(status))return "badge--emerald";if("chamado".equals(status))return "badge--amber";if("em_atendimento".equals(status))return "badge--teal";if("ausente".equals(status))return "badge--rose";return "badge--slate";}
%>
<%
Usuario paciente=(Usuario)request.getAttribute("paciente");
List<SenhaPaciente> ativas=(List<SenhaPaciente>)request.getAttribute("senhasAtivas");
List<SenhaPaciente> historico=(List<SenhaPaciente>)request.getAttribute("historico");
if(ativas==null)ativas=Collections.emptyList();if(historico==null)historico=Collections.emptyList();
long aguardando=ativas.stream().filter(s->"aguardando".equals(s.getStatus())).count();
String nome=paciente==null?"Paciente":paciente.getNome();String primeiroNome=nome.split(" ")[0];String ctx=request.getContextPath();
%>
<%@ include file="/WEB-INF/jspf/icons.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>FilaSUS — Minha Fila</title>
<link rel="stylesheet" href="<%=ctx%>/css/styles.css">
<style>
.hero-paciente{position:relative;overflow:hidden;border-radius:16px;border:2px solid var(--teal-200);background:radial-gradient(120% 120% at 100% 0%,var(--amber-50) 0%,transparent 45%),radial-gradient(120% 120% at 0% 100%,var(--emerald-50) 0%,transparent 45%),linear-gradient(135deg,var(--teal-50),var(--surface));padding:28px}.hero-paciente__badge{display:inline-flex;align-items:center;gap:8px;background:rgba(255,255,255,.7);color:var(--teal-700);padding:4px 12px;border-radius:9999px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;border:1px solid var(--teal-100)}.hero-paciente__title{font-size:28px;font-weight:700;margin-top:12px;line-height:1.15}.hero-paciente__subtitle{font-size:14px;color:var(--text-muted);margin-top:6px}.hero-paciente__stats{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:20px}.hero-stat{background:rgba(255,255,255,.8);border:1px solid var(--teal-100);border-radius:12px;padding:12px 14px}.hero-stat__label{color:var(--teal-700);font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.05em}.hero-stat__value{font-size:26px;font-weight:700;margin-top:4px}.info-banner{display:flex;gap:14px;background:var(--amber-50);border:1px solid var(--amber-200);border-radius:12px;padding:16px 18px;margin-top:20px}.info-banner__icon{width:38px;height:38px;border-radius:10px;background:var(--amber-100);color:var(--amber-700);display:flex;align-items:center;justify-content:center;flex-shrink:0}.info-banner__title{font-size:14px;font-weight:600;color:var(--amber-800)}.info-banner__message{font-size:12.5px;color:var(--amber-800);margin-top:2px;line-height:1.5}.section-title{display:flex;align-items:center;gap:8px;font-size:18px;font-weight:600;margin-bottom:14px}.section-title__count{font-size:11px;color:var(--text-muted);margin-left:auto;font-weight:500}.ticket-card-wrap{display:flex;flex-direction:column}.history-grid{display:grid;grid-template-columns:80px 1.6fr 1.4fr 1fr;gap:12px;padding:10px 16px;border-bottom:1px solid var(--border);align-items:center;font-size:13px}.history-grid--header{background:var(--surface-2);font-size:10px;text-transform:uppercase;color:var(--text-muted);font-weight:600}.history-password{font-family:var(--font-mono);font-weight:700}.ticket-server{padding:22px;border:1px solid var(--border);border-left:4px solid var(--teal-500);border-radius:var(--radius-lg);background:var(--surface);box-shadow:var(--shadow-sm)}.ticket-server__code{font-family:var(--font-mono);font-size:30px;font-weight:700;color:var(--teal-700);margin:8px 0}.ticket-server__meta{display:flex;gap:14px;flex-wrap:wrap;margin-top:14px;padding-top:12px;border-top:1px solid var(--border);font-size:12px;color:var(--text-muted)}
.hero-stat__label{display:flex;align-items:center;gap:6px}.hero-paciente__top{display:flex;align-items:flex-start;justify-content:space-between;gap:16px}.hero-paciente__profile-link{align-self:flex-start;flex-shrink:0;min-height:36px;height:auto;padding:7px 12px;gap:6px}.section-title__icon{color:var(--primary);display:inline-flex}.history-grid{grid-template-columns:80px 1.6fr 1.4fr 1fr 1fr}.history-grid:hover:not(.history-grid--header){background:var(--slate-50)}
@media(max-width:768px){.hero-paciente__stats,.grid-3{grid-template-columns:1fr}.history-grid{grid-template-columns:1fr;gap:4px}.history-grid--header{display:none}}
</style>
</head>
<body>
<div class="app-shell">
<header class="header">
<div class="header__title">
<button class="header__mobile-toggle" type="button" onclick="toggleMenu()" aria-label="Abrir menu"><%=ico("list")%></button>
<span>Minha Fila</span>
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
<a class="sidebar__item sidebar__item--active" href="<%=ctx%>/paciente/dashboard">
<span class="sidebar__item-icon"><%=ico("dashboard")%></span>
<span>Minha Fila</span>
</a>
<a class="sidebar__item" href="<%=ctx%>/paciente/meus-dados">
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
<div style="flex:1;min-width:0">
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
<section class="hero-paciente">
<div class="hero-paciente__top">
<div>
<span class="hero-paciente__badge"><span style="width:8px;height:8px;background:var(--teal-500);border-radius:50%;display:inline-block"></span> Bem-vindo(a)</span>
<h1 class="hero-paciente__title">Olá, <%=h(primeiroNome)%>!</h1>
<p class="hero-paciente__subtitle">
<%=ativas.isEmpty()?"Você não possui senhas ativas no momento.":"Você possui "+ativas.size()+" senha(s) ativa(s)."%>
</p>
</div>
<a href="<%=ctx%>/paciente/meus-dados" class="btn btn--outline btn--sm hero-paciente__profile-link"><%=ico("user")%><span class="hidden-mobile">Ver meus dados</span></a>
</div>
<div class="hero-paciente__stats">
<div class="hero-stat">
<div class="hero-stat__label"><%=ico("ticket")%><span>Senhas ativas</span></div>
<div class="hero-stat__value">
<%=ativas.size()%>
</div>
</div>
<div class="hero-stat">
<div class="hero-stat__label"><%=ico("users")%><span>Aguardando</span></div>
<div class="hero-stat__value">
<%=aguardando%>
</div>
</div>
<div class="hero-stat">
<div class="hero-stat__label"><%=ico("history")%><span>Atendimentos anteriores</span></div>
<div class="hero-stat__value">
<%=historico.size()%>
</div>
</div>
</div>
</section>
<section class="info-banner">
<div class="info-banner__icon"><%=ico("info")%></div>
<div>
<div class="info-banner__title">Como entrar em uma fila de atendimento?</div>
<p class="info-banner__message">A entrada em filas é feita <strong>exclusivamente pelo atendente</strong> na recepção do mutirão. Dirija-se ao balcão, apresente seu CPF e o atendente irá inseri-lo na fila adequada, gerando sua senha. Você poderá acompanhar sua posição e o tempo de espera por aqui.</p>
</div>
</section>
<section style="margin-top:24px">
<h2 class="section-title"><span class="section-title__icon"><%=ico("ticket")%></span> Minhas Senhas Ativas <span class="section-title__count">
<%=ativas.size()%> senha(s)</span>
</h2>
<%if(ativas.isEmpty()){%>
<div class="card">
<div class="empty-state">
<div class="empty-state__icon"><%=ico("ticket")%></div>
<div class="empty-state__title">Nenhuma senha ativa</div>
<div class="empty-state__message">Dirija-se à recepção do mutirão para entrar em uma fila.</div>
</div>
</div>
<%}else{%>
<div class="grid grid-3">
<%for(SenhaPaciente s:ativas){%>
<article class="ticket-card-wrap">
<div class="ticket-server">
<div style="font-size:11px;text-transform:uppercase;color:var(--text-muted)">Senha de atendimento</div>
<div class="ticket-server__code">
<%=h(s.getCodigo())%>
</div>
<strong>
<%=h(s.getFilaNome())%>
</strong>
<p style="font-size:12px;color:var(--text-muted);margin-top:4px">
<%=h(s.getMutiraoNome())%>
</p>
<div style="margin-top:10px">
<span class="badge <%=statusClass(s.getStatus())%>">
<%=h(s.getStatus())%>
</span>
<%if(s.isPrioridade()){%> <span class="badge badge--amber">Prioritário</span>
<%}%>
</div>
<div class="ticket-server__meta">
<%if(s.getPosicao()>0){%>
<span>Posição: <strong>
<%=s.getPosicao()%>ª</strong>
</span>
<%}%>
<span>Espera: <strong>
<%=s.getEspera()%> min</strong>
</span>
</div>
</div>
</article>
<%}%>
</div>
<%}%>
</section>
<section style="margin-top:24px">
<h2 class="section-title"><span class="section-title__icon"><%=ico("history")%></span> Meu Histórico <span class="section-title__count">
<%=historico.size()%> registro(s)</span>
</h2>
<div class="card" style="padding:0">
<%if(historico.isEmpty()){%>
<div class="empty-state">
<div class="empty-state__title">Sem atendimentos anteriores</div>
<div class="empty-state__message">Seu histórico aparecerá aqui após o atendimento.</div>
</div>
<%}else{%>
<div class="history-grid history-grid--header">
<div>Senha</div>
<div>Fila</div>
<div>Data</div>
<div>Prioridade</div>
<div>Status</div>
</div>
<%for(SenhaPaciente s:historico){%>
<div class="history-grid">
<div class="history-password">
<%=h(s.getCodigo())%>
</div>
<div>
<%=h(s.getFilaNome())%>
<br>
<small>
<%=h(s.getMutiraoNome())%>
</small>
</div>
<div>
<%=h(s.getEntrada())%>
</div>
<div><span class="badge <%=s.isPrioridade()?"badge--amber":"badge--slate"%>"><%=s.isPrioridade()?"Prioritária":"Comum"%></span></div>
<div>
<span class="badge <%=statusClass(s.getStatus())%>">
<%=h(s.getStatus())%>
</span>
</div>
</div>
<%}%>
<%}%>
</div>
</section>
</div>
</main>
</div>
<footer class="footer">FilaSUS © 2026 — Giovanna Gonçalves & Matheus Souza Rosa</footer>
</div>
<script>function toggleMenu(){var s=document.getElementById('sidebar'),b=document.querySelector('.sidebar-backdrop'),o=!s.classList.contains('open');s.classList.toggle('open',o);s.classList.toggle('sidebar--mobile',o);document.body.classList.toggle('mobile-nav-open',o);if(o&&!b){b=document.createElement('div');b.className='sidebar-backdrop';b.onclick=toggleMenu;document.body.appendChild(b)}else if(!o&&b)b.remove()}</script>
</body>
</html>
