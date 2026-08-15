<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Relatórios</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .report-filters {
      display: flex;
      align-items: flex-end;
      gap: 12px;
      flex-wrap: wrap;
    }
    .report-filters .field__label { margin-bottom: 4px; }
    .report-filters .select {
      height: 38px;
      padding-right: 28px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .report-filters .btn { height: 38px; }

    .section-toggles {
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      padding-top: 12px;
      margin-top: 12px;
      border-top: 1px solid var(--border);
    }
    .section-chip {
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border: 1px solid var(--border);
      border-radius: 9999px;
      font-size: 13px;
      cursor: pointer;
      transition: border-color 0.15s, background 0.15s;
      user-select: none;
    }
    .section-chip:hover { border-color: var(--teal-300); background: var(--teal-50); }
    .section-chip input { accent-color: var(--teal-600); width: 14px; height: 14px; }

    .mini-table-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
      align-items: stretch;
    }
    .mini-table-grid .card { display: flex; flex-direction: column; }
    .mini-table-grid .card__body--p0 { flex: 1; }
    @media (max-width: 900px) { .mini-table-grid { grid-template-columns: 1fr; } }

    .report-table-wrapper {
      overflow: auto;
      max-height: 480px;
    }
    .report-table th {
      position: sticky;
      top: 0;
      background: var(--surface);
      z-index: 1;
    }
    .report-table th, .report-table td { white-space: nowrap; }
    .report-table td.wrap { white-space: normal; word-break: break-word; }
    .report-table .td-time-cell { font-size: 12px; color: var(--text-muted); }
    @media (max-width: 768px) { .hide-mobile { display: none; } }

    /* No PDF/impressão: todas as colunas visíveis, sem cabeçalho fixo
       (position:sticky some/some duplica ao quebrar página) e sem
       corte de altura na tabela. */
    @media print {
      .hide-mobile { display: table-cell !important; }
      .report-table th { position: static; }
      .report-table-wrapper { max-height: none; overflow: visible; }
      .print-area table { width: 100%; border-collapse: collapse; }
      .print-area th, .print-area td { padding: 8px 10px; text-align: left; }
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
      { key: 'filas', label: 'Filas', icon: 'list', href: 'filas.jsp' },
      { key: 'usuarios', label: 'Usuários', icon: 'users', href: 'usuarios.jsp' },
      { key: 'relatorios', label: 'Relatórios', icon: 'chart', href: 'relatorios.jsp', active: true },
    ],
  }];

  let allSessions = [];
  let selectedSessionId = null;
  let selectedQueueId = 'all';
  let reportData = null;
  let history = [];
  let filteredHistory = [];

  const SECTIONS_META = [
    { key: 'stats', label: 'Indicadores' },
    { key: 'priority', label: 'Por Prioridade' },
    { key: 'status', label: 'Por Status' },
    { key: 'medic', label: 'Por Médico' },
    { key: 'hour', label: 'Por Horário' },
    { key: 'detail', label: 'Atendimentos Detalhados' },
  ];
  let sections = { stats: true, priority: true, status: true, medic: true, hour: true, detail: true };

  if (!isAuthenticated() || getCurrentUser()?.role !== 'admin') {
    window.location.href = '../login.jsp';
  } else {
    init();
  }

  async function init() {
    const user = getCurrentUser();
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Relatórios',
      user,
      childrenHtml: `
        ${pageHeader({ title: 'Relatórios', subtitle: 'Indicadores de atendimento por mutirão' })}
        <div id="content">
          <div class="flex items-center justify-center" style="min-height:320px">
            <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
          </div>
        </div>
      `,
    });
    const painelLink = document.querySelector('a[href="painel.jsp"]');
    if (painelLink) painelLink.href = '../painel.jsp';

    try {
      const { sessions } = await api('/api/sessions');
      allSessions = sessions;
      const { session } = await api('/api/sessions/active');
      selectedSessionId = session?.id || sessions[0]?.id || null;
    } catch (e) { /* ignore */ }

    await load();
  }

  async function load() {
    if (!selectedSessionId) {
      document.getElementById('content').innerHTML = emptyState({
        icon: 'chart',
        title: 'Sem relatórios',
        message: 'Não há mutirões cadastrados para gerar relatórios.',
      });
      return;
    }
    try {
      const queueQs = selectedQueueId !== 'all' ? '&queueId=' + encodeURIComponent(selectedQueueId) : '';
      const [reportRes, historyRes] = await Promise.all([
        api('/api/reports?sessionId=' + selectedSessionId + queueQs),
        api('/api/history?sessionId=' + selectedSessionId),
      ]);
      reportData = reportRes;
      history = historyRes.history || [];
      applyQueueFilter();
      render();
    } catch (err) {
      console.error(err);
      toast(err.message || 'Erro ao carregar relatório.', 'error');
    }
  }

  function applyQueueFilter() {
    filteredHistory = selectedQueueId === 'all'
      ? history
      : history.filter(h => h.queueId === selectedQueueId);
  }

  function render() {
    const session = allSessions.find(s => s.id === selectedSessionId);
    const report = reportData.report;
    const metrics = reportData.metrics;
    const queues = session?.queues || [];

    const filters = `
      <div class="card mb-4">
        <div class="card__body report-filters">
          <div style="flex:1;min-width:260px">
            <label class="field__label" for="session-select">Mutirão</label>
            <select class="select" id="session-select" onchange="selectSession(this.value)" style="width:100%;min-width:260px">
              ${allSessions.map(s => `
                <option value="${s.id}" ${s.id === selectedSessionId ? 'selected' : ''}>
                  ${escapeHtml(s.name)}
                </option>
              `).join('')}
            </select>
          </div>
          <div style="flex:1;min-width:200px">
            <label class="field__label" for="queue-select">Fila</label>
            <select class="select" id="queue-select" onchange="selectQueue(this.value)" style="width:100%;min-width:200px">
              <option value="all" ${selectedQueueId === 'all' ? 'selected' : ''}>Todas as filas</option>
              ${queues.map(q => `
                <option value="${q.id}" ${selectedQueueId === q.id ? 'selected' : ''}>${escapeHtml(q.name)}</option>
              `).join('')}
            </select>
          </div>
          <div class="flex gap-2" style="flex-wrap:wrap">
            <button class="btn btn--outline btn--sm" onclick="exportCsv()">
              ${ICONS.fileText}
              <span class="hidden-mobile">Exportar CSV</span>
            </button>
            <button class="btn btn--outline btn--sm" onclick="printReport()">
              ${ICONS.fileText}
              <span class="hidden-mobile">Exportar PDF</span>
            </button>
            <button class="btn btn--ghost btn--sm" onclick="load()">
              ${ICONS.refresh}
              <span class="hidden-mobile">Atualizar</span>
            </button>
          </div>
          <div class="section-toggles" style="width:100%">
            ${SECTIONS_META.map(s => `
              <label class="section-chip">
                <input type="checkbox" ${sections[s.key] ? 'checked' : ''} onchange="toggleSection('${s.key}', this.checked)">
                ${escapeHtml(s.label)}
              </label>
            `).join('')}
          </div>
        </div>
      </div>
    `;

    const stats = !sections.stats ? '' : `
      <div class="grid grid-3 mb-4">
        ${statCard({ label: 'Atendidos', value: report.totalAttendances, hint: 'Concluídos no filtro atual', icon: 'check', accent: 'emerald' })}
        ${statCard({ label: 'Ausentes', value: report.totalAbsent, hint: 'Não compareceram', icon: 'ban', accent: 'rose' })}
        ${statCard({ label: 'Prioritários', value: metrics?.totalPriority ?? 0, hint: 'Aguardando prioridade agora', icon: 'shield', accent: 'amber' })}
        ${statCard({ label: 'Espera Média', value: formatMinutes(report.avgWaitMinutes || 0), hint: 'Da entrada até a chamada', icon: 'clock', accent: 'teal' })}
        ${statCard({ label: 'Atendimento Médio', value: formatMinutes(report.avgServiceMinutes || 0), hint: 'Duração da consulta', icon: 'activity', accent: 'violet' })}
        ${statCard({ label: 'Na fila agora', value: metrics?.totalWaiting ?? 0, hint: 'Aguardando atendimento', icon: 'users', accent: 'slate' })}
      </div>
    `;

    const breakdownCards = [
      sections.priority ? `
        <div class="card">
          <div class="card__header"><div class="card__title">Por Prioridade</div></div>
          <div class="card__body--p0">${pieChartBody(report.byPriority)}</div>
        </div>
      ` : '',
      sections.status ? `
        <div class="card">
          <div class="card__header"><div class="card__title">Por Status</div></div>
          <div class="card__body--p0">${statusBarBody(report.byStatus)}</div>
        </div>
      ` : '',
      sections.medic ? `
        <div class="card">
          <div class="card__header"><div class="card__title">Por Médico</div></div>
          <div class="card__body--p0">${medicBarBody(report.byMedic)}</div>
        </div>
      ` : '',
      sections.hour ? `
        <div class="card">
          <div class="card__header"><div class="card__title">Por Horário</div></div>
          <div class="card__body--p0" style="max-height:260px;overflow-y:auto">${hourChartBody(filteredHistory)}</div>
        </div>
      ` : '',
    ].filter(Boolean).join('');
    const breakdowns = !breakdownCards ? '' : `<div class="mini-table-grid mb-4">${breakdownCards}</div>`;

    const detailTable = !sections.detail ? '' : (filteredHistory.length === 0
      ? emptyState({
          icon: 'history',
          title: 'Nenhum registro encontrado',
          message: 'Não há atendimentos concluídos, ausentes ou remarcados para este filtro.',
        })
      : `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Atendimentos detalhados</div>
              <div class="card__description">${filteredHistory.length} ${filteredHistory.length === 1 ? 'registro' : 'registros'}</div>
            </div>
          </div>
          <div class="card__body--p0">
            <div class="report-table-wrapper">${detailTableRows()}</div>
          </div>
        </div>
      `);

    const nothingSelected = !sections.stats && !breakdownCards && !sections.detail;
    document.getElementById('content').innerHTML = filters + (nothingSelected
      ? emptyState({ icon: 'chart', title: 'Nenhuma seção selecionada', message: 'Marque ao menos uma seção acima para ver o relatório.' })
      : stats + breakdowns + detailTable);
  }

  function toggleSection(key, checked) {
    sections[key] = checked;
    render();
  }

  function detailTableRows() {
    return `
      <table class="table report-table">
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
          ${filteredHistory.map(h => `
            <tr>
              <td class="td-password font-mono" style="font-weight:700">${escapeHtml(h.password)}</td>
              <td class="wrap">
                <div style="font-weight:500">${escapeHtml(h.patientName || '—')}</div>
                <div class="td-time-cell">${h.patientAge !== undefined ? h.patientAge + ' anos' : ''}</div>
              </td>
              <td class="hide-mobile">${escapeHtml(h.queueName || '—')}</td>
              <td>${priorityBadge(h.priority)}</td>
              <td class="hide-mobile td-time-cell">${formatTime(h.enteredAt)}</td>
              <td class="hide-mobile td-time-cell">${formatTime(h.calledAt)}</td>
              <td class="hide-mobile td-time-cell">${formatTime(h.finishedAt || h.attendedAt)}</td>
              <td>${statusBadge(h.status)}</td>
              <td class="hide-mobile td-time-cell">${h.medicName ? 'Médico: ' + escapeHtml(h.medicName) : '—'}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  function pieChartBody(byPriority) {
    const prioritario = byPriority.find(p => p.priority === 'prioritario')?.count || 0;
    const comum = byPriority.find(p => p.priority === 'comum')?.count || 0;
    const total = prioritario + comum;
    const pct = n => total ? (n / total * 100).toFixed(0) + '%' : '0%';
    return `
      <table class="table">
        <thead><tr><th>Prioridade</th><th>Quantidade</th><th>Percentual</th></tr></thead>
        <tbody>
          <tr><td>Prioritário</td><td>${prioritario}</td><td>${pct(prioritario)}</td></tr>
          <tr><td>Comum</td><td>${comum}</td><td>${pct(comum)}</td></tr>
          <tr><td><strong>Total</strong></td><td><strong>${total}</strong></td><td>100%</td></tr>
        </tbody>
      </table>
    `;
  }

  function statusBarBody(byStatus) {
    if (!byStatus.length) return '<p style="text-align:center;color:var(--text-muted);padding:24px">Sem dados.</p>';
    return `
      <table class="table">
        <thead><tr><th>Status</th><th>Quantidade</th></tr></thead>
        <tbody>
          ${byStatus.map(s => `<tr><td>${escapeHtml(s.label || s.status)}</td><td>${s.count}</td></tr>`).join('')}
        </tbody>
      </table>
    `;
  }

  function hourChartBody(items) {
    const buckets = {};
    for (let h = 8; h <= 18; h++) buckets[h] = 0;
    items.forEach(i => {
      if (i.attendedAt) {
        const h = new Date(i.attendedAt).getHours();
        if (buckets[h] !== undefined) buckets[h]++;
      }
    });
    return `
      <table class="table">
        <thead><tr><th>Horário</th><th>Atendimentos</th></tr></thead>
        <tbody>
          ${Object.entries(buckets).map(([h, count]) => `<tr><td>${h}h</td><td>${count}</td></tr>`).join('')}
        </tbody>
      </table>
    `;
  }

  function medicBarBody(byMedic) {
    if (!byMedic.length) return '<p style="text-align:center;color:var(--text-muted);padding:24px">Sem dados.</p>';
    return `
      <table class="table">
        <thead><tr><th>Médico</th><th>Atendimentos</th><th>Tempo médio</th></tr></thead>
        <tbody>
          ${byMedic.map(m => `
            <tr>
              <td>${escapeHtml(m.medicName)}</td>
              <td>${m.attendances}</td>
              <td>${formatMinutes(m.avgMinutes)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  function selectSession(id) {
    selectedSessionId = id;
    selectedQueueId = 'all';
    load();
  }

  function selectQueue(id) {
    selectedQueueId = id;
    load();
  }

  function printReport() {
    const session = allSessions.find(s => s.id === selectedSessionId);
    const report = reportData.report;
    const metrics = reportData.metrics;
    const queueName = selectedQueueId === 'all'
      ? 'Todas as filas'
      : (session?.queues || []).find(q => q.id === selectedQueueId)?.name || '—';

    let printArea = document.getElementById('print-area');
    if (!printArea) {
      printArea = document.createElement('div');
      printArea.id = 'print-area';
      printArea.className = 'print-area';
      document.body.appendChild(printArea);
    }
    const parts = [`
      <h2>Relatório — ${escapeHtml(session?.name || '—')}</h2>
      <div style="font-size:13px;color:#555;margin-bottom:16px">
        Fila: ${escapeHtml(queueName)} &middot; Gerado em ${formatDateTime(new Date().toISOString())}
      </div>
    `];
    if (sections.stats) {
      parts.push(`
        <table class="table" style="margin-bottom:20px">
          <tbody>
            <tr><td>Atendidos</td><td><strong>${report.totalAttendances}</strong></td></tr>
            <tr><td>Ausentes</td><td><strong>${report.totalAbsent}</strong></td></tr>
            <tr><td>Prioritários aguardando</td><td><strong>${metrics?.totalPriority ?? 0}</strong></td></tr>
            <tr><td>Espera média</td><td><strong>${formatMinutes(report.avgWaitMinutes || 0)}</strong></td></tr>
            <tr><td>Atendimento médio</td><td><strong>${formatMinutes(report.avgServiceMinutes || 0)}</strong></td></tr>
            <tr><td>Na fila agora</td><td><strong>${metrics?.totalWaiting ?? 0}</strong></td></tr>
          </tbody>
        </table>
      `);
    }
    if (sections.priority) parts.push(`<h3 style="font-size:15px;margin-bottom:8px">Por Prioridade</h3>${pieChartBody(report.byPriority)}`);
    if (sections.status) parts.push(`<h3 style="font-size:15px;margin:20px 0 8px">Por Status</h3>${statusBarBody(report.byStatus)}`);
    if (sections.medic) parts.push(`<h3 style="font-size:15px;margin:20px 0 8px">Por Médico</h3>${medicBarBody(report.byMedic)}`);
    if (sections.hour) parts.push(`<h3 style="font-size:15px;margin:20px 0 8px">Por Horário</h3>${hourChartBody(filteredHistory)}`);
    if (sections.detail) parts.push(`<h3 style="font-size:15px;margin:20px 0 8px">Atendimentos detalhados (${filteredHistory.length})</h3>${detailTableRows()}`);

    if (parts.length === 1) {
      toast('Marque ao menos uma seção para exportar.', 'warning');
      return;
    }
    printArea.innerHTML = parts.join('');
    window.print();
  }

  function exportCsv() {
    if (!filteredHistory.length) {
      toast('Nenhum registro para exportar.', 'warning');
      return;
    }
    const headers = ['Senha', 'Paciente', 'Idade', 'Fila', 'Prioridade', 'Status', 'Entrada', 'Chamada', 'Conclusao', 'Medico'];
    const rows = filteredHistory.map(h => [
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
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `relatorio-filasus-${new Date().toISOString().slice(0,10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast('Exportação concluída.', 'success', 'CSV gerado');
  }
</script>
</body>
</html>
