<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%!
  private String h(Object value) {
    if (value == null) return "";
    return String.valueOf(value).replace("&", "&amp;").replace("<", "&lt;")
        .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
  }
%>
<% String ctx = request.getContextPath(); %>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Login</title>
  <link rel="stylesheet" href="<%= ctx %>/css/styles.css">
  <style>
    .login-page .login-main { padding:12px 16px;align-items:center }
    .login-layout { display:grid;grid-template-columns:1fr 1fr;gap:32px;max-width:1200px;width:100%;margin:0 auto;align-items:center }
    .login-hero { padding:24px }
    .login-hero__badge { display:inline-flex;align-items:center;gap:8px;background:var(--teal-50);color:var(--teal-700);padding:4px 12px;border-radius:9999px;font-size:12px;font-weight:500;margin-bottom:16px }
    .login-hero__title { font-size:32px;font-weight:700;line-height:1.15;letter-spacing:-.01em;margin-bottom:12px }
    .login-hero__title span { color:var(--primary) }
    .login-hero__subtitle { font-size:15px;color:var(--text-muted);line-height:1.5 }
    .login-page .login-card__header,
    .login-page .login-card__body { padding:12px 20px }
    .login-page .login-card__footer { padding:6px 20px;font-size:11px }
    .login-page .field { margin-bottom:8px }
    .login-page .field__label { margin-bottom:3px }
    .login-page .input { padding:6px 12px }
    .login-page .divider { margin:8px 0 }
    @media(max-width:900px){.login-layout{grid-template-columns:1fr}.login-hero__title{font-size:28px}}
  </style>
</head>
<body>
<div class="login-page">
  <header class="login-header">
    <div style="max-width:1200px;margin:0 auto;display:flex;align-items:center;gap:10px">
      <span class="sidebar__brand-icon" aria-hidden="true" style="font-size:20px">♥</span>
      <div><strong>FilaSUS</strong><div style="font-size:10px;color:var(--text-muted)">Sistema de Fila de Atendimento</div></div>
    </div>
  </header>
  <main class="login-main">
    <div class="login-layout">
      <section class="login-hero">
        <div class="login-hero__badge"><span style="width:8px;height:8px;background:var(--teal-500);border-radius:50%"></span>Mutirão do SUS — Atendimento Online</div>
        <h1 class="login-hero__title">Organize filas digitais com <span>prioridade</span> e estimativa em tempo real</h1>
        <p class="login-hero__subtitle">Cadastro de pacientes, geração de senhas, classificação por prioridade, chamada sequencial e painel de exibição.</p>
      </section>
      <section class="login-card">
        <div class="login-card__header">
          <h2 style="font-size:20px;font-weight:600">Acessar o sistema</h2>
          <p style="font-size:13px;color:var(--text-muted);margin-top:4px">Entre com seu CPF ou e-mail e sua senha.</p>
        </div>
        <div class="login-card__body">
          <% if (request.getAttribute("erro") != null) { %>
            <div class="alert alert--error" role="alert"><div class="alert__message"><%= h(request.getAttribute("erro")) %></div></div>
          <% } %>
          <form action="<%= ctx %>/login" method="post">
            <div class="field">
              <label class="field__label" for="login">CPF ou e-mail</label>
              <input class="input" id="login" name="login" type="text" value="<%= h(request.getAttribute("login")) %>" autocomplete="username" required>
            </div>
            <div class="field">
              <label class="field__label" for="senha">Senha</label>
              <input class="input" id="senha" name="senha" type="password" autocomplete="current-password" required>
            </div>
            <button type="submit" class="btn btn--primary btn--block btn--lg">Entrar</button>
          </form>
          <div class="divider">ou</div>
          <a href="<%= ctx %>/cadastro" class="btn btn--outline btn--block">Realizar cadastro</a>
          <p style="text-align:center;font-size:11px;color:var(--text-muted);margin-top:8px">O cadastro cria sua conta no sistema. A entrada em uma fila é feita pelo atendente na recepção do mutirão.</p>
        </div>
        <div class="login-card__footer">FilaSUS © <%= new java.util.Date().getYear() + 1900 %> — Giovanna Gonçalves &amp; Matheus Souza Rosa</div>
      </section>
    </div>
  </main>
</div>
</body>
</html>
