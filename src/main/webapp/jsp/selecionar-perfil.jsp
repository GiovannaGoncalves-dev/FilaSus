<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="br.com.filasus.model.enums.PerfilUsuario" %>
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
  <title>FilaSUS — Selecionar perfil</title>
  <link rel="stylesheet" href="<%= ctx %>/css/styles.css">
</head>
<body>
<main class="login-page">
  <div class="login-main">
    <section class="login-card" style="width:min(560px,100%);margin:auto">
      <div class="login-card__header">
        <h1 style="font-size:22px;font-weight:700">Como você deseja acessar?</h1>
        <p style="color:var(--text-muted);margin-top:6px">Sua conta possui mais de um perfil. Escolha o perfil ativo desta sessão.</p>
      </div>
      <div class="login-card__body">
        <% if (request.getAttribute("erro") != null) { %>
          <div class="alert alert--error" role="alert"><div class="alert__message"><%= h(request.getAttribute("erro")) %></div></div>
        <% } %>
        <form action="<%= ctx %>/selecionar-perfil" method="post">
          <div class="profile-grid">
          <%
            List<PerfilUsuario> perfis = (List<PerfilUsuario>) request.getAttribute("perfis");
            if (perfis != null) {
              for (PerfilUsuario perfil : perfis) {
          %>
            <label class="profile-option" style="cursor:pointer">
              <input type="radio" name="perfil" value="<%= perfil.name() %>" required>
              <span class="profile-option__title"><%= perfil.getDescricao() %></span>
            </label>
          <% }} %>
          </div>
          <button type="submit" class="btn btn--primary btn--block btn--lg">Continuar</button>
        </form>
        <form action="<%= ctx %>/logout" method="post" style="margin-top:10px">
          <button type="submit" class="btn btn--ghost btn--block">Sair</button>
        </form>
      </div>
    </section>
  </div>
</main>
</body>
</html>
