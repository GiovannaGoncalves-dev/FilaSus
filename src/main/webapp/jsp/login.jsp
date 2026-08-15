<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Login</title>
  <link rel="stylesheet" href="../css/styles.css">
  <style>
    .login-page .login-main { padding: 12px 16px; align-items: center; }
    .login-layout {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 32px;
      max-width: 1200px;
      width: 100%;
      margin: 0 auto;
      align-items: center;
    }
    .login-hero { padding: 24px; }

    /* Card compacto pra caber sem scroll em telas menores */
    .login-page .login-card__header,
    .login-page .login-card__body { padding: 12px 20px; }
    .login-page .login-card__footer { padding: 6px 20px; font-size: 11px; }
    .login-page .field { margin-bottom: 8px; }
    .login-page .field__label { margin-bottom: 3px; }
    .login-page .input { padding: 6px 12px; }
    .login-page #submit-btn { padding: 8px 20px; }
    .login-page .divider { margin: 8px 0; }
    .login-page #register-section .btn { padding: 6px 16px; }
    .login-page #register-section p { margin-top: 4px !important; }

    .login-hero__badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: var(--teal-50);
      color: var(--teal-700);
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 12px;
      font-weight: 500;
      margin-bottom: 16px;
    }
    .login-hero__title {
      font-size: 32px;
      font-weight: 700;
      line-height: 1.15;
      letter-spacing: -0.01em;
      margin-bottom: 12px;
    }
    .login-hero__title span { color: var(--primary); }
    .login-hero__subtitle {
      font-size: 15px;
      color: var(--text-muted);
      line-height: 1.5;
    }
    @media (max-width: 900px) {
      .login-layout { grid-template-columns: 1fr; gap: 24px; }
      .login-hero__title { font-size: 28px; }
    }
  </style>
</head>
<body>
<div class="login-page">
  <header class="login-header">
    <div style="max-width:1200px;margin:0 auto;display:flex;align-items:center;justify-content:space-between">
      <div class="flex items-center gap-2">
        <div class="sidebar__brand-icon">${''}</div>
        <div>
          <div style="font-weight:700;line-height:1.1">FilaSUS</div>
          <div style="font-size:10px;color:var(--text-muted);line-height:1.1">Sistema de Fila de Atendimento</div>
        </div>
      </div>
    </div>
  </header>

  <main class="login-main">
    <div class="login-layout">
      <div class="login-hero">
        <div class="login-hero__badge">
          <span style="width:8px;height:8px;background:var(--teal-500);border-radius:50%;display:inline-block"></span>
          Mutirão do SUS — Atendimento Online
        </div>
        <h1 class="login-hero__title">
          Organize filas digitais com <span>prioridade</span> e estimativa em tempo real
        </h1>
        <p class="login-hero__subtitle">
          Cadastro de pacientes, geração automática de senhas, classificação
          por prioridade, chamada sequencial e painel de exibição para
          mutirões de saúde.
        </p>
      </div>

      <div class="login-card">
        <div class="login-card__header">
          <h2 style="font-size:20px;font-weight:600">Acessar o sistema</h2>
          <p style="font-size:13px;color:var(--text-muted);margin-top:4px">
            Entre com seu CPF ou e-mail e sua senha.
          </p>
        </div>
        <div class="login-card__body">
          <form id="login-form" autocomplete="off">
            <div class="field">
              <label class="field__label" for="email">CPF ou e-mail</label>
              <input class="input" id="email" type="text" placeholder="000.000.000-00 ou seu@email.com" autocomplete="username">
            </div>
            <div class="field">
              <label class="field__label" for="password">Senha</label>
              <input class="input" id="password" type="password" placeholder="••••••" autocomplete="current-password">
            </div>
            <button type="submit" class="btn btn--primary btn--block btn--lg" id="submit-btn">
              <span id="submit-text">Entrar</span>
            </button>
          </form>

          <div id="register-section">
            <div class="divider">ou</div>
            <a href="cadastro.jsp" class="btn btn--outline btn--block">
              <span id="icon-register"></span>
              Realizar cadastro
            </a>
            <p style="text-align:center;font-size:11px;color:var(--text-muted);margin-top:8px">
              O cadastro cria sua conta no sistema. A entrada em uma fila é feita
              pelo atendente na recepção do mutirão.
            </p>
          </div>
        </div>
        <div class="login-card__footer">
          FilaSUS © <%= new java.util.Date().getYear() + 1900 %> — Giovanna Gonçalves & Matheus Souza Rosa
        </div>
      </div>
    </div>
  </main>
</div>

<script src="../js/utils.js?v=5"></script>
<script src="../js/auth.js?v=5"></script>
<script src="../mock/data.js?v=5"></script>
<script src="../js/components.js?v=5"></script>
<script>
  if (new URLSearchParams(window.location.search).get('logout') === '1') {
    clearSession();
    history.replaceState(null, '', window.location.pathname);
  }
  // Injeta ícones SVG
  document.querySelector('.sidebar__brand-icon').innerHTML = ICONS.heart;
    document.getElementById('icon-register').innerHTML = ICONS.userPlus;

  document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    if (!email) { toast('Informe seu e-mail ou CPF.', 'error'); return; }
    const btn = document.getElementById('submit-btn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Entrando...';
    try {
      const session = await login(email, password);
      if (session.requiresProfileSelection) {
        window.location.href = `${CONFIG.CONTEXT}/selecionar-perfil`;
        return;
      }
      toast(`Bem-vindo(a), ${session.user.name.split(' ')[0]}!`, 'success');
      // Redireciona conforme o perfil
      const role = session.user.role;
      const folder = role === 'paciente' ? 'paciente' : role === 'atendente' ? 'atendente' : role === 'medico' ? 'medico' : 'admin';
      setTimeout(() => redirectTo(`${folder}/dashboard.jsp`), 600);
    } catch (err) {
      toast(err.message, 'error');
      btn.disabled = false;
      btn.innerHTML = '<span id="submit-text">Entrar</span>';
    }
  });

  async function synchronizeSelectedProfile() {
    if (new URLSearchParams(window.location.search).get('profileSelected') !== '1') return false;
    try {
      const session = await api('/api/me');
      setSession(session);
      const role = session.user.role;
      const folder = role === 'paciente' ? 'paciente' : role === 'atendente' ? 'atendente' : role === 'medico' ? 'medico' : 'admin';
      redirectTo(`${folder}/dashboard.jsp`);
      return true;
    } catch (_) { return false; }
  }

  synchronizeSelectedProfile();
  // Se já está logado, redireciona
  if (isAuthenticated()) {
    const user = getCurrentUser();
    const folder = user.role === 'paciente' ? 'paciente' : user.role === 'atendente' ? 'atendente' : user.role === 'medico' ? 'medico' : 'admin';
    redirectTo(`${folder}/dashboard.jsp`);
  }

</script>
</body>
</html>
