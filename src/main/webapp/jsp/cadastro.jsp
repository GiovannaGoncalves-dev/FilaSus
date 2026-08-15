<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
  private String esc(Object value) {
    if (value == null) return "";
    return value.toString().replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
      .replace("\"", "&quot;").replace("'", "&#39;");
  }
%>
<%@ include file="/WEB-INF/jspf/icons.jspf" %>
<!DOCTYPE html>
<html lang="pt-BR"><head>
  <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Cadastro de Paciente</title>
  <link rel="stylesheet" href="<%= request.getContextPath() %>/css/styles.css">
</head><body>
<div class="login-page">
  <header class="login-header"><div style="max-width:768px;margin:0 auto;display:flex;align-items:center;justify-content:space-between;width:100%">
    <a href="<%= request.getContextPath() %>/login" class="flex items-center gap-2" style="color:var(--text-muted);font-size:14px;font-weight:500"><%=ico("arrowLeft")%> Voltar ao login</a><div class="flex items-center gap-2"><span class="sidebar__brand-icon" style="width:32px;height:32px;border-radius:8px"><%=ico("heart")%></span><strong>FilaSUS</strong></div>
  </div></header>
  <main style="flex:1;padding:32px 16px"><div style="max-width:640px;margin:0 auto">
  <% if (request.getAttribute("sucesso") != null) { %>
    <div class="card" style="border-color:var(--emerald-100);box-shadow:var(--shadow-lg)"><div class="card__body" style="padding:32px;text-align:center"><div style="width:64px;height:64px;border-radius:50%;background:var(--emerald-100);color:var(--emerald-700);display:flex;align-items:center;justify-content:center;margin:0 auto 16px"><%=ico("check")%></div>
      <h1 style="font-size:24px">Cadastro realizado!</h1>
      <p style="color:var(--text-muted)">Seus dados foram salvos. Para entrar em uma fila, dirija-se à recepção do mutirão.</p>
      <div style="border:1px solid var(--border);border-radius:12px;padding:16px;margin:24px 0;text-align:left">
        <p><strong>Nome:</strong> <%= esc(request.getAttribute("nomeCadastrado")) %></p>
        <p><strong>CPF:</strong> <%= esc(request.getAttribute("cpfCadastrado")) %></p>
        <p><strong>Idade:</strong> <%= esc(request.getAttribute("idadeCadastrada")) %> anos</p>
      </div>
      <a class="btn btn--primary" href="<%= request.getContextPath() %>/login"><%=ico("logout")%> Ir para o login</a>
    </div></div>
  <% } else { %>
    <div style="margin-bottom:24px"><h1 style="font-size:28px">Cadastre-se no FilaSUS</h1>
      <p style="color:var(--text-muted)">Preencha seus dados pessoais. A senha de atendimento é gerada na recepção.</p></div>
    <% if (request.getAttribute("erro") != null) { %><div class="alert alert--danger" style="margin-bottom:16px"><%= esc(request.getAttribute("erro")) %></div><% } %>
    <div class="alert alert--warning" style="margin-bottom:16px"><%=ico("alert")%><div><div class="alert__title">Importante</div>
      <div class="alert__message">O cadastro não gera senha de atendimento. Procure a recepção no dia do mutirão.</div></div></div>
    <form method="post" action="<%= request.getContextPath() %>/cadastro">
      <div class="card"><div class="card__header"><div class="card__title flex items-center gap-2"><%=ico("user")%> Dados pessoais</div></div><div class="card__body">
        <div class="field"><label class="field__label field__label--required" for="nome">Nome completo</label>
          <input class="input" id="nome" name="nome" required minlength="3" value="<%= esc(request.getAttribute("formNome")) %>"></div>
        <div class="field-row"><div class="field"><label class="field__label field__label--required" for="email">E-mail</label>
          <input class="input" id="email" name="email" type="email" required value="<%= esc(request.getAttribute("formEmail")) %>"></div>
          <div class="field"><label class="field__label field__label--required" for="senha">Senha</label>
          <input class="input" id="senha" name="senha" type="password" minlength="8" required autocomplete="new-password"></div></div>
        <div class="field-row"><div class="field"><label class="field__label field__label--required" for="cpf">CPF</label>
          <input class="input" id="cpf" name="cpf" required maxlength="14" inputmode="numeric" value="<%= esc(request.getAttribute("formCpf")) %>"></div>
          <div class="field"><label class="field__label field__label--required" for="dataNascimento">Data de nascimento</label>
          <input class="input" id="dataNascimento" name="dataNascimento" type="date" required value="<%= esc(request.getAttribute("formNascimento")) %>"></div></div>
        <div class="field"><label class="field__label field__label--required" for="telefone">Telefone</label>
          <input class="input" id="telefone" name="telefone" type="tel" required maxlength="15" value="<%= esc(request.getAttribute("formTelefone")) %>"></div>
      </div><div class="card__footer flex gap-2" style="justify-content:flex-end">
        <a href="<%= request.getContextPath() %>/login" class="btn btn--outline">Cancelar</a><button class="btn btn--primary" type="submit"><%=ico("check")%> Concluir cadastro</button>
      </div></div>
    </form>
  <% } %>
  </div></main>
  <footer class="login-footer">FilaSUS © <%= java.time.Year.now() %></footer>
</div>
<script src="<%= request.getContextPath() %>/js/utils.js?v=5"></script>
<script>document.getElementById('cpf')?.addEventListener('input',e=>e.target.value=maskCpf(e.target.value));document.getElementById('telefone')?.addEventListener('input',e=>e.target.value=maskPhone(e.target.value));</script>
</body></html>
