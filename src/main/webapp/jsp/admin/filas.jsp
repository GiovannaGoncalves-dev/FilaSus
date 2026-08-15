<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Filas</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .queue-list-item {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 16px;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      transition: border-color 0.15s, background 0.15s;
    }
    .queue-list-item:hover {
      border-color: var(--teal-200);
      background: var(--teal-50);
    }
    .queue-list-item__prefix {
      font-size: 14px;
      font-weight: 700;
      padding: 6px 10px;
      border-radius: 8px;
      background: var(--teal-100);
      color: var(--teal-700);
      min-width: 42px;
      text-align: center;
    }
    .queue-list-item__info {
      flex: 1;
      min-width: 0;
    }
    .queue-list-item__name {
      font-size: 15px;
      font-weight: 600;
      margin-bottom: 2px;
    }
    .queue-list-item__meta {
      font-size: 12px;
      color: var(--text-muted);
    }
    .queue-list-item__actions {
      display: flex;
      gap: 6px;
    }
    .field-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }
    @media (max-width: 500px) {
      .field-row { grid-template-columns: 1fr; }
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
      { key: 'multiroes', label: 'Multirões', icon: 'calendar', href: 'multiroes.jsp' },
      { key: 'filas', label: 'Filas', icon: 'list', href: 'filas.jsp', active: true },
      { key: 'usuarios', label: 'Usuários', icon: 'users', href: 'usuarios.jsp' },
      { key: 'relatorios', label: 'Relatórios', icon: 'chart', href: 'relatorios.jsp' },
    ],
  }];

  let allQueues = [];

  if (!isAuthenticated() || getCurrentUser()?.role !== 'admin') {
    window.location.href = '../login.jsp';
  } else {
    init();
  }

  function init() {
    const user = getCurrentUser();
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Filas',
      user,
      childrenHtml: `
        ${pageHeader({
          title: 'Filas de Atendimento',
          subtitle: 'Gerencie as filas disponíveis para mutirões.',
          actions: `<button class="btn btn--primary" onclick="openNewQueueDialog()">${ICONS.plus} Nova Fila</button>`
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
      const { queues } = await api('/api/queues');
      allQueues = queues;
      render();
    } catch (err) {
      console.error(err);
      toast(err.message || 'Erro ao carregar filas.', 'error');
    }
  }

  function render() {
    const content = document.getElementById('content');

    if (allQueues.length === 0) {
      content.innerHTML = emptyState({
        icon: 'list',
        title: 'Nenhuma fila cadastrada',
        message: 'Crie filas de atendimento para usar nos mutirões.',
        action: `<button class="btn btn--primary mt-4" onclick="openNewQueueDialog()">${ICONS.plus} Nova Fila</button>`,
      });
      return;
    }

    const list = allQueues.map(q => `
      <div class="queue-list-item">
        <div class="queue-list-item__prefix">${escapeHtml(q.sequencePrefix)}</div>
        <div class="queue-list-item__info">
          <div class="queue-list-item__name">${escapeHtml(q.name)}</div>
          <div class="queue-list-item__meta">Tempo médio padrão: ${q.avgServiceMinutes} min</div>
        </div>
        <div class="queue-list-item__actions">
          <button class="btn btn--outline btn--sm" onclick="openEditQueueDialog('${q.id}')" title="Editar">
            ${ICONS.edit || 'Editar'}
          </button>
          <button class="btn btn--outline btn--sm" onclick="deleteQueue('${q.id}', '${escapeHtml(q.name)}')" title="Excluir" style="color:var(--red-600)">
            ${ICONS.trash || 'Excluir'}
          </button>
        </div>
      </div>
    `).join('');

    content.innerHTML = `
      <div style="display:flex;flex-direction:column;gap:8px">
        ${list}
      </div>
    `;
  }

  function openNewQueueDialog() {
    showDialog({
      title: 'Nova Fila',
      size: 'lg',
      body: `
        <p style="font-size:14px;color:var(--text-muted);margin:-4px 0 16px 0">Crie uma fila de atendimento para usar nos mutirões.</p>
        <form id="new-queue-form" autocomplete="off">
          <div class="field">
            <label class="field__label field__label--required" for="q-name">Nome da fila</label>
            <input class="input" id="q-name" name="name" type="text" placeholder="Ex.: Consulta - Cardiologia" required>
          </div>
          <div class="field-row">
            <div class="field">
              <label class="field__label field__label--required" for="q-prefix">Prefixo da senha</label>
              <input class="input" id="q-prefix" name="sequencePrefix" type="text" placeholder="Ex.: CA" maxlength="3" required style="text-transform:uppercase">
              <div class="field__hint">2-3 caracteres. Será usado no início de cada senha (ex: CA-001).</div>
            </div>
            <div class="field">
              <label class="field__label field__label--required" for="q-avg">Tempo médio padrão (em minutos)</label>
              <input class="input" id="q-avg" name="avgServiceMinutes" type="number" min="1" max="120" value="15" required>
            </div>
          </div>
        </form>
      `,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog()">Cancelar</button>
        <button class="btn btn--primary" onclick="submitNewQueue()" id="q-submit">Criar fila</button>
      `,
    });
  }

  function openEditQueueDialog(queueId) {
    const queue = allQueues.find(q => q.id === queueId);
    if (!queue) return;

    showDialog({
      title: 'Editar Fila',
      size: 'lg',
      body: `
        <form id="edit-queue-form" autocomplete="off">
          <div class="field">
            <label class="field__label field__label--required" for="eq-name">Nome da fila</label>
            <input class="input" id="eq-name" name="name" type="text" value="${escapeHtml(queue.name)}" required>
          </div>
          <div class="field-row">
            <div class="field">
              <label class="field__label field__label--required" for="eq-prefix">Prefixo da senha</label>
              <input class="input" id="eq-prefix" name="sequencePrefix" type="text" value="${escapeHtml(queue.sequencePrefix)}" maxlength="3" required style="text-transform:uppercase">
            </div>
            <div class="field">
              <label class="field__label field__label--required" for="eq-avg">Tempo médio padrão (em minutos)</label>
              <input class="input" id="eq-avg" name="avgServiceMinutes" type="number" min="1" max="120" value="${queue.avgServiceMinutes}" required>
            </div>
          </div>
        </form>
      `,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog()">Cancelar</button>
        <button class="btn btn--primary" onclick="submitEditQueue('${queueId}')" id="eq-submit">Salvar alterações</button>
      `,
    });
  }

  async function submitNewQueue() {
    const form = document.getElementById('new-queue-form');
    const name = form.name.value.trim();
    const sequencePrefix = form.sequencePrefix.value.trim().toUpperCase();
    const avgServiceMinutes = parseInt(form.avgServiceMinutes.value, 10);

    if (!name || !sequencePrefix || !avgServiceMinutes) {
      toast('Preencha todos os campos obrigatórios.', 'error');
      return;
    }
    if (sequencePrefix.length < 2) {
      toast('O prefixo deve ter pelo menos 2 caracteres.', 'error');
      return;
    }

    const btn = document.getElementById('q-submit');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Criando...';

    try {
      await api('/api/queues', {
        method: 'POST',
        body: { name, sequencePrefix, avgServiceMinutes },
      });
      closeDialog();
      toast('Fila criada com sucesso.', 'success');
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao criar fila.', 'error');
      btn.disabled = false;
      btn.innerHTML = 'Criar fila';
    }
  }

  async function submitEditQueue(queueId) {
    const form = document.getElementById('edit-queue-form');
    const name = form.name.value.trim();
    const sequencePrefix = form.sequencePrefix.value.trim().toUpperCase();
    const avgServiceMinutes = parseInt(form.avgServiceMinutes.value, 10);

    if (!name || !sequencePrefix || !avgServiceMinutes) {
      toast('Preencha todos os campos obrigatórios.', 'error');
      return;
    }

    const btn = document.getElementById('eq-submit');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Salvando...';

    try {
      await api('/api/queues/' + queueId, {
        method: 'PATCH',
        body: { name, sequencePrefix, avgServiceMinutes },
      });
      closeDialog();
      toast('Fila atualizada com sucesso.', 'success');
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao atualizar fila.', 'error');
      btn.disabled = false;
      btn.innerHTML = 'Salvar alterações';
    }
  }

  async function deleteQueue(queueId, queueName) {
    const confirmed = await confirmDialog({
      title: 'Excluir fila',
      message: `Deseja realmente excluir a fila "${queueName}"? Esta ação não pode ser desfeita.`,
      confirmText: 'Excluir',
      cancelText: 'Cancelar',
      danger: true,
    });
    if (!confirmed) return;

    try {
      await api('/api/queues/' + queueId, { method: 'DELETE' });
      toast('Fila excluída com sucesso.', 'success');
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao excluir fila.', 'error');
    }
  }
</script>
</body>
</html>
