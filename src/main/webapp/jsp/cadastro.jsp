<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Cadastro de Paciente</title>
  <link rel="stylesheet" href="../css/styles.css">
</head>
<body>
<div class="login-page">
  <header class="login-header">
    <div style="max-width:768px;margin:0 auto;display:flex;align-items:center;justify-content:space-between">
      <a href="login.jsp" class="flex items-center gap-2" style="color:var(--text-muted);font-size:14px;font-weight:500">
        <span id="icon-back"></span>
        Voltar ao login
      </a>
      <div class="flex items-center gap-2">
        <div class="sidebar__brand-icon" style="width:32px;height:32px;border-radius:8px"></div>
        <strong style="font-size:14px">FilaSUS</strong>
      </div>
    </div>
  </header>

  <main style="flex:1;padding:32px 16px">
    <div style="max-width:640px;margin:0 auto" id="content">
      <!-- Preenchido via JS -->
    </div>
  </main>

  <footer class="login-footer">
    FilaSUS © <%= new java.util.Date().getYear() + 1900 %> — Sistema de Fila de Atendimento Online
  </footer>
</div>

<script src="../js/utils.js?v=5"></script>
<script src="../js/components.js?v=5"></script>
<script src="../mock/data.js?v=5"></script>
<script>
  document.querySelector('.sidebar__brand-icon').innerHTML = ICONS.heart;
  document.getElementById('icon-back').innerHTML = ICONS.arrowLeft;

  let createdPatient = null;

  function render() {
    const content = document.getElementById('content');
    if (createdPatient) {
      content.innerHTML = renderSuccess();
      return;
    }
    content.innerHTML = renderForm();
    bindForm();
  }

  function renderForm() {
    return `
      <div style="margin-bottom:24px">
        <div style="display:inline-flex;align-items:center;gap:8px;background:var(--teal-50);color:var(--teal-700);padding:4px 12px;border-radius:9999px;font-size:12px;font-weight:500;margin-bottom:12px">
          ${ICONS.userPlus}
          Cadastro de Paciente
        </div>
        <h1 style="font-size:28px;font-weight:700">Cadastre-se no FilaSUS</h1>
        <p style="color:var(--text-muted);font-size:14px;margin-top:4px">
          Preencha seus dados pessoais para se cadastrar no sistema. Após o
          cadastro, dirija-se à recepção do mutirão para entrar em uma fila
          de atendimento.
        </p>
      </div>

      <div class="alert alert--warning" style="margin-bottom:16px">
        ${ICONS.alert}
        <div>
          <div class="alert__title">Importante</div>
          <div class="alert__message">
            O cadastro não gera senha de atendimento. A definição da fila e a
            geração da senha são feitas pelo atendente na recepção, no dia do
            mutirão.
          </div>
        </div>
      </div>

      <form id="cadastro-form">
        <div class="card">
          <div class="card__header">
            <div class="card__title flex items-center gap-2">
              <span style="color:var(--primary)">${ICONS.idCard}</span>
              Dados Pessoais
            </div>
          </div>
          <div class="card__body">
            <div class="field">
              <label class="field__label field__label--required" for="name">Nome completo</label>
              <input class="input" id="name" type="text" placeholder="Ex.: Maria Aparecida Santos">
            </div>
            <div class="field-row">
              <div class="field">
                <label class="field__label field__label--required" for="email">E-mail</label>
                <input class="input" id="email" type="email" placeholder="voce@email.com" autocomplete="email">
              </div>
              <div class="field">
                <label class="field__label field__label--required" for="password">Senha</label>
                <input class="input" id="password" type="password" minlength="8" placeholder="Mínimo de 8 caracteres" autocomplete="new-password">
              </div>
            </div>
            <div class="field-row">
              <div class="field">
                <label class="field__label field__label--required" for="cpf">CPF</label>
                <input class="input" id="cpf" type="text" placeholder="000.000.000-00" inputmode="numeric" maxlength="14">
              </div>
              <div class="field">
                <label class="field__label" for="cns">CNS (opcional)</label>
                <input class="input" id="cns" type="text" placeholder="700 1234 5678 9012">
              </div>
            </div>
            <div class="field-row">
              <div class="field">
                <label class="field__label field__label--required" for="birthDate">Data de nascimento</label>
                <input class="input" id="birthDate" type="date">
                <div class="field__hint" id="age-hint"></div>
              </div>
              <div class="field">
                <label class="field__label field__label--required" for="phone">Telefone</label>
                <input class="input" id="phone" type="tel" placeholder="(11) 98765-4321" inputmode="tel" maxlength="15">
              </div>
            </div>
            <div class="field">
              <label class="field__label" for="whatsapp">WhatsApp (opcional)</label>
              <input class="input" id="whatsapp" type="tel" placeholder="(11) 98765-4321" inputmode="tel" maxlength="15">
              <div class="field__hint">Para receber notificações sobre sua senha.</div>
            </div>
          </div>
          <div class="card__footer flex gap-2" style="justify-content:flex-end">
            <a href="login.jsp" class="btn btn--outline">Cancelar</a>
            <button type="submit" class="btn btn--primary" id="submit-btn">
              <span id="icon-check"></span>
              Concluir cadastro
            </button>
          </div>
        </div>
      </form>

      <div style="text-align:center;font-size:14px;color:var(--text-muted);margin-top:24px">
        Já é cadastrado?
        <a href="login.jsp" style="color:var(--primary);font-weight:500;display:inline-flex;align-items:center;gap:4px">
          Faça login com seu CPF <span>${ICONS.arrowRight}</span>
        </a>
      </div>
    `;
  }

  function renderSuccess() {
    const p = createdPatient;
    return `
      <div class="card" style="border-color:var(--emerald-100);box-shadow:var(--shadow-lg)">
        <div class="card__body" style="padding:32px;text-align:center">
          <div style="width:64px;height:64px;margin:0 auto 16px;border-radius:50%;background:var(--emerald-100);display:flex;align-items:center;justify-content:center;color:var(--emerald-700)">
            ${ICONS.check}
          </div>
          <h1 style="font-size:24px;font-weight:700">Cadastro realizado!</h1>
          <p style="color:var(--text-muted);font-size:14px;max-width:420px;margin:8px auto 0">
            Seus dados foram salvos no sistema. Para entrar em uma fila de
            atendimento, dirija-se à recepção do mutirão. Um atendente irá
            gerar sua senha.
          </p>

          <div style="border:1px solid var(--border);border-radius:var(--radius);padding:16px;margin:24px 0;text-align:left">
            <div style="display:flex;justify-content:space-between;gap:8px">
              <span style="font-size:11px;text-transform:uppercase;color:var(--text-muted)">Nome</span>
              <span style="font-size:14px;font-weight:500">${escapeHtml(p.name)}</span>
            </div>
            <div style="display:flex;justify-content:space-between;gap:8px;margin-top:8px">
              <span style="font-size:11px;text-transform:uppercase;color:var(--text-muted)">CPF</span>
              <span style="font-size:14px;font-family:var(--font-mono)">${escapeHtml(p.cpf)}</span>
            </div>
            <div style="display:flex;justify-content:space-between;gap:8px;margin-top:8px">
              <span style="font-size:11px;text-transform:uppercase;color:var(--text-muted)">Idade</span>
              <span style="font-size:14px;font-weight:500">${p.age} anos</span>
            </div>
            ${p.cns ? `
              <div style="display:flex;justify-content:space-between;gap:8px;margin-top:8px">
                <span style="font-size:11px;text-transform:uppercase;color:var(--text-muted)">CNS</span>
                <span style="font-size:14px;font-family:var(--font-mono)">${escapeHtml(p.cns)}</span>
              </div>
            ` : ''}
          </div>

          <div class="alert alert--info" style="text-align:left;margin:16px 0">
            ${ICONS.info}
            <div>
              <div class="alert__title">Próximos passos</div>
              <div class="alert__message">
                No dia do mutirão, apresente seu CPF na recepção. O atendente
                confirmará seus dados e irá inseri-lo na fila adequada, gerando
                sua senha de atendimento.
              </div>
            </div>
          </div>

          <div class="flex gap-2" style="justify-content:center;margin-top:16px">
            <a href="login.jsp" class="btn btn--primary">${ICONS.logout} Ir para o login</a>
          </div>
        </div>
      </div>
    `;
  }

  function bindForm() {
    document.getElementById('cpf').addEventListener('input', e => e.target.value = maskCpf(e.target.value));
    document.getElementById('phone').addEventListener('input', e => e.target.value = maskPhone(e.target.value));
    document.getElementById('whatsapp').addEventListener('input', e => e.target.value = maskPhone(e.target.value));
    document.getElementById('birthDate').addEventListener('change', e => {
      const age = calcAge(e.target.value);
      document.getElementById('age-hint').textContent = age >= 0 ? `${age} anos` : '';
    });
    document.getElementById('icon-check').innerHTML = ICONS.check;
    document.getElementById('cadastro-form').addEventListener('submit', handleSubmit);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const cpf = document.getElementById('cpf').value;
    const cns = document.getElementById('cns').value.trim();
    const birthDate = document.getElementById('birthDate').value;
    const phone = document.getElementById('phone').value;
    const whatsapp = document.getElementById('whatsapp').value;

    if (!name || name.length < 3) { toast('Informe seu nome completo.', 'error'); return; }
    if (!email || !email.includes('@')) { toast('Informe um e-mail válido.', 'error'); return; }
    if (password.length < 8) { toast('A senha deve ter pelo menos 8 caracteres.', 'error'); return; }
    if (cpf.replace(/\D/g, '').length !== 11) { toast('CPF deve conter 11 dígitos.', 'error'); return; }
    if (!birthDate) { toast('Informe sua data de nascimento.', 'error'); return; }
    if (phone.replace(/\D/g, '').length < 10) { toast('Telefone inválido.', 'error'); return; }

    const btn = document.getElementById('submit-btn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Cadastrando...';
    try {
      const { patient } = await api('/api/patients', {
        method: 'POST',
        body: { name, email, password, cpf, cns: cns || undefined, birthDate, phone },
      });
      createdPatient = patient;
      toast('Cadastro realizado com sucesso!', 'success');
      render();
    } catch (err) {
      toast(err.message, 'error');
      btn.disabled = false;
      btn.innerHTML = `${ICONS.check} Concluir cadastro`;
    }
  }

  render();
</script>
</body>
</html>
