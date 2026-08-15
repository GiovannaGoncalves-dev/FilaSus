<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Meus Dados</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .data-field {
      display: flex;
      flex-direction: column;
      gap: 4px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 12px 14px;
    }
    .data-field__label {
      display: flex;
      align-items: center;
      gap: 6px;
      color: var(--text-muted);
      font-size: 10px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .data-field__label svg { color: var(--teal-600); }
    .data-field__value {
      font-size: 14px;
      font-weight: 500;
      color: var(--text);
      word-break: break-word;
    }
    .data-field__value--mono { font-family: var(--font-mono); letter-spacing: 0.02em; }
    .data-grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
    }
    @media (max-width: 640px) { .data-grid { grid-template-columns: 1fr; } }
    .docs-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; }
    .docs-list li {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      background: var(--surface-2);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 10px 12px;
    }
    .docs-list li svg { color: var(--text-muted); margin-top: 2px; flex-shrink: 0; }
    .docs-list__name { font-size: 13px; font-weight: 500; word-break: break-all; }
    .docs-list__desc { font-size: 11px; color: var(--text-muted); margin-top: 2px; }
    .docs-list__time { font-size: 10px; color: var(--text-muted); margin-top: 2px; }
    .info-banner {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      border-radius: 12px;
      padding: 16px 18px;
    }
    .info-banner--teal {
      background: var(--teal-50);
      border: 1px solid var(--teal-200);
    }
    .info-banner--amber {
      background: var(--amber-50);
      border: 1px solid var(--amber-200);
    }
    .info-banner__icon {
      flex-shrink: 0;
      width: 38px;
      height: 38px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .info-banner--teal .info-banner__icon { background: var(--teal-100); color: var(--teal-700); }
    .info-banner--amber .info-banner__icon { background: var(--amber-100); color: var(--amber-700); }
    .info-banner--teal .info-banner__title { color: var(--teal-800); }
    .info-banner--teal .info-banner__message { color: var(--teal-700); }
    .info-banner--amber .info-banner__title { color: var(--amber-800); }
    .info-banner--amber .info-banner__message { color: var(--amber-800); }
    .info-banner__title { font-size: 14px; font-weight: 600; }
    .info-banner__message { font-size: 12.5px; margin-top: 2px; line-height: 1.5; }
  </style>
</head>
<body>
<div id="root"></div>
<script src="../../js/utils.js?v=5"></script>
<script src="../../js/auth.js?v=5"></script>
<script src="../../mock/data.js?v=5"></script>
<script src="../../js/components.js?v=5"></script>
<script>
  /* ---------- Guard ---------- */
  (function guard() {
    if (!isAuthenticated()) { redirectTo('../login.jsp'); return; }
    const u = getCurrentUser();
    if (!u || u.role !== 'paciente') {
      toast('Você não tem permissão para acessar esta página.', 'error');
      redirectTo('../login.jsp');
    }
  })();

  const user = getCurrentUser() || {};
  const patientId = getCurrentPatientId();

  const navGroups = [{
    label: 'Paciente',
    items: [
      { key: 'dashboard',  label: 'Minha Fila',          icon: 'dashboard', href: 'dashboard.jsp' },
      { key: 'meus-dados', label: 'Meus Dados',          icon: 'user',      href: 'meus-dados.jsp',          active: true },
      { key: 'prioridade', label: 'Solicitar Prioridade',icon: 'alert',     href: 'solicitar-prioridade.jsp' },
    ],
  }];

  let patient = null;
  let isLoading = true;

  function renderShell() {
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Meus Dados',
      user,
      childrenHtml: `<div id="page-content"></div>`,
    });
  }

  function dataField({ icon, label, value, mono }) {
    return `
      <div class="data-field">
        <div class="data-field__label">${icon}<span>${escapeHtml(label)}</span></div>
        <div class="data-field__value ${mono ? 'data-field__value--mono' : ''}">${escapeHtml(value || '—')}</div>
      </div>
    `;
  }

  function renderLoading() {
    return `
      ${pageHeader({ title: 'Meus Dados', subtitle: 'Confira seus dados cadastrais no sistema. Para alterações, procure um atendente na recepção.' })}
      <div class="card">
        <div class="card__body" style="display:flex;flex-direction:column;gap:12px">
          <div class="skeleton" style="height:24px;width:200px"></div>
          <div class="data-grid">
            ${Array.from({length:6}).map(() => '<div class="skeleton" style="height:68px"></div>').join('')}
          </div>
        </div>
      </div>
    `;
  }

  function renderError() {
    return `
      ${pageHeader({ title: 'Meus Dados', subtitle: 'Confira seus dados cadastrais no sistema.' })}
      <div class="alert alert--danger">
        <span style="margin-top:2px">${ICONS.alert}</span>
        <div>
          <div class="alert__title">Não foi possível carregar seus dados</div>
          <div class="alert__message">Não encontramos um registro de paciente vinculado a esta conta. Tente sair e entrar novamente, ou procure a recepção.</div>
        </div>
      </div>
    `;
  }

  function renderPatient() {
    const docs = (patient.documents || []);
    return `
      ${pageHeader({ title: 'Meus Dados', subtitle: 'Confira seus dados cadastrais no sistema. Para alterações, procure um atendente na recepção.' })}

      <div class="info-banner info-banner--teal" aria-labelledby="how-to-title">
        <div class="info-banner__icon">${ICONS.info}</div>
        <div style="min-width:0">
          <div id="how-to-title" class="info-banner__title">Como entrar em uma fila de atendimento</div>
          <p class="info-banner__message">
            O sistema não permite que pacientes entrem em filas diretamente. No dia do mutirão,
            dirija-se à recepção, apresente seu CPF e o atendente irá inseri-lo na fila adequada,
            gerando sua senha de atendimento.
          </p>
        </div>
      </div>

      <div class="card" style="margin-top:16px">
        <div class="card__header">
          <div class="card__title" style="display:flex;align-items:center;gap:8px">
            <span style="color:var(--primary)">${ICONS.idCard}</span>
            Dados pessoais
          </div>
          <div class="card__description">Informações cadastrais vinculadas ao seu CPF.</div>
        </div>
        <div class="card__body">
          <div class="data-grid">
            ${dataField({ icon: ICONS.user,     label: 'Nome completo',        value: patient.name })}
            ${dataField({ icon: ICONS.clock,    label: 'Idade',                value: `${patient.age ?? calcAge(patient.birthDate)} anos` })}
            ${dataField({ icon: ICONS.idCard,   label: 'CPF',                  value: patient.cpf, mono: true })}
            ${dataField({ icon: ICONS.heart,    label: 'CNS',                  value: patient.cns || 'Não informado', mono: true })}
            ${dataField({ icon: ICONS.calendar, label: 'Data de nascimento',   value: formatDate(patient.birthDate) })}
            ${dataField({ icon: ICONS.phone,    label: 'Telefone',             value: patient.phone, mono: true })}
          </div>

          ${docs.length > 0 ? `
            <div style="margin-top:18px;padding-top:14px;border-top:1px solid var(--border)">
              <div style="font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:0.05em;color:var(--text-muted);margin-bottom:10px">
                Documentos anexados (${docs.length})
              </div>
              <ul class="docs-list custom-scroll" style="max-height:280px;overflow-y:auto">
                ${docs.map(doc => `
                  <li>
                    <span>${ICONS.fileText}</span>
                    <div style="min-width:0;flex:1">
                      <div class="docs-list__name">${escapeHtml(doc.fileName)}</div>
                      <div class="docs-list__desc">${escapeHtml(doc.description || '—')}</div>
                      ${doc.uploadedAt ? `<div class="docs-list__time">Enviado em ${formatDate(doc.uploadedAt)}</div>` : ''}
                    </div>
                  </li>
                `).join('')}
              </ul>
            </div>
          ` : ''}
        </div>
        <div class="card__footer" style="display:flex;align-items:center;gap:8px">
          <span style="color:var(--amber-700);display:inline-flex">${ICONS.alert}</span>
          <span style="font-size:12px;color:var(--text-muted)">
            Para alterar seus dados, procure um atendente na recepção do mutirão.
          </span>
        </div>
      </div>
    `;
  }

  function renderPage() {
    const c = document.getElementById('page-content');
    if (!c) return;
    if (isLoading) { c.innerHTML = renderLoading(); return; }
    c.innerHTML = patient ? renderPatient() : renderError();
  }

  async function load() {
    if (!patientId) { isLoading = false; renderPage(); return; }
    try {
      const data = await api(`/api/patients/${encodeURIComponent(patientId)}`);
      patient = data.patient || null;
    } catch (err) {
      toast(err.message || 'Erro ao carregar seus dados.', 'error');
      patient = null;
    } finally {
      isLoading = false;
      renderPage();
    }
  }

  renderShell();
  renderPage();
  load();
</script>
</body>
</html>
