<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*" %>
<%!
private String h(Object valor){if(valor==null)return "";return String.valueOf(valor).replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");}
private String senha(ItemFila item){return "F"+item.getIdFila()+"-"+String.format("%03d",item.getSequenciaItemFila());}
%>
<% if(request.getAttribute("filas")==null){response.sendRedirect(request.getContextPath()+"/painel"+(request.getQueryString()==null?"":"?"+request.getQueryString()));return;}
String ctx=request.getContextPath(); Mutirao mutirao=(Mutirao)request.getAttribute("mutirao"); List<Fila> filas=(List<Fila>)request.getAttribute("filas"); List<ItemFila> chamados=(List<ItemFila>)request.getAttribute("chamados"); Map<Integer,ItemFila> atuais=(Map<Integer,ItemFila>)request.getAttribute("atualPorFila"); Map<Integer,Long> aguardando=(Map<Integer,Long>)request.getAttribute("aguardandoPorFila"); %>
<%@ include file="/WEB-INF/jspf/icons.jspf" %>
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="refresh" content="5">
<title>FilaSUS — Painel de Atendimento</title>
<link rel="stylesheet" href="<%=ctx%>/css/styles.css">
<style>body{margin:0;background:var(--surface-2);overflow-x:hidden}.display-panel{min-height:100vh}.display-main{padding:24px;display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:24px}.display-queues-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.display-card{min-width:0}.display-list-item{display:flex;align-items:center;gap:16px;padding:14px 16px;border-bottom:1px solid var(--border)}.display-list-item:last-child{border-bottom:0}.display-password{font-size:clamp(38px,5vw,58px)}.empty{grid-column:1/-1;display:flex;min-height:60vh;align-items:center;justify-content:center;text-align:center;padding:40px}.queue-name{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.live-dot{width:8px;height:8px;border-radius:50%;background:var(--emerald-500);display:inline-block;animation:panel-pulse 1.5s infinite}@keyframes panel-pulse{50%{opacity:.45}}@media(max-width:900px){.display-main{grid-template-columns:1fr;padding:12px}.display-queues-grid{grid-template-columns:1fr}.display-header{padding:12px}}</style>
</head>
<body>
<div class="display-panel">
<header class="display-header">
<div class="flex items-center gap-2">
<div class="sidebar__brand-icon"><%=ico("heart")%></div><div><strong>FilaSUS</strong>
<div style="font-size:11px;color:var(--text-muted)">Painel de Atendimento</div>
</div>
</div>
<div class="flex items-center gap-3"><div class="flex items-center gap-2" style="font-size:14px;font-weight:600"><%=ico("clock")%><span class="font-mono" id="clock" aria-label="Horário atual"></span></div><a href="<%=ctx%>/login" class="btn btn--ghost btn--icon" title="Sair do painel"><%=ico("x")%></a></div>
</header>
<main class="display-main">
<%if(request.getAttribute("erro")!=null){%>
<div class="empty">
<div>
<div class="empty-state__icon" style="margin:0 auto 12px"><%=ico("alert")%></div><h2>Não foi possível carregar o painel</h2>
<p>
<%=h(request.getAttribute("erro"))%>
</p>
</div>
</div>
<%}else if(mutirao==null){%>
<div class="empty">
<div>
<div class="empty-state__icon" style="margin:0 auto 12px"><%=ico("clock")%></div><h2>Nenhum mutirão aberto</h2>
<p>Volte mais tarde ou consulte a recepção.</p>
</div>
</div>
<%}else{%>
<section>
<div class="display-card mb-4">
<div class="flex items-center justify-between" style="gap:16px;flex-wrap:wrap">
<div>
<small style="color:var(--teal-700);font-weight:700;text-transform:uppercase">Mutirão em andamento</small>
<h1 style="font-size:22px">
<%=h(mutirao.getTipo())%>
</h1>
<p>
<%=h(mutirao.getLocal())%>
</p>
</div>
<strong>
<%=h(mutirao.getData())%>
</strong>
</div>
</div>
<div class="display-queues-grid">
<%for(Fila fila:filas){ItemFila atual=atuais.get(fila.getId());%>
<article class="display-card <%=atual==null?"":"display-card--active"%>">
<div class="flex items-center justify-between">
<strong class="queue-name">
<%=h(fila.getNome())%>
</strong>
<span class="badge badge--teal"><%=ico("users")%>
<%=aguardando.get(fila.getId())%> aguardando</span>
</div>
<small>
<%=atual==null?"Aguardando chamada":h(atual.getStatus().getDescricao())%>
</small>
<div class="display-password">
<%=atual==null?"—":senha(atual)%>
</div>
<div style="font-size:16px;font-weight:600">
<%=atual==null?"Nenhum paciente em atendimento":"Dirija-se ao local indicado"%>
</div>
</article>
<%}if(filas.isEmpty()){%>
<div class="display-card">
<p>Nenhuma fila configurada.</p>
</div>
<%}%>
</div>
</section>
<aside>
<div class="display-card" style="padding:0">
<div style="padding:16px 20px;border-bottom:1px solid var(--border);font-weight:700;text-transform:uppercase;display:flex;align-items:center;gap:8px"><%=ico("volume")%> Últimas chamadas</div>
<div>
<%if(chamados.isEmpty()){%>
<p style="padding:28px;text-align:center;color:var(--text-muted)">Nenhuma chamada realizada.</p>
<%}int limite=Math.min(6,chamados.size());for(int i=0;i<limite;i++){ItemFila item=chamados.get(i);%>
<div class="display-list-item">
<strong class="font-mono" style="font-size:20px;color:var(--teal-700)">
<%=senha(item)%>
</strong>
<div style="min-width:0">
<strong class="queue-name" style="display:block">Paciente chamado</strong>
<small>
<%=h(item.getFila().getNome())%> · <%=h(item.getStatus().getDescricao())%>
</small>
</div>
</div>
<%}%>
</div>
</div>
</aside>
<%}%>
</main>
<footer class="display-footer">
<span class="flex items-center gap-2"><span class="live-dot"></span> Modo painel — atualização automática a cada 5 segundos</span>
<span>
<%=mutirao==null?"":h(mutirao.getTipo())%>
</span>
</footer>
</div>
<script>function atualizarRelogio(){document.getElementById('clock').textContent=new Date().toLocaleTimeString('pt-BR')}atualizarRelogio();setInterval(atualizarRelogio,1000);</script>
</body>
</html>
