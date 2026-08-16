<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" import="java.util.*,br.com.filasus.model.*" %>
<%!
private String h(Object v){if(v==null)return "";return v.toString().replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;");}
private String iniciais(Usuario p){if(p==null||p.getNome()==null||p.getNome().isBlank())return "?";String[] n=p.getNome().trim().split("\\s+");return (n[0].substring(0,1)+(n.length>1?n[n.length-1].substring(0,1):"")).toUpperCase();}
%>
<%
Usuario usuario=(Usuario)request.getAttribute("usuario");
Mutirao mutirao=(Mutirao)request.getAttribute("mutirao");
List<Fila> filas=(List<Fila>)request.getAttribute("filas");
List<Usuario> pacientes=(List<Usuario>)request.getAttribute("pacientes");
if(filas==null)filas=Collections.emptyList();
String busca=(String)request.getAttribute("busca");
String ctx=request.getContextPath(),pageTitle="Cadastrar Paciente",activeNav="cadastro";
%>
<%@ include file="/WEB-INF/jspf/atendente-shell-start.jspf" %>
<style>
.stepper-card{display:flex;align-items:flex-start;padding:20px 24px 16px;margin-bottom:16px}.step{display:flex;flex-direction:column;align-items:center;gap:8px;flex:1;min-width:100px;text-align:center}.step__circle{width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:14px;background:var(--slate-100);color:var(--slate-500);border:2px solid transparent;flex-shrink:0}.step--active .step__circle{background:var(--teal-600);color:#fff}.step--done .step__circle{background:var(--emerald-100);color:var(--emerald-700)}.step__label{font-size:13px;font-weight:500;color:var(--text-muted)}.step--active .step__label,.step--done .step__label{color:var(--text);font-weight:600}.step__bar{flex:1;height:2px;background:var(--border);margin-top:15px;min-width:24px}.step__bar--done{background:var(--emerald-500)}
.patient-search-result{display:flex;align-items:center;gap:12px;padding:12px;border-radius:var(--radius);border:1px solid var(--border);background:var(--surface)}.patient-search-result__avatar{width:40px;height:40px;border-radius:50%;background:var(--teal-100);color:var(--teal-800);display:flex;align-items:center;justify-content:center;font-weight:700;flex-shrink:0}.patient-search-result__name{font-size:14px;font-weight:600}.patient-search-result__meta{font-size:12px;color:var(--text-muted);margin-top:2px}.patient-search-result__content{flex:1;min-width:0}.patient-search-results{display:flex;flex-direction:column;gap:8px;margin-top:16px;max-height:360px;overflow-y:auto}
.queue-radio-card{display:block;padding:12px;border:1px solid var(--border);border-radius:var(--radius);background:var(--surface);min-width:180px}.queue-radio-card__title{font-size:14px;font-weight:600}.queue-radio-card__meta{font-size:12px;color:var(--text-muted);margin-top:4px}.registration-divider{display:flex;align-items:center;gap:12px;color:var(--text-muted);font-size:12px;margin:20px 0}.registration-divider:before,.registration-divider:after{content:"";height:1px;background:var(--border);flex:1}@media(max-width:640px){.stepper-card{padding:16px 8px}.step{min-width:72px}.step__label{font-size:11px}.step__bar{min-width:8px}.patient-search-result{align-items:flex-start;flex-wrap:wrap}.patient-search-result form{width:100%}}
</style>
<div class="server-page-heading"><h1>Cadastrar Paciente</h1><p><%=mutirao==null?"Cadastre pacientes no sistema":h(mutirao.getTipo())%></p></div>
<%if(request.getAttribute("sucesso")!=null){%><div class="alert alert--success server-message"><%=ico("check")%><div><%=h(request.getAttribute("sucesso"))%></div></div><%}if(request.getAttribute("erro")!=null){%><div class="alert alert--danger server-message"><%=ico("alert")%><div><%=h(request.getAttribute("erro"))%></div></div><%}%>
<div class="card stepper-card">
  <div class="step <%=busca.isBlank()?"step--active":"step--done"%>"><div class="step__circle"><%=busca.isBlank()?"1":ico("check")%></div><div class="step__label">Paciente</div></div>
  <div class="step__bar <%=!busca.isBlank()?"step__bar--done":""%>"></div>
  <div class="step <%=!busca.isBlank()?"step--active":""%>"><div class="step__circle">2</div><div class="step__label">Fila &amp; Prioridade</div></div>
  <div class="step__bar"></div>
  <div class="step"><div class="step__circle">3</div><div class="step__label">Senha Gerada</div></div>
</div>

<section class="card mb-4">
  <div class="card__header"><div><div class="card__title">Identificar Paciente</div><div class="card__description">Busque um paciente existente ou cadastre um novo para inseri-lo na fila.</div></div></div>
  <div class="card__body">
    <form method="get" action="<%=ctx%>/atendente/cadastrar-paciente">
      <div class="field"><label class="field__label" for="busca">Buscar por nome ou CPF</label><div class="flex gap-2"><input type="text" id="busca" class="input flex-1" name="busca" value="<%=h(busca)%>" placeholder="Ex.: João ou 123.456.789-01" minlength="3" required><button class="btn btn--primary"><%=ico("search")%> Buscar</button></div><div class="field__hint">Digite ao menos 3 caracteres.</div></div>
    </form>
    <%if(busca!=null&&pacientes!=null&&pacientes.isEmpty()){%>
      <div class="alert alert--warning"><%=ico("alert")%><div><div class="alert__title">Nenhum paciente encontrado</div><div class="alert__message">Cadastre um novo paciente no formulário abaixo.</div></div></div>
    <%}else if(pacientes!=null&&!pacientes.isEmpty()){%>
      <div class="patient-search-results">
      <%for(Usuario p:pacientes){%>
        <div class="patient-search-result"><div class="patient-search-result__avatar"><%=h(iniciais(p))%></div><div class="patient-search-result__content"><div class="patient-search-result__name"><%=h(p.getNome())%></div><div class="patient-search-result__meta">CPF: <%=h(p.getCpfFormatado())%></div></div>
        <%if(mutirao!=null){%><form method="post" action="<%=ctx%>/fila/emitir" class="server-actions"><input type="hidden" name="cpfPaciente" value="<%=h(p.getCpf())%>"><select class="select" name="idFila" required><option value="">Selecionar fila</option><%for(Fila f:filas){%><option value="<%=f.getId()%>"><%=h(f.getNome())%></option><%}%></select><button class="btn btn--primary btn--sm"><%=ico("ticket")%> Gerar Senha</button></form><%}%>
        </div>
      <%}%>
      </div>
    <%}%>
    <div class="registration-divider">OU CADASTRE UM NOVO PACIENTE</div>
    <form method="post" action="<%=ctx%>/atendente/cadastrar-paciente">
      <div class="server-form-grid">
        <div class="field"><label class="field__label field__label--required" for="nome">Nome completo</label><input class="input" id="nome" name="nome" minlength="3" placeholder="Ex.: Maria da Silva" required></div>
        <div class="field"><label class="field__label field__label--required" for="cpf">CPF</label><input class="input" id="cpf" name="cpf" maxlength="14" placeholder="000.000.000-00" inputmode="numeric" required></div>
        <div class="field"><label class="field__label field__label--required" for="email">E-mail</label><input class="input" id="email" type="email" name="email" placeholder="paciente@email.com" required></div>
        <div class="field"><label class="field__label field__label--required" for="telefone">Telefone</label><input class="input" id="telefone" name="telefone" placeholder="(00) 00000-0000" inputmode="numeric" required></div>
        <div class="field"><label class="field__label field__label--required" for="nascimento">Data de nascimento</label><input class="input" id="nascimento" type="date" name="dataNascimento" required></div>
        <div class="field"><label class="field__label field__label--required" for="senha">Senha inicial</label><input class="input" id="senha" type="password" name="senha" minlength="8" placeholder="Mínimo de 8 caracteres" required></div>
      </div>
      <div style="display:flex;justify-content:flex-end;margin-top:18px"><button class="btn btn--success"><%=ico("userPlus")%> Cadastrar Paciente</button></div>
    </form>
  </div>
</section>
<%if(mutirao==null){%><div class="alert alert--warning"><%=ico("alert")%><div><div class="alert__title">Nenhum mutirão aberto</div><div class="alert__message">O cadastro permanece disponível, mas a emissão de senha será liberada quando houver uma operação aberta.</div></div></div><%}%>
<%@ include file="/WEB-INF/jspf/atendente-shell-end.jspf" %>
