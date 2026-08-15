<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Painel Geral</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .quick-action {
      display: block;
      text-decoration: none;
      color: inherit;
      transition: transform 0.1s, box-shadow 0.15s;
    }
    .quick-action:hover {
      transform: translateY(-2px);
      box-shadow: var(--shadow-md);
    }
    .quick-action__inner {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px 20px;
    }
    .quick-action__icon {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .session-banner {
      display: flex;
      align-items: center;
      gap: 16px;
      flex-wrap: wrap;
      padding: 20px;
    }
    .session-banner__icon {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      background: var(--emerald-50);
      color: var(--emerald-700);
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .activity-item,
    .session-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 20px;
      border-bottom: 1px solid var(--border);
    }
    .activity-item:last-child,
    .session-item:last-child { border-bottom: none; }
    .activity-item__icon,
    .session-item__icon {
      width: 36px;
      height: 36px;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .section-title {
      font-size: 15px;
      font-weight: 600;
      margin-bottom: 12px;
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

  // --- Sidebar nav (admin) ---
  const navGroups = [{
    label: 'Administração',
    items: [
      { key: 'dashboard', label: 'Painel Geral', icon: 'dashboard', href: 'dashboard.jsp', active: true },
      { key: 'multiroes', label: 'Multirões', icon: 'calendar', href: 'multiroes.jsp' },
      { key: 'filas', label: 'Filas', icon: 'list', href: 'filas.jsp' },
      { key: 'usuarios', label: 'Usuários', icon: 'users', href: 'usuarios.jsp' },
      { key: 'relatorios', label: 'Relatórios', icon: 'chart', href: 'relatorios.jsp' },
    ],
  }];

  if (!isAuthenticated() || getCurrentUser()?.role !== 'admin') {
    window.location.href = '../login.jsp';
  } else {
    init();
  }

  function init() {
    const user = getCurrentUser();
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Painel Geral',
      user,
      childrenHtml: `
        ${pageHeader({ title: 'Painel Geral', subtitle: 'Visão geral do sistema e do mutirão em andamento' })}
        <div id="content">
          <div class="flex items-center justify-center" style="min-height:320px">
            <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
          </div>
        </div>
      `,
    });
    // Fix "Painel" header link to point to /jsp/painel.jsp
    const painelLink = document.querySelector('a[href="painel.jsp"]');
    if (painelLink) painelLink.href = '../painel.jsp';

    load();
    setInterval(load, 15000);
  }

  async function load() {
    try {
      const [activeRes, sessionsRes] = await Promise.all([
        api('/api/sessions/active'),
        api('/api/sessions'),
      ]);
      const session = activeRes.session;
      let queueRes = { items: [], metrics: null };
      let historyRes = { history: [] };
      if (session) {
        [queueRes, historyRes] = await Promise.all([
          api('/api/queue?sessionId=' + session.id),
          api('/api/history?sessionId=' + session.id),
        ]);
      }
      render(session, queueRes, sessionsRes.sessions, historyRes.history);
    } catch (err) {
      console.error(err);
      document.getElementById('content').innerHTML = `
        <div class="alert alert--danger">
          ${ICONS.alert}
          <div>
            <div class="alert__title">Erro ao carregar</div>
            <div class="alert__message">${escapeHtml(err.message || 'Tente novamente.')}</div>
          </div>
        </div>
      `;
    }
  }

  function render(session, queueData, sessions, history) {
    const metrics = queueData.metrics;
    const items = queueData.items || [];
    const emAtendimento = items.filter(i => i.status === 'em_atendimento').length;
    const attendedToday = metrics?.totalAttended ?? 0;
    const waiting = metrics?.totalWaiting ?? 0;
    const priority = metrics?.totalPriority ?? 0;
    const absent = metrics?.totalAbsent ?? 0;

    // Active session banner
    const sessionBanner = session ? `
      <div class="card mb-6">
        <div class="session-banner">
          <div class="session-banner__icon">${ICONS.activity}</div>
          <div style="flex:1;min-width:0">
            <div style="font-size:11px;text-transform:uppercase;letter-spacing:0.05em;color:var(--emerald-700);font-weight:600">Mutirão em andamento</div>
            <div style="font-size:18px;font-weight:700;margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(session.name)}</div>
            <div style="font-size:13px;color:var(--text-muted);margin-top:2px;display:flex;align-items:center;gap:4px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
              ${ICONS.mapPin} ${escapeHtml(session.location)} &middot; ${formatDate(session.date)} &middot; ${session.startTime}&ndash;${session.endTime}
            </div>
          </div>
          ${sessionStatusBadge(session.status)}
        </div>
      </div>
    ` : `
      <div class="alert alert--warning mb-6">
        ${ICONS.alert}
        <div style="flex:1">
          <div class="alert__title">Nenhum mutirão aberto</div>
          <div class="alert__message">Abra ou agende um mutirão para começar os atendimentos.</div>
        </div>
        <a href="multiroes.jsp" class="btn btn--primary btn--sm">${ICONS.calendar} Ver mutirões</a>
      </div>
    `;

    // 6 stat cards
    const stats = `
      <div class="section-title">Visão Geral</div>
      <div class="grid grid-3 mb-6">
        ${statCard({ label: 'Atendimentos hoje', value: attendedToday, hint: 'Pacientes finalizados', icon: 'check', accent: 'emerald' })}
        ${statCard({ label: 'Aguardando', value: waiting, hint: priority + ' prioritários', icon: 'users', accent: 'amber' })}
        ${statCard({ label: 'Em atendimento', value: emAtendimento, hint: 'Em consulta agora', icon: 'activity', accent: 'teal' })}
        ${statCard({ label: 'Ausentes', value: absent, hint: 'Pacientes faltosos', icon: 'x', accent: 'rose' })}
        ${statCard({ label: 'Tempo médio de espera', value: formatMinutes(metrics?.avgWaitMinutes ?? 0), hint: 'Check-in até chamada', icon: 'clock', accent: 'violet' })}
        ${statCard({ label: 'Tempo médio de atendimento', value: formatMinutes(metrics?.avgServiceMinutes ?? 0), hint: 'Duração da consulta', icon: 'history', accent: 'slate' })}
      </div>
    `;

    // Quick actions
    const quickActions = `
      <div class="section-title">Ações Rápidas</div>
      <div class="grid grid-3 mb-6">
        <a href="multiroes.jsp" class="card quick-action">
          <div class="quick-action__inner">
            <div class="quick-action__icon" style="background:var(--teal-50);color:var(--teal-700)">${ICONS.plus}</div>
            <div style="min-width:0">
              <div style="font-weight:600">Novo Mutirão</div>
              <div style="font-size:12px;color:var(--text-muted)">Agende um novo evento</div>
            </div>
          </div>
        </a>
        <a href="usuarios.jsp" class="card quick-action">
          <div class="quick-action__inner">
            <div class="quick-action__icon" style="background:var(--amber-50);color:var(--amber-700)">${ICONS.users}</div>
            <div style="min-width:0">
              <div style="font-weight:600">Gerenciar Usuários</div>
              <div style="font-size:12px;color:var(--text-muted)">Atendentes e médicos</div>
            </div>
          </div>
        </a>
        <a href="relatorios.jsp" class="card quick-action">
          <div class="quick-action__inner">
            <div class="quick-action__icon" style="background:var(--emerald-50);color:var(--emerald-700)">${ICONS.chart}</div>
            <div style="min-width:0">
              <div style="font-weight:600">Ver Relatórios</div>
              <div style="font-size:12px;color:var(--text-muted)">Métricas e indicadores</div>
            </div>
          </div>
        </a>
      </div>
    `;

    // Recent sessions (top 3)
    const recentSessions = sessions.slice(0, 3);
    const recentSessionsHtml = recentSessions.length === 0
      ? emptyState({ icon: 'calendar', title: 'Nenhum mutirão', message: 'Os mutirões cadastrados aparecerão aqui.' })
      : `
        <div class="card">
          <div class="card__header">
            <div class="card__title">Multirões recentes</div>
            <a href="multiroes.jsp" class="btn btn--ghost btn--sm">Ver todos</a>
          </div>
          <div class="card__body--p0">
            ${recentSessions.map(s => `
              <div class="session-item">
                <div class="session-item__icon" style="background:var(--slate-100);color:var(--slate-700)">${ICONS.calendar}</div>
                <div style="flex:1;min-width:0">
                  <div style="font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(s.name)}</div>
                  <div style="font-size:12px;color:var(--text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(s.location)} &middot; ${formatDate(s.date)}</div>
                </div>
                ${sessionStatusBadge(s.status)}
              </div>
            `).join('')}
          </div>
        </div>
      `;

    // Recent activity (top 8 from history)
    const recentActivity = history.slice(0, 8);
    const activityHtml = recentActivity.length === 0
      ? emptyState({ icon: 'history', title: 'Sem atividade', message: 'Os atendimentos finalizados aparecerão aqui.' })
      : `
        <div class="card">
          <div class="card__header">
            <div class="card__title">Atividade recente</div>
            <span class="badge badge--slate">${history.length} registros</span>
          </div>
          <div class="card__body--p0" style="max-height:420px;overflow-y:auto" class="custom-scroll">
            ${recentActivity.map(h => {
              const tone = h.status === 'atendido' ? 'emerald' : h.status === 'ausente' ? 'rose' : 'violet';
              const icon = h.status === 'atendido' ? 'check' : h.status === 'ausente' ? 'x' : 'refresh';
              return `
                <div class="activity-item">
                  <div class="activity-item__icon" style="background:var(--${tone}-50);color:var(--${tone}-700)">${ICONS[icon]}</div>
                  <div style="flex:1;min-width:0">
                    <div style="font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(h.patientName || '—')}</div>
                    <div style="font-size:12px;color:var(--text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                      Senha ${escapeHtml(h.password)} &middot; ${escapeHtml(h.queueName || '')} &middot; ${relativeTime(h.finishedAt || h.calledAt || h.enteredAt)}
                    </div>
                  </div>
                  ${statusBadge(h.status)}
                </div>
              `;
            }).join('')}
          </div>
        </div>
      `;

    document.getElementById('content').innerHTML = `
      ${sessionBanner}
      ${stats}
      ${quickActions}
      <div class="section-title">Atividade</div>
      <div class="grid grid-2">
        ${recentSessionsHtml}
        ${activityHtml}
      </div>
    `;
  }
</script>
</body>
</html>
