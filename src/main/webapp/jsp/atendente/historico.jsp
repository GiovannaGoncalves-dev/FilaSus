<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Histórico de Atendimentos</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .history-table-wrapper {
      overflow: auto;
      max-height: 520px;
    }
    .history-table th {
      position: sticky;
      top: 0;
      background: var(--surface);
      z-index: 1;
    }
    .history-table th,
    .history-table td {
      white-space: nowrap;
    }
    .history-table td.wrap {
      white-space: normal;
      word-break: break-word;
    }
    .history-table .td-actions {
      display: flex;
      gap: 6px;
      flex-wrap: wrap;
    }
    .history-table .td-password {
      font-family: var(--font-mono);
      font-weight: 700;
      color: var(--slate-800);
    }
    .history-table .td-priority-cell {
      display: flex;
      align-items: center;
      gap: 6px;
      min-width: 96px;
    }
    .history-table .td-time-cell {
      font-size: 12px;
      color: var(--text-muted);
    }
    .history-filters {
      display: flex;
      align-items: flex-end;
      gap: 12px;
      flex-wrap: wrap;
    }
    .history-filters .field__label { margin-bottom: 4px; }
    .history-filters .select { height: 38px; }
    .history-filters .btn { height: 38px; }
    @media (max-width: 768px) {
      .hide-mobile { display: none; }
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
  if (!requireRole('atendente')) throw new Error('Não autorizado');
    const user = getCurrentUser();

    const state = {
      session: null,
      history: [],
      filtered: [],
      statusFilter: 'all', /* all | atendido | ausente | remarcado */
      queueFilter: 'all', /* all | queueId */
      loading: true,
    };

    function buildNavGroups() {
      return [{
        label: 'Operação',
        items: [
          { key: 'dashboard', label: 'Painel', icon: 'dashboard', href: 'dashboard.jsp' },
          { key: 'cadastrar', label: 'Cadastrar Paciente', icon: 'userPlus', href: 'cadastrar-paciente.jsp' },
          { key: 'fila', label: 'Gerenciar Fila', icon: 'list', href: 'gerenciar-fila.jsp' },
          { key: 'historico', label: 'Histórico', icon: 'history', href: 'historico.jsp', active: true },
        ],
      }];
    }

    function renderSkeleton() {
      const childrenHtml = `
        ${pageHeader({ title: 'Histórico de Atendimentos', subtitle: 'Registros do mutirão atual' })}
        <div class="card mb-4"><div class="card__body">${'<div class="skeleton" style="height:60px"></div>'}</div></div>
        <div class="card"><div class="card__body">${'<div class="skeleton" style="height:400px"></div>'}</div></div>
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Histórico',
        user,
        childrenHtml,
      });
    }

    function applyFilter() {
      state.filtered = state.history
        .filter(h => state.statusFilter === 'all' || h.status === state.statusFilter)
        .filter(h => state.queueFilter === 'all' || h.queueId === state.queueFilter);
    }

    function renderFilters() {
      const counts = {
        all: state.history.length,
        atendido: state.history.filter(h => h.status === 'atendido').length,
        ausente: state.history.filter(h => h.status === 'ausente').length,
        remarcado: state.history.filter(h => h.status === 'remarcado').length,
      };
      const queues = state.session?.queues || [];
      return `
        <div class="card mb-4">
          <div class="card__body history-filters">
            <div style="flex:1;min-width:200px">
              <label class="field__label">Filtrar por status</label>
              <select class="select" id="status-filter" onchange="setStatusFilter(this.value)" style="min-width:200px">
                <option value="all" ${state.statusFilter === 'all' ? 'selected' : ''}>Todos (${counts.all})</option>
                <option value="atendido" ${state.statusFilter === 'atendido' ? 'selected' : ''}>Atendidos (${counts.atendido})</option>
                <option value="ausente" ${state.statusFilter === 'ausente' ? 'selected' : ''}>Ausentes (${counts.ausente})</option>
                <option value="remarcado" ${state.statusFilter === 'remarcado' ? 'selected' : ''}>Remarcados (${counts.remarcado})</option>
              </select>
            </div>
            <div style="flex:1;min-width:200px">
              <label class="field__label">Filtrar por fila</label>
              <select class="select" id="queue-filter" onchange="setQueueFilter(this.value)" style="min-width:200px">
                <option value="all" ${state.queueFilter === 'all' ? 'selected' : ''}>Todas as filas</option>
                ${queues.map(q => `
                  <option value="${q.id}" ${state.queueFilter === q.id ? 'selected' : ''}>${escapeHtml(q.name)}</option>
                `).join('')}
              </select>
            </div>
            <div class="flex gap-2" style="flex-wrap:wrap">
              <button class="btn btn--outline btn--sm" onclick="exportCsv()">
                ${ICONS.fileText}
                <span class="hidden-mobile">Exportar CSV</span>
              </button>
              <button class="btn btn--ghost btn--sm" onclick="loadHistory()">
                ${ICONS.refresh}
                <span class="hidden-mobile">Atualizar</span>
              </button>
            </div>
          </div>
        </div>
      `;
    }

    function renderTable() {
      if (!state.filtered.length) {
        return emptyState({
          icon: 'history',
          title: state.statusFilter === 'all'
            ? 'Nenhum registro encontrado'
            : 'Nenhum registro para este filtro',
          message: state.statusFilter === 'all'
            ? 'Ainda não há atendimentos concluídos, ausentes ou remarcados neste mutirão.'
            : `Não há registros com status "${STATUS_LABELS[state.statusFilter]}" no mutirão atual.`,
          action: `<a href="gerenciar-fila.jsp" class="btn btn--outline btn--sm mt-4">${ICONS.list} Ir para a fila</a>`,
        });
      }
      return `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Atendimentos</div>
              <div class="card__description">${state.filtered.length} ${state.filtered.length === 1 ? 'registro' : 'registros'}</div>
            </div>
          </div>
          <div class="card__body card__body--p0">
            <div class="history-table-wrapper">
              <table class="table history-table">
                <thead>
                  <tr>
                    <th>Senha</th>
                    <th>Paciente</th>
                    <th class="hide-mobile">Fila</th>
                    <th>Prioridade</th>
                    <th class="hide-mobile">Entrada</th>
                    <th class="hide-mobile">Chamada</th>
                    <th class="hide-mobile">Conclusão</th>
                    <th>Status</th>
                    <th class="hide-mobile">Atendente / Médico</th>
                  </tr>
                </thead>
                <tbody>
                  ${state.filtered.map(h => `
                    <tr>
                      <td class="td-password">${escapeHtml(h.password)}</td>
                      <td class="wrap">
                        <div style="font-weight:500">${escapeHtml(h.patientName || '—')}</div>
                        <div class="td-time-cell">${h.patientAge !== undefined ? h.patientAge + ' anos' : ''}</div>
                      </td>
                      <td class="hide-mobile">${escapeHtml(h.queueName || '—')}</td>
                      <td>
                        <div class="td-priority-cell">${priorityBadge(h.priority)}</div>
                      </td>
                      <td class="hide-mobile td-time-cell">${formatTime(h.enteredAt)}</td>
                      <td class="hide-mobile td-time-cell">${formatTime(h.calledAt)}</td>
                      <td class="hide-mobile td-time-cell">${formatTime(h.finishedAt || h.attendedAt)}</td>
                      <td>${statusBadge(h.status)}</td>
                      <td class="hide-mobile td-time-cell">
                        ${h.medicName ? `Médico: ${escapeHtml(h.medicName)}` : '—'}
                      </td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      `;
    }

    function renderPage() {
      const sessionName = state.session ? state.session.name : 'Carregando...';
      const childrenHtml = `
        ${pageHeader({ title: 'Histórico de Atendimentos', subtitle: sessionName })}
        ${state.session ? renderFilters() : ''}
        ${renderTable()}
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Histórico',
        user,
        childrenHtml,
      });
      const sel = document.getElementById('status-filter');
      if (sel) sel.value = state.statusFilter;
      const qSel = document.getElementById('queue-filter');
      if (qSel) qSel.value = state.queueFilter;
    }

    function setStatusFilter(value) {
      state.statusFilter = value;
      applyFilter();
      renderPage();
    }

    function setQueueFilter(value) {
      state.queueFilter = value;
      applyFilter();
      renderPage();
    }

    function exportCsv() {
      if (!state.filtered.length) {
        toast('Nenhum registro para exportar.', 'warning');
        return;
      }
      const headers = ['Senha', 'Paciente', 'Idade', 'Fila', 'Prioridade', 'Status', 'Entrada', 'Chamada', 'Conclusao', 'Medico'];
      const rows = state.filtered.map(h => [
        h.password,
        h.patientName || '',
        h.patientAge !== undefined ? h.patientAge : '',
        h.queueName || '',
        PRIORITY_LABELS[h.priority] || h.priority,
        STATUS_LABELS[h.status] || h.status,
        h.enteredAt ? formatDateTime(h.enteredAt) : '',
        h.calledAt ? formatDateTime(h.calledAt) : '',
        h.finishedAt ? formatDateTime(h.finishedAt) : (h.attendedAt ? formatDateTime(h.attendedAt) : ''),
        h.medicName || '',
      ]);
      const csv = [headers, ...rows]
        .map(r => r.map(cell => `"${String(cell).replace(/"/g, '""')}"`).join(','))
        .join('\n');
      const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `historico-filasus-${new Date().toISOString().slice(0,10)}.csv`;
      a.click();
      URL.revokeObjectURL(url);
      toast('Exportação concluída.', 'success', 'CSV gerado');
    }

    async function loadHistory() {
      state.loading = true;
      try {
        const sessionRes = await api('/api/sessions/active');
        state.session = sessionRes.session;
        if (!state.session) {
          state.history = [];
          state.filtered = [];
          state.loading = false;
          renderPage();
          return;
        }
        const data = await api('/api/history', { method: 'GET' });
        state.history = data.history || [];
        applyFilter();
        state.loading = false;
        renderPage();
      } catch (err) {
        state.loading = false;
        toast(err.message || 'Erro ao carregar histórico.', 'error');
        renderPage();
      }
    }

    renderSkeleton();
    loadHistory();
</script>
</body>
</html>
