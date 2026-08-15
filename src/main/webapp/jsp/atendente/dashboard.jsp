<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Painel do Atendente</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .queue-now-card {
      display: flex;
      flex-direction: column;
      gap: 14px;
      height: 100%;
    }
    .queue-now-card > div:last-child {
      flex: 1;
      display: flex;
      flex-direction: column;
    }
    .queue-now-card .queue-now-current {
      flex: 1;
    }
    /* Grid de filas com cards de tamanho igual */
    .queue-cards-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 16px;
      align-items: stretch;
    }
    @media (max-width: 1024px) {
      .queue-cards-grid { grid-template-columns: repeat(2, 1fr); }
    }
    @media (max-width: 640px) {
      .queue-cards-grid { grid-template-columns: 1fr; }
    }
    .queue-now-current {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 12px;
      border-radius: var(--radius);
      background: var(--slate-50);
      border: 1px solid var(--border);
      flex-wrap: wrap;
    }
    .queue-now-current--active {
      background: linear-gradient(135deg, var(--teal-50), var(--emerald-50));
      border-color: var(--teal-200);
    }
    .queue-now-current__label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-muted);
    }
    .queue-now-current__password {
      font-family: var(--font-mono);
      font-weight: 700;
      font-size: 22px;
      color: var(--teal-700);
    }
    .queue-now-current__name {
      font-size: 13px;
      color: var(--text-muted);
      margin-top: 2px;
      max-width: 220px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .recent-calls {
      list-style: none;
      padding: 0;
      margin: 0;
      display: flex;
      flex-direction: column;
      gap: 6px;
      max-height: 200px;
      overflow-y: auto;
    }
    .recent-call {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 10px;
      border-radius: 6px;
      background: var(--surface-2);
      font-size: 13px;
    }
    .recent-call__pwd {
      font-family: var(--font-mono);
      font-weight: 700;
      color: var(--slate-700);
      min-width: 64px;
    }
    .recent-call__name {
      flex: 1;
      color: var(--text-muted);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .recent-call__time {
      font-size: 11px;
      color: var(--text-muted);
      white-space: nowrap;
    }
    .live-dot {
      display: inline-block;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: var(--emerald-500);
      animation: live-pulse 1.5s infinite;
    }
    @keyframes live-pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.8); }
    }
    .ticket-pulse {
      animation: ticket-glow 2s ease-in-out infinite;
    }
    @keyframes ticket-glow {
      0%, 100% { box-shadow: 0 0 0 0 rgba(13, 148, 136, 0); }
      50% { box-shadow: 0 0 0 6px rgba(13, 148, 136, 0.12); }
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
  /* Guard de página */
  if (!requireRole('atendente')) throw new Error('Não autorizado');
    const user = getCurrentUser();
    let dashboardState = {
      session: null,
      items: [],
      metrics: null,
      queueStats: [],   // [{ queue, waitingCount, current, lastCalls }]
      loading: true,
      error: null,
      autoRefresh: true,
      timerId: null,
    };

    function buildNavGroups() {
      const totalWaiting = dashboardState.metrics?.totalWaiting ?? 0;
      return [{
        label: 'Operação',
        items: [
          { key: 'dashboard', label: 'Painel', icon: 'dashboard', href: 'dashboard.jsp', active: true },
          { key: 'cadastrar', label: 'Cadastrar Paciente', icon: 'userPlus', href: 'cadastrar-paciente.jsp' },
          { key: 'fila', label: 'Gerenciar Fila', icon: 'list', href: 'gerenciar-fila.jsp', badge: totalWaiting || undefined },
          { key: 'historico', label: 'Histórico', icon: 'history', href: 'historico.jsp' },
        ],
      }];
    }

    function renderSkeleton() {
      const childrenHtml = `
        ${pageHeader({ title: 'Painel do Atendente', subtitle: 'Visão geral da operação de hoje' })}
        <div class="card mb-4"><div class="card__body">${'<div class="skeleton" style="height:80px"></div>'}</div></div>
        ${skeletonGrid(6, '110px')}
        <div class="card mt-4"><div class="card__body">${'<div class="skeleton" style="height:300px"></div>'}</div></div>
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Painel',
        user,
        childrenHtml,
      });
    }

    function renderSessionCard() {
      const s = dashboardState.session;
      if (!s) {
        return `
          <div class="card mb-4">
            <div class="card__body">
              <div class="empty-state" style="padding:24px">
                <div class="empty-state__icon">${ICONS.alert}</div>
                <div class="empty-state__title">Nenhum mutirão aberto</div>
                <div class="empty-state__message">Não há mutirão em andamento no momento. Verifique com a administração.</div>
              </div>
            </div>
          </div>
        `;
      }
      return `
        <div class="card mb-4">
          <div class="card__body" style="display:flex;align-items:center;gap:16px;flex-wrap:wrap">
            <div style="width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,var(--teal-500),var(--emerald-600));color:#fff;display:flex;align-items:center;justify-content:center;flex-shrink:0">
              ${ICONS.heart}
            </div>
            <div style="flex:1;min-width:200px">
              <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
                <h2 style="font-size:18px;font-weight:700;margin:0">${escapeHtml(s.name)}</h2>
                ${sessionStatusBadge(s.status)}
              </div>
              <div style="font-size:13px;color:var(--text-muted);margin-top:4px;display:flex;align-items:center;gap:6px;flex-wrap:wrap">
                <span style="display:inline-flex;align-items:center;gap:4px">${ICONS.mapPin}${escapeHtml(s.location || '—')}</span>
                <span>·</span>
                <span style="display:inline-flex;align-items:center;gap:4px">${ICONS.calendar}${formatDate(s.date)}</span>
                <span>·</span>
                <span style="display:inline-flex;align-items:center;gap:4px">${ICONS.clock}${escapeHtml(s.startTime)}—${escapeHtml(s.endTime)}</span>
              </div>
            </div>
            <a href="cadastrar-paciente.jsp" class="btn btn--outline btn--sm">
              ${ICONS.userPlus}
              Cadastrar Paciente
            </a>
            <a href="gerenciar-fila.jsp" class="btn btn--primary btn--sm">
              ${ICONS.list}
              Gerenciar Fila
            </a>
          </div>
        </div>
      `;
    }

    function renderStats() {
      const m = dashboardState.metrics || {};
      const cards = [
        statCard({ label: 'Aguardando', value: m.totalWaiting ?? 0, hint: 'Na fila agora', icon: 'clock', accent: 'teal' }),
        statCard({ label: 'Prioritários', value: m.totalPriority ?? 0, hint: 'Aguardando prioridade', icon: 'shield', accent: 'amber' }),
        statCard({ label: 'Em Atendimento', value: m.totalCalled ?? 0, hint: 'Chamados / em consulta', icon: 'stethoscope', accent: 'violet' }),
        statCard({ label: 'Atendidos', value: m.totalAttended ?? 0, hint: 'Concluídos hoje', icon: 'check', accent: 'emerald' }),
        statCard({ label: 'Ausentes', value: m.totalAbsent ?? 0, hint: 'Não compareceram', icon: 'ban', accent: 'rose' }),
        statCard({ label: 'Espera Média', value: formatMinutes(m.avgWaitMinutes || 0), hint: 'Tempo médio de espera', icon: 'activity', accent: 'slate' }),
      ];
      return `<div class="grid grid-3 mb-4">${cards.join('')}</div>`;
    }

    function renderQueueCard(qs) {
      const { queue, waitingCount, priorityWaitingCount, current, lastCalls } = qs;
      const currentActive = current && ['chamado', 'em_atendimento'].includes(current.status);
      return `
        <div class="card queue-now-card">
          <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:14px 16px;border-bottom:1px solid var(--border)">
            <div>
              <div style="font-size:14px;font-weight:600">${escapeHtml(queue.name)}</div>
              <div style="font-size:11px;color:var(--text-muted);margin-top:2px">
                Prefixo <span class="font-mono">${escapeHtml(queue.sequencePrefix)}</span> · média ${queue.avgServiceMinutes} min
              </div>
            </div>
            <span class="badge badge--slate">${waitingCount} aguardando</span>
          </div>

          <div style="padding:0 16px 16px;flex:1;display:flex;flex-direction:column">
            <div class="queue-now-current ${currentActive ? 'queue-now-current--active' : ''}" style="flex:1">
              <div>
                <div class="queue-now-current__label">${currentActive ? 'Em atendimento agora' : 'Ninguém chamado'}</div>
                ${currentActive ? `
                  <div class="queue-now-current__password">${escapeHtml(current.password)}</div>
                  <div class="queue-now-current__name">${escapeHtml(current.patientName || '—')}</div>
                ` : `
                  <div style="font-size:13px;color:var(--text-muted);margin-top:6px">Fila pronta para chamada.</div>
                `}
              </div>
              <button class="btn btn--primary btn--sm" onclick="callNext('${queue.id}')" ${waitingCount === 0 ? 'disabled' : ''}>
                ${ICONS.play}
                Chamar Próximo
              </button>
            </div>
            <div style="display:flex;align-items:center;gap:6px;margin-top:10px;font-size:12px;color:var(--amber-700)">
              ${ICONS.shield}${priorityWaitingCount} prioritário(s)
            </div>
          </div>
        </div>
      `;
    }

    function renderRecentCalls() {
      const all = dashboardState.queueStats
        .flatMap(qs => qs.lastCalls.map(c => ({ ...c, queueName: qs.queue.name })))
        .sort((a, b) => new Date(b.calledAt || b.enteredAt) - new Date(a.calledAt || a.enteredAt))
        .slice(0, 5);
      if (!all.length) {
        return '';
      }
      return `
        <div class="card mb-4">
          <div class="card__header">
            <div class="card__title">${ICONS.volume} Últimas Chamadas</div>
          </div>
          <div class="card__body" style="padding:0;max-height:320px;overflow-y:auto">
            ${all.map(c => `
              <div style="display:flex;align-items:center;justify-content:space-between;gap:12px;padding:12px 16px;border-bottom:1px solid var(--border)">
                <div style="display:flex;align-items:center;gap:12px;min-width:0">
                  <span class="font-mono" style="font-weight:700;min-width:64px">${escapeHtml(c.password)}</span>
                  <div style="min-width:0">
                    <div style="font-size:13px;font-weight:500">${escapeHtml(c.patientName || '—')}</div>
                    <div style="font-size:11px;color:var(--text-muted)">${escapeHtml(c.queueName)} · chamada ${relativeTime(c.calledAt || c.enteredAt)}</div>
                  </div>
                </div>
                <div style="display:flex;gap:6px;flex-shrink:0">
                  <span class="badge ${priorityBadgeClass(c.priority)}">${PRIORITY_LABELS[c.priority] || c.priority}</span>
                  <span class="badge ${statusBadgeClass(c.status)}">${STATUS_LABELS[c.status] || c.status}</span>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    }

    function renderPriorityBanner() {
      const totalPriority = dashboardState.metrics?.totalPriority ?? 0;
      if (!totalPriority) return '';
      return `
        <div class="alert alert--warning">
          ${ICONS.shield}
          <div>
            <div class="alert__title">Pacientes prioritários aguardando</div>
            <div class="alert__message">
              Há ${totalPriority} paciente(s) prioritário(s) na fila. Eles serão chamados antes dos pacientes comuns pelo botão "Chamar Próximo".
              Algumas prioridades ainda aguardam validação do médico.
            </div>
          </div>
        </div>
      `;
    }

    function renderRealTimeQueues() {
      const qs = dashboardState.queueStats;
      if (!qs.length) {
        return emptyState({
          icon: 'list',
          title: 'Sem filas configuradas',
          message: 'Este mutirão ainda não possui filas de atendimento.',
        });
      }
      return `
        <div class="card mb-4">
          <div class="card__header">
            <div>
              <div class="card__title">Fila em Tempo Real</div>
              <div class="card__description">
                <span class="live-dot"></span>
                <span style="margin-left:6px">Atualização automática a cada 5 segundos</span>
              </div>
            </div>
            <button class="btn btn--ghost btn--sm" onclick="toggleAutoRefresh()" id="btn-autorefresh">
              ${ICONS.refresh}
              <span id="autorefresh-label">Pausar</span>
            </button>
          </div>
          <div class="card__body">
            <div class="queue-cards-grid">
              ${qs.map(renderQueueCard).join('')}
            </div>
          </div>
        </div>
      `;
    }

    function renderPage() {
      const childrenHtml = `
        ${pageHeader({ title: 'Painel do Atendente', subtitle: 'Visão geral da operação de hoje' })}
        ${renderSessionCard()}
        ${renderStats()}
        ${renderRealTimeQueues()}
        ${renderRecentCalls()}
        ${renderPriorityBanner()}
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Painel',
        user,
        childrenHtml,
      });
    }

    async function callNext(queueId) {
      const sessionId = dashboardState.session?.id;
      if (!sessionId) {
        toast('Nenhum mutirão aberto.', 'warning');
        return;
      }
      try {
        const data = await api('/api/queue/call-next', { method: 'POST', body: { sessionId, queueId } });
        if (!data.item) {
          toast(data.message || 'Fila vazia.', 'info');
        } else {
          toast(`Paciente ${data.item.patientName} chamado: ${data.item.password}`, 'success', 'Chamado!');
        }
        await loadAll();
      } catch (err) {
        toast(err.message || 'Erro ao chamar próximo paciente.', 'error');
      }
    }

    function toggleAutoRefresh() {
      dashboardState.autoRefresh = !dashboardState.autoRefresh;
      const label = document.getElementById('autorefresh-label');
      if (label) label.textContent = dashboardState.autoRefresh ? 'Pausar' : 'Retomar';
      if (dashboardState.autoRefresh) {
        startAutoRefresh();
        toast('Atualização automática retomada.', 'info');
      } else {
        stopAutoRefresh();
        toast('Atualização automática pausada.', 'info');
      }
    }

    function startAutoRefresh() {
      stopAutoRefresh();
      if (dashboardState.autoRefresh) {
        dashboardState.timerId = setInterval(loadAll, 5000);
      }
    }
    function stopAutoRefresh() {
      if (dashboardState.timerId) {
        clearInterval(dashboardState.timerId);
        dashboardState.timerId = null;
      }
    }

    async function loadAll() {
      try {
        const sessionRes = await api('/api/sessions/active');
        dashboardState.session = sessionRes.session;
        if (!dashboardState.session) {
          dashboardState.loading = false;
          renderPage();
          return;
        }
        const queueRes = await api('/api/queue', { method: 'GET' });
        dashboardState.items = queueRes.items || [];
        dashboardState.metrics = queueRes.metrics || null;

        const queues = dashboardState.session.queues || [];
        dashboardState.queueStats = queues.map(q => {
          const qItems = dashboardState.items.filter(i => i.queueId === q.id);
          const current = qItems.find(i => ['chamado', 'em_atendimento'].includes(i.status)) || null;
          const waitingCount = qItems.filter(i => i.status === 'aguardando').length;
          const priorityWaitingCount = qItems.filter(i => i.status === 'aguardando' && i.priority === 'prioritario').length;
          const lastCalls = qItems
            .filter(i => ['chamado', 'em_atendimento', 'atendido'].includes(i.status))
            .sort((a, b) => new Date(b.calledAt || b.enteredAt) - new Date(a.calledAt || a.enteredAt))
            .slice(0, 5);
          return { queue: q, waitingCount, priorityWaitingCount, current, lastCalls };
        });

        dashboardState.loading = false;
        renderPage();
      } catch (err) {
        dashboardState.loading = false;
        dashboardState.error = err.message;
        toast(err.message || 'Erro ao carregar dados.', 'error');
      }
    }

    /* Inicializa */
    renderSkeleton();
    loadAll().then(startAutoRefresh);
    /* Pausa o refresh quando a aba está oculta para poupar recurso */
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) stopAutoRefresh();
      else if (dashboardState.autoRefresh) startAutoRefresh();
    });
</script>
</body>
</html>
