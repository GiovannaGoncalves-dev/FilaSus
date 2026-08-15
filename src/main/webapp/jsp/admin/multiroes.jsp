<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Multirões</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .sessions-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
      align-items: stretch;
    }
    @media (max-width: 768px) {
      .sessions-grid { grid-template-columns: 1fr; }
    }
    .sessions-grid .card {
      display: flex;
      flex-direction: column;
    }
    .sessions-grid .card__body {
      flex: 1;
      display: flex;
      flex-direction: column;
    }
    .session-card__header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 8px;
      margin-bottom: 8px;
    }
    .session-card__title {
      font-size: 16px;
      font-weight: 600;
      flex: 1;
      min-width: 0;
    }
    .session-card__meta {
      font-size: 13px;
      color: var(--text-muted);
      display: flex;
      align-items: center;
      gap: 6px;
      margin-bottom: 8px;
    }
    .session-card__meta span {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .queue-chips {
      display: flex;
      flex-wrap: wrap;
      align-content: flex-start;
      align-items: flex-start;
      gap: 4px;
      margin-bottom: 12px;
      flex: 1;
    }
    .queue-chips .badge,
    .queue-chips .badge.badge--slate {
      font-size: 10px;
      padding: 2px 6px;
      font-weight: 500;
    }
    .queue-item {
      padding: 12px;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      transition: border-color 0.15s, background 0.15s, opacity 0.15s;
    }
    .queue-item:hover { border-color: var(--teal-300); background: var(--teal-50); }
    .queue-item--disabled { opacity: 0.6; }
    .queue-item__header {
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
    }
    .queue-item__header input[type="checkbox"] { accent-color: var(--teal-600); width: 16px; height: 16px; cursor: pointer; }
    .queue-item__name { font-size: 14px; font-weight: 500; flex: 1; }
    .queue-item__prefix {
      font-size: 10px;
      font-weight: 600;
      padding: 2px 6px;
      border-radius: 4px;
      background: var(--slate-100);
      color: var(--slate-600);
    }
    .queue-item__fields {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 10px;
      margin-top: 10px;
      padding-top: 10px;
      border-top: 1px solid var(--border);
    }
    @media (max-width: 500px) {
      .queue-item__fields { grid-template-columns: 1fr 1fr; }
      .queue-item__capacity { grid-column: 1 / -1; }
    }
    .queue-item__field label {
      display: block;
      font-size: 11px;
      color: var(--text-muted);
      margin-bottom: 4px;
      font-weight: 500;
    }
    .queue-item__field input {
      width: 100%;
      padding: 6px 8px;
      border: 1px solid var(--border);
      border-radius: 6px;
      font-size: 13px;
      text-align: center;
      box-sizing: border-box;
    }
    .queue-item__field input:focus {
      outline: none;
      border-color: var(--teal-400);
      box-shadow: 0 0 0 2px var(--teal-100);
    }
    .queue-item__capacity {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-direction: column;
      background: var(--teal-50);
      border-radius: 6px;
      padding: 6px 8px;
    }
    .queue-item__capacity-value {
      font-size: 18px;
      font-weight: 700;
      color: var(--teal-700);
      line-height: 1;
    }
    .queue-item__capacity-label {
      font-size: 10px;
      color: var(--teal-600);
      margin-top: 2px;
    }
    .field-row-3 {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 12px;
    }
    @media (max-width: 600px) {
      .field-row-3 { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
<div id="root"></div>
<script src="../../js/utils.js?v=5"></script>
<script src="../../js/auth.js?v=5"></script>
<script src="../../mock/data.js?v=5"></script>
<script src="../../js/components.js?v=5"></script>
<script>
  // --- Auth guard (relative path fix for jsp/admin/) ---
  window.logout = async function() {
    try { await api('/api/auth', { method: 'DELETE' }); } catch (e) {}
    clearSession();
    window.location.href = '../login.jsp';
  };

  const navGroups = [{
    label: 'Administração',
    items: [
      { key: 'dashboard', label: 'Painel Geral', icon: 'dashboard', href: 'dashboard.jsp' },
      { key: 'multiroes', label: 'Multirões', icon: 'calendar', href: 'multiroes.jsp', active: true },
      { key: 'filas', label: 'Filas', icon: 'list', href: 'filas.jsp' },
      { key: 'usuarios', label: 'Usuários', icon: 'users', href: 'usuarios.jsp' },
      { key: 'relatorios', label: 'Relatórios', icon: 'chart', href: 'relatorios.jsp' },
    ],
  }];

  let allSessions = [];
  let allQueues = [];
  let currentFilter = 'todas';

  if (!isAuthenticated() || getCurrentUser()?.role !== 'admin') {
    window.location.href = '../login.jsp';
  } else {
    init();
  }


  function init() {
    const user = getCurrentUser();
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Multirões',
      user,
      childrenHtml: `
        ${pageHeader({
          title: 'Multirões',
          subtitle: 'Gerencie mutirões de atendimento do SUS.',
          actions: `<button class="btn btn--primary" onclick="openNewDialog()">${ICONS.plus} Novo Mutirão</button>`
        })}
        <div id="content">
          <div class="flex items-center justify-center" style="min-height:320px">
            <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
          </div>
        </div>
      `,
    });
    const painelLink = document.querySelector('a[href="painel.jsp"]');
    if (painelLink) painelLink.href = '../painel.jsp';

    load();
  }

  async function load() {
    try {
      const [sessionsResult, queuesResult] = await Promise.all([
        api('/api/sessions'),
        api('/api/queues'),
      ]);
      allSessions = sessionsResult.sessions;
      allQueues = queuesResult.queues;
      render();
    } catch (err) {
      console.error(err);
      toast(err.message || 'Erro ao carregar.', 'error');
    }
  }

  function render() {
    const filters = [
      { key: 'todas', label: 'Todas' },
      { key: 'agendada', label: 'Agendadas' },
      { key: 'aberta', label: 'Abertas' },
      { key: 'encerrada', label: 'Encerradas' },
      { key: 'cancelada', label: 'Canceladas' },
    ];
    const filtered = currentFilter === 'todas'
      ? allSessions
      : allSessions.filter(s => s.status === currentFilter);

    const tabs = `
      <div class="tabs">
        ${filters.map(f => {
          const count = f.key === 'todas'
            ? allSessions.length
            : allSessions.filter(s => s.status === f.key).length;
          return `
            <button class="tab ${currentFilter === f.key ? 'tab--active' : ''}" onclick="setFilter('${f.key}')">
              ${f.label}
              <span class="tab__count">${count}</span>
            </button>
          `;
        }).join('')}
      </div>
    `;

    const list = filtered.length === 0
      ? emptyState({
          icon: 'calendar',
          title: 'Nenhum mutirão',
          message: 'Não há mutirões neste filtro. Crie um novo mutirão para começar.',
          action: `<button class="btn btn--primary mt-4" onclick="openNewDialog()">${ICONS.plus} Novo Mutirão</button>`,
        })
      : `<div class="sessions-grid">${filtered.map(sessionCard).join('')}</div>`;

    document.getElementById('content').innerHTML = tabs + list;
  }

  function sessionCard(s) {
    return `
      <div class="card">
        <div class="card__body">
          <div class="session-card__header">
            <h3 class="session-card__title">${escapeHtml(s.name)}</h3>
            ${sessionStatusBadge(s.status)}
          </div>
          <div class="session-card__meta">
            ${ICONS.mapPin}
            <span>${escapeHtml(s.location)}</span>
          </div>
          <div class="session-card__meta">
            ${ICONS.calendar}
            <span>${formatDate(s.date)} &middot; ${s.startTime}&ndash;${s.endTime}</span>
          </div>
          <div class="session-card__meta">
            ${ICONS.list}
            <span>${(s.queues || []).length} fila(s) de atendimento</span>
          </div>
          <div class="queue-chips">
            ${(s.queues || []).map(q => `<span class="badge badge--slate">${escapeHtml(q.name)}</span>`).join('')}
          </div>
          <div style="margin-top:auto;padding-top:8px">
            ${sessionActions(s)}
          </div>
        </div>
      </div>
    `;
  }

  function sessionActions(s) {
    const buttons = [];
    if (s.status === 'agendada') {
      buttons.push(`<button class="btn btn--primary btn--sm" onclick="changeStatus('${s.id}','aberta','Deseja abrir este mutirão agora?')">${ICONS.play} Abrir</button>`);
      buttons.push(`<button class="btn btn--outline btn--sm" onclick="changeStatus('${s.id}','cancelada','Deseja cancelar este mutirão?',true)">${ICONS.ban} Cancelar</button>`);
    } else if (s.status === 'aberta') {
      buttons.push(`<button class="btn btn--success btn--sm" onclick="changeStatus('${s.id}','encerrada','Deseja encerrar este mutirão?')">${ICONS.stop} Encerrar</button>`);
      buttons.push(`<button class="btn btn--outline btn--sm" onclick="changeStatus('${s.id}','cancelada','Deseja cancelar este mutirão?',true)">${ICONS.ban} Cancelar</button>`);
    } else if (s.status === 'encerrada') {
      buttons.push(`<button class="btn btn--outline btn--sm" onclick="changeStatus('${s.id}','aberta','Deseja reabrir este mutirão?')">${ICONS.refresh} Reabrir</button>`);
    } else if (s.status === 'cancelada') {
      buttons.push(`<button class="btn btn--outline btn--sm" onclick="changeStatus('${s.id}','agendada','Deseja reativar este mutirão como agendado?')">${ICONS.refresh} Reabrir</button>`);
    }
    return `<div class="flex gap-2 flex-wrap" style="justify-content:flex-end">${buttons.join('')}</div>`;
  }

  async function changeStatus(id, newStatus, message, danger) {
    const confirmed = await confirmDialog({
      title: 'Confirmar ação',
      message,
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      danger: !!danger,
    });
    if (!confirmed) return;
    try {
      await api('/api/sessions/' + id, { method: 'PATCH', body: { status: newStatus } });
      toast('Multirão atualizado com sucesso.', 'success');
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao atualizar.', 'error');
    }
  }

  function setFilter(f) {
    currentFilter = f;
    render();
  }

  function openNewDialog() {
    const today = new Date().toISOString().slice(0, 10);
    const queuesHtml = allQueues.length === 0
      ? '<p style="font-size:13px;color:var(--text-muted)">Nenhuma fila cadastrada. O mutirão será criado sem filas.</p>'
      : allQueues.map(q => `
        <div class="queue-item" id="queue-item-${q.id}">
          <div class="queue-item__header">
            <input type="checkbox" name="queueIds" value="${q.id}" checked onchange="toggleQueueItem('${q.id}', this.checked)">
            <span class="queue-item__name">${escapeHtml(q.name)}</span>
            <span class="queue-item__prefix">${escapeHtml(q.sequencePrefix)}</span>
          </div>
          <div class="queue-item__fields">
            <div class="queue-item__field">
              <label>Tempo médio (min)</label>
              <input type="number" name="avgTime_${q.id}" value="${q.avgServiceMinutes}" min="1" max="120" onchange="updateCapacity('${q.id}')">
            </div>
            <div class="queue-item__field">
              <label>Médicos atendendo</label>
              <input type="number" name="doctors_${q.id}" value="1" min="1" max="50" onchange="updateCapacity('${q.id}')">
            </div>
            <div class="queue-item__capacity" id="capacity-${q.id}">
              <div class="queue-item__capacity-value">${Math.round(60 / q.avgServiceMinutes)}</div>
              <div class="queue-item__capacity-label">pacientes/hora</div>
            </div>
          </div>
        </div>
      `).join('');

    showDialog({
      title: 'Novo Mutirão',
      size: 'lg',
      body: `
        <p style="font-size:14px;color:var(--text-muted);margin:-4px 0 16px 0">Cadastre um mutirão de atendimento. Você poderá abri-lo em seguida.</p>
        <form id="new-session-form" autocomplete="off">
          <div class="field">
            <label class="field__label field__label--required" for="ns-name">Nome</label>
            <input class="input" id="ns-name" name="name" type="text" placeholder="Ex.: Mutirão de Cardiologia - UBS Central" required>
          </div>
          <div class="field">
            <label class="field__label field__label--required" for="ns-location">Local</label>
            <input class="input" id="ns-location" name="location" type="text" placeholder="Ex.: UBS Central - Rua das Flores, 123 - Centro" required>
          </div>
          <div class="field-row-3">
            <div class="field">
              <label class="field__label field__label--required" for="ns-date">Data</label>
              <input class="input" id="ns-date" name="date" type="date" value="${today}" required>
            </div>
            <div class="field">
              <label class="field__label field__label--required" for="ns-start">Início</label>
              <input class="input" id="ns-start" name="startTime" type="time" value="08:00" required>
            </div>
            <div class="field">
              <label class="field__label field__label--required" for="ns-end">Fim</label>
              <input class="input" id="ns-end" name="endTime" type="time" value="17:00" required>
            </div>
          </div>
          <div class="field" style="margin-top:16px">
            <label class="field__label" style="margin-bottom:2px">Filas disponíveis</label>
            <div style="font-size:12px;color:var(--text-muted);margin-bottom:10px">Configure tempo médio e médicos para estimar a capacidade de cada fila.</div>
            <div style="display:flex;flex-direction:column;gap:8px">${queuesHtml}</div>
          </div>
        </form>
      `,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog()">Cancelar</button>
        <button class="btn btn--primary" onclick="submitNewSession()" id="ns-submit">Criar mutirão</button>
      `,
    });
  }

  function toggleQueueItem(queueId, checked) {
    const item = document.getElementById('queue-item-' + queueId);
    if (!item) return;
    const fields = item.querySelector('.queue-item__fields');
    if (checked) {
      item.classList.remove('queue-item--disabled');
      fields.style.display = 'grid';
    } else {
      item.classList.add('queue-item--disabled');
      fields.style.display = 'none';
    }
  }

  function updateCapacity(queueId) {
    const form = document.getElementById('new-session-form');
    const avgTime = parseInt(form.querySelector(`input[name="avgTime_${queueId}"]`)?.value) || 15;
    const doctors = parseInt(form.querySelector(`input[name="doctors_${queueId}"]`)?.value) || 1;
    // Capacidade = (médicos * 60) / tempo médio
    const capacity = Math.round((doctors * 60) / avgTime);
    const capacityEl = document.getElementById('capacity-' + queueId);
    if (capacityEl) {
      capacityEl.innerHTML = `
        <div class="queue-item__capacity-value">${capacity}</div>
        <div class="queue-item__capacity-label">pacientes/hora</div>
      `;
    }
  }

  async function submitNewSession() {
    const form = document.getElementById('new-session-form');
    const name = form.name.value.trim();
    const location = form.location.value.trim();
    const date = form.date.value;
    const startTime = form.startTime.value;
    const endTime = form.endTime.value;
    const queueCheckboxes = form.querySelectorAll('input[name="queueIds"]');
    const queueIds = [];
    const queueConfigs = {};

    queueCheckboxes.forEach(cb => {
      if (cb.checked) {
        const qId = cb.value;
        queueIds.push(qId);
        queueConfigs[qId] = {
          avgServiceMinutes: parseInt(form.querySelector(`input[name="avgTime_${qId}"]`)?.value) || 15,
          doctors: parseInt(form.querySelector(`input[name="doctors_${qId}"]`)?.value) || 1,
        };
      }
    });

    if (!name || !location || !date || !startTime || !endTime) {
      toast('Preencha todos os campos obrigatórios.', 'error');
      return;
    }
    if (queueIds.length === 0) {
      toast('Selecione pelo menos uma fila.', 'error');
      return;
    }
    const btn = document.getElementById('ns-submit');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Criando...';
    try {
      await api('/api/sessions', {
        method: 'POST',
        body: { name, location, date, startTime, endTime, queueIds, queueConfigs },
      });
      closeDialog();
      toast('Mutirão criado com sucesso.', 'success');
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao criar mutirão.', 'error');
      btn.disabled = false;
      btn.innerHTML = 'Criar mutirão';
    }
  }
</script>
</body>
</html>
