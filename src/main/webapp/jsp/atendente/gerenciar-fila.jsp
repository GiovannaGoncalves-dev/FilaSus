<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Gerenciar Fila</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .call-next-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      width: 100%;
      padding: 12px;
      font-size: 15px;
      font-weight: 700;
      background: linear-gradient(135deg, var(--teal-600), var(--emerald-600));
      color: #fff;
      border: none;
      border-radius: var(--radius-lg);
      cursor: pointer;
      box-shadow: 0 8px 24px -8px rgba(13, 148, 136, 0.4);
      transition: transform 0.1s, box-shadow 0.2s, opacity 0.2s;
    }
    .call-next-btn:hover:not(:disabled) {
      transform: translateY(-1px);
      box-shadow: 0 12px 28px -8px rgba(13, 148, 136, 0.5);
    }
    .call-next-btn:active { transform: translateY(0); }
    .call-next-btn:disabled { opacity: 0.5; cursor: not-allowed; }
    .call-next-btn__icon {
      width: 24px; height: 24px;
      border-radius: 50%;
      background: rgba(255,255,255,0.2);
      display: flex; align-items: center; justify-content: center;
    }
    .now-serving-grid .card__body { padding: 14px 16px; justify-content: center; }

    .now-serving {
      display: grid;
      grid-template-columns: minmax(136px, auto) minmax(240px, 1fr) auto;
      grid-template-areas:
        "status status status"
        "password patient actions";
      align-items: center;
      column-gap: 24px;
      row-gap: 10px;
      padding: 14px 16px 16px;
      border-radius: var(--radius);
      background: linear-gradient(135deg, var(--teal-50), var(--emerald-50));
      border: 1px solid var(--teal-200);
    }
    .now-serving--empty {
      display: flex;
      background: var(--surface-2);
      border: 1px dashed var(--border-strong);
      align-items: center;
      justify-content: center;
      padding: 24px;
      text-align: center;
    }
    .now-serving-grid { align-items: stretch; }
    .now-serving-grid .card { display: flex; flex-direction: column; }
    .now-serving-grid .card__body { flex: 1; display: flex; flex-direction: column; }
    .now-serving-grid .card__body > .now-serving { flex: 1; }
    .now-serving__label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-muted);
    }
    .now-serving__status {
      grid-area: status;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      min-width: 0;
    }
    .now-serving__ticket {
      grid-area: password;
      display: flex;
      align-items: center;
      min-height: 52px;
      padding-right: 24px;
      border-right: 1px solid var(--teal-200);
    }
    .now-serving__password {
      font-family: var(--font-mono);
      font-weight: 700;
      font-size: clamp(30px, 3vw, 38px);
      color: var(--teal-700);
      line-height: 1;
      letter-spacing: 0.02em;
      font-variant-numeric: tabular-nums;
      white-space: nowrap;
    }
    .now-serving__patient {
      grid-area: patient;
      min-width: 0;
    }
    .now-serving__name {
      font-size: 16px;
      font-weight: 600;
      line-height: 1.3;
      text-wrap: balance;
    }
    .now-serving__meta {
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 2px;
      display: flex;
      align-items: center;
      gap: 4px;
    }
    .now-serving__actions {
      grid-area: actions;
      display: grid;
      grid-template-columns: repeat(2, max-content);
      gap: 8px;
      justify-content: end;
    }
    .now-serving__actions .btn {
      min-height: 40px;
      justify-content: flex-start;
    }

    @media (max-width: 1100px) {
      .now-serving {
        grid-template-columns: minmax(128px, auto) 1fr;
        grid-template-areas:
          "status status"
          "password patient"
          "actions actions";
      }
      .now-serving__actions {
        grid-template-columns: repeat(4, max-content);
        justify-content: start;
      }
    }

    /* Override queue-row grid for action-heavy layout on mobile */
    @media (max-width: 768px) {
      .now-serving {
        grid-template-columns: 1fr;
        grid-template-areas:
          "status"
          "password"
          "patient"
          "actions";
        gap: 10px;
        padding: 14px;
      }
      .now-serving__ticket {
        min-height: auto;
        padding: 2px 0 10px;
        border-right: 0;
        border-bottom: 1px solid var(--teal-200);
      }
      .now-serving__actions {
        grid-template-columns: repeat(2, minmax(0, 1fr));
        width: 100%;
      }
      .now-serving__actions .btn { justify-content: center; }
      .queue-header { display: none; }
      .queue-row {
        grid-template-columns: 1fr;
        gap: 6px;
        padding: 12px;
      }
      .queue-row__password { font-size: 18px; }
      .queue-row > div { display: flex; align-items: center; gap: 8px; }
      .queue-row > div:last-child { justify-content: flex-end; flex-wrap: wrap; }
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
    .queue-single-card .card__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 16px 20px;
      flex-wrap: wrap;
    }
    .queue-single-card .card__body {
      padding: 16px 20px;
    }
    .queue-single-card .card__body--p0 {
      padding: 0;
    }
    .queue-single-card .queue-list-header {
      display: grid;
      grid-template-columns: 80px 1fr 100px 100px 60px 140px;
      gap: 12px;
      padding: 12px 20px;
      background: var(--surface-2);
      border-bottom: 1px solid var(--border);
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      color: var(--text-muted);
      letter-spacing: 0.03em;
    }
    .queue-single-card .queue-list-item {
      display: grid;
      grid-template-columns: 80px 1fr 100px 100px 60px 140px;
      gap: 12px;
      padding: 14px 20px;
      border-bottom: 1px solid var(--border);
      align-items: center;
      font-size: 14px;
    }
    .queue-single-card .queue-list-item:last-child {
      border-bottom: none;
    }
    .queue-single-card .queue-list-empty {
      padding: 40px 20px;
      text-align: center;
      color: var(--text-muted);
      font-size: 14px;
    }
    @media (max-width: 768px) {
      .queue-single-card .queue-list-header { display: none; }
      .queue-single-card .queue-list-item {
        grid-template-columns: 1fr auto;
        grid-template-areas:
          "password priority"
          "patient patient"
          "details details"
          "actions actions";
        gap: 10px 12px;
        margin: 0 12px 10px;
        padding: 14px;
        border: 1px solid var(--border);
        border-radius: var(--radius);
        background: var(--surface);
      }
      .queue-single-card .queue-list-item:first-child { margin-top: 12px; }
      .queue-single-card .queue-list-item:last-child { margin-bottom: 12px; }
      .queue-list-item__password {
        grid-area: password;
        align-self: center;
      }
      .queue-list-item__patient {
        grid-area: patient;
        padding-top: 10px;
        border-top: 1px solid var(--border);
      }
      .queue-list-item__priority { grid-area: priority; }
      .queue-list-item__details {
        grid-area: details;
        display: flex;
        align-items: center;
        gap: 8px;
        color: var(--text-muted);
        font-size: 12px;
      }
      .queue-list-item__details::after {
        content: 'Posição ' attr(data-position);
        font-weight: 600;
        color: var(--slate-700);
      }
      .queue-list-item__position { display: none; }
      .queue-list-item__actions {
        grid-area: actions;
        display: grid;
        grid-template-columns: repeat(2, minmax(0, 1fr));
        gap: 8px;
      }
      .queue-list-item__actions .btn {
        width: 100%;
        min-height: 44px;
      }
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
      metrics: null,
      queues: [],
      activeQueueId: null,
      itemsByQueue: {}, /* queueId -> items[] */
      currentByQueue: {}, /* queueId -> item|null */
      loading: true,
      calling: false,
      autoRefresh: true,
      timerId: null,
    };

    function buildNavGroups() {
      const totalWaiting = state.queues.reduce((sum, q) => {
        return sum + (state.itemsByQueue[q.id]?.filter(i => i.status === 'aguardando').length || 0);
      }, 0);
      return [{
        label: 'Operação',
        items: [
          { key: 'dashboard', label: 'Painel', icon: 'dashboard', href: 'dashboard.jsp' },
          { key: 'cadastrar', label: 'Cadastrar Paciente', icon: 'userPlus', href: 'cadastrar-paciente.jsp' },
          { key: 'fila', label: 'Gerenciar Fila', icon: 'list', href: 'gerenciar-fila.jsp', active: true, badge: totalWaiting || undefined },
          { key: 'historico', label: 'Histórico', icon: 'history', href: 'historico.jsp' },
        ],
      }];
    }

    function renderSkeleton() {
      const childrenHtml = `
        ${pageHeader({ title: 'Gerenciar Fila', subtitle: 'Controle de chamadas em tempo real' })}
        ${'<div class="skeleton" style="height:80px;margin-bottom:16px"></div>'}
        ${'<div class="skeleton" style="height:200px;margin-bottom:16px"></div>'}
        ${'<div class="skeleton" style="height:400px"></div>'}
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Gerenciar Fila',
        user,
        childrenHtml,
      });
    }

    function renderStats() {
      const m = state.metrics || {};
      const cards = [
        statCard({ label: 'Aguardando', value: m.totalWaiting ?? 0, hint: 'Na fila agora', icon: 'users', accent: 'teal' }),
        statCard({ label: 'Prioritários', value: m.totalPriority ?? 0, hint: 'Na fila agora', icon: 'shield', accent: 'amber' }),
        statCard({ label: 'Chamados', value: m.totalCalled ?? 0, hint: 'Chamados / em consulta', icon: 'volume', accent: 'violet' }),
        statCard({ label: 'Atendidos', value: m.totalAttended ?? 0, hint: 'Concluídos', icon: 'check', accent: 'emerald' }),
        statCard({ label: 'Ausentes', value: m.totalAbsent ?? 0, hint: 'Não compareceram', icon: 'ban', accent: 'rose' }),
        statCard({ label: 'Espera Média', value: formatMinutes(m.avgWaitMinutes || 0), hint: 'Tempo médio de espera', icon: 'clock', accent: 'slate' }),
      ];
      return `<div class="grid grid-3 mb-4">${cards.join('')}</div>`;
    }

    function renderTabs() {
      if (!state.queues.length) return '';
      const tabsHtml = `
        <div class="tabs">
          ${state.queues.map(q => {
            const waiting = (state.itemsByQueue[q.id] || []).filter(i => i.status === 'aguardando').length;
            const isActive = q.id === state.activeQueueId;
            return `
              <button class="tab ${isActive ? 'tab--active' : ''}" onclick="selectQueue('${q.id}')">
                ${escapeHtml(q.name)}
                <span class="tab__count">${waiting}</span>
              </button>
            `;
          }).join('')}
        </div>
      `;
      return tabsScroller(tabsHtml, 'queue-tabs-scroller');
    }

    function renderNowServing() {
      const current = state.currentByQueue[state.activeQueueId];
      if (!current) {
        return `
          <div class="now-serving now-serving--empty">
            <div class="empty-state" style="padding:8px">
              <div class="empty-state__icon" style="width:32px;height:32px;margin-bottom:6px">${ICONS.volume}</div>
              <div class="empty-state__title" style="font-size:13px">Em atendimento agora</div>
              <div class="empty-state__message" style="font-size:12px">Nenhum paciente chamado nesta fila. Clique em "Chamar Próximo" para iniciar.</div>
            </div>
          </div>
        `;
      }
      const queue = state.queues.find(q => q.id === current.queueId);
      const elapsed = current.calledAt
        ? Math.max(0, Math.round((Date.now() - new Date(current.calledAt).getTime()) / 60000))
        : 0;
      return `
        <div class="now-serving">
          <div class="now-serving__status">
            <div class="now-serving__label">
              ${current.status === 'em_atendimento' ? 'Em atendimento agora' : 'Chamado · aguardando paciente'}
            </div>
            ${current.priority === 'prioritario' ? `<span class="badge badge--amber">${ICONS.shield} Prioritário</span>` : ''}
          </div>
          <div class="now-serving__ticket">
            <div class="now-serving__password">${escapeHtml(current.password)}</div>
          </div>
          <div class="now-serving__patient">
            <div class="now-serving__name">${escapeHtml(current.patientName || '—')}</div>
            <div class="now-serving__meta">
              ${current.patientAge !== undefined ? current.patientAge + ' anos' : ''}
              ${current.patientCpf ? ' · CPF ' + escapeHtml(current.patientCpf) : ''}
              ${queue ? ' · ' + escapeHtml(queue.name) : ''}
            </div>
            <div class="now-serving__meta">
              ${ICONS.clock}
              Chamado há ${elapsed} min · ${formatTime(current.calledAt)}
            </div>
          </div>
          <div class="now-serving__actions">
            <button class="btn btn--outline btn--sm" onclick="recall('${current.id}')">
              ${ICONS.volume}
              Chamar Novamente
            </button>
            <button class="btn btn--outline btn--sm" onclick="markAbsent('${current.id}', '${escapeHtml(current.password)}', '${escapeHtml(current.patientName || '')}')">
              ${ICONS.ban}
              Marcar Ausente
            </button>
            <button class="btn btn--outline btn--sm" onclick="reschedule('${current.id}', '${escapeHtml(current.password)}', '${escapeHtml(current.patientName || '')}')">
              ${ICONS.refresh}
              Remarcar
            </button>
            <button class="btn btn--outline btn--sm" onclick="returnToWaiting('${current.id}', '${escapeHtml(current.password)}')">
              ${ICONS.arrowLeft}
              Devolver à Fila
            </button>
          </div>
        </div>
      `;
    }

    function rowActions(item) {
      const actions = [];
      if (item.status === 'aguardando') {
        actions.push(`
          <button class="btn btn--primary btn--sm" onclick="callNext('${item.queueId}')" title="Chamar este paciente">
            ${ICONS.play}
            Chamar
          </button>
        `);
        actions.push(`
          <button class="btn btn--outline btn--sm" onclick="markAbsent('${item.id}', '${escapeHtml(item.password)}', '${escapeHtml(item.patientName || '')}')" title="Marcar ausente">
            ${ICONS.ban}
            <span class="hidden-mobile">Ausente</span>
          </button>
        `);
      }
      return actions.join('');
    }

    function renderQueueList() {
      const items = (state.itemsByQueue[state.activeQueueId] || [])
        .filter(i => i.status === 'aguardando');
      if (!items.length) {
        return emptyState({
          icon: 'check',
          title: 'Fila vazia',
          message: 'Não há pacientes aguardando nesta fila.',
        });
      }
      return `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Aguardando atendimento</div>
              <div class="card__description">${items.length} ${items.length === 1 ? 'paciente' : 'pacientes'} na fila</div>
            </div>
          </div>
          <div class="card__body card__body--p0">
            ${queueHeader()}
            <div style="max-height:520px;overflow-y:auto">
              ${items.map(item => queueRow({
                item,
                actions: rowActions(item),
              })).join('')}
            </div>
          </div>
        </div>
      `;
    }

    function renderQueueListInner() {
      const items = (state.itemsByQueue[state.activeQueueId] || [])
        .filter(i => i.status === 'aguardando');
      if (!items.length) {
        return `<div class="queue-list-empty">Não há pacientes aguardando nesta fila.</div>`;
      }
      return `
        <div class="queue-list-header">
          <div>Senha</div>
          <div>Paciente</div>
          <div>Prioridade</div>
          <div>Status</div>
          <div>Pos.</div>
          <div>Ações</div>
        </div>
        <div style="max-height:400px;overflow-y:auto">
          ${items.map(item => `
            <div class="queue-list-item">
              <div class="queue-list-item__password font-mono" style="font-weight:700;font-size:15px">${escapeHtml(item.password)}</div>
              <div class="queue-list-item__patient">
                <div style="font-weight:500">${escapeHtml(item.patientName || '—')}</div>
                ${item.patientAge !== undefined ? `<div style="font-size:12px;color:var(--text-muted)">${item.patientAge} anos</div>` : ''}
              </div>
              <div class="queue-list-item__priority">${priorityBadge(item.priority)}</div>
              <div class="queue-list-item__details" data-position="${item.position ? item.position + 'ª' : '—'}">${statusBadge(item.status)}</div>
              <div class="queue-list-item__position" style="font-weight:600">${item.position ? item.position + 'ª' : '—'}</div>
              <div class="queue-list-item__actions">
                <button class="btn btn--primary btn--sm" onclick="callNext('${item.queueId}')" title="Chamar este paciente">
                  ${ICONS.play}
                  Chamar
                </button>
                <button class="btn btn--outline btn--sm" onclick="markAbsent('${item.id}', '${escapeHtml(item.password)}', '${escapeHtml(item.patientName || '')}')" title="Marcar ausente">
                  ${ICONS.ban}
                  Ausente
                </button>
              </div>
            </div>
          `).join('')}
        </div>
      `;
    }

    function renderPage() {
      if (!state.session) {
        const childrenHtml = `
          ${pageHeader({ title: 'Gerenciar Fila', subtitle: 'Controle de chamadas em tempo real' })}
          <div class="card">
            <div class="card__body">
              <div class="empty-state">
                <div class="empty-state__icon">${ICONS.alert}</div>
                <div class="empty-state__title">Nenhum mutirão aberto</div>
                <div class="empty-state__message">Não há mutirão em andamento para gerenciar a fila.</div>
              </div>
            </div>
          </div>
        `;
        document.getElementById('root').innerHTML = renderAppShell({
          navGroups: buildNavGroups(),
          title: 'Gerenciar Fila',
          user,
          childrenHtml,
        });
        return;
      }

      const queue = state.queues.find(q => q.id === state.activeQueueId);
      const waitingCount = (state.itemsByQueue[state.activeQueueId] || []).filter(i => i.status === 'aguardando').length;

      const childrenHtml = `
        ${pageHeader({
          title: 'Gerenciar Fila',
          subtitle: state.session.name,
          actions: `
            <button class="btn btn--ghost btn--sm" onclick="toggleAutoRefresh()" id="btn-autorefresh">
              ${ICONS.refresh}
              <span id="autorefresh-label">Pausar</span>
            </button>
            <a href="cadastrar-paciente.jsp" class="btn btn--primary btn--sm">
              ${ICONS.userPlus}
              <span class="hidden-mobile">Cadastrar</span>
            </a>
          `,
        })}
        ${renderStats()}
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px;font-size:12px;color:var(--text-muted)">
          <span class="live-dot"></span>
          Atualização automática a cada 5 segundos
        </div>
        ${renderTabs()}

        <div class="card queue-single-card">
          <div class="card__header" style="border-bottom:1px solid var(--border);padding-bottom:12px">
            <div>
              <div class="card__title">${escapeHtml(queue?.name || '—')}</div>
              <div class="card__description">
                ${waitingCount} ${waitingCount === 1 ? 'paciente aguardando' : 'pacientes aguardando'}
                · Prefixo <span class="font-mono">${escapeHtml(queue?.sequencePrefix || '')}</span>
              </div>
            </div>
            <button class="call-next-btn" style="width:auto;padding:10px 24px" onclick="callNext('${state.activeQueueId || ''}')" ${state.calling || waitingCount === 0 ? 'disabled' : ''}>
              <span class="call-next-btn__icon">${ICONS.play}</span>
              ${state.calling ? '<span class="spinner"></span> Chamando...' : 'Chamar Próximo'}
            </button>
          </div>

          <div class="card__body" style="padding:16px">
            ${renderNowServing()}
          </div>

          <div class="card__body card__body--p0" style="border-top:1px solid var(--border)">
            ${renderQueueListInner()}
          </div>
        </div>
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Gerenciar Fila',
        user,
        childrenHtml,
      });
    }

    /* ---------------- Ações ---------------- */
    function selectQueue(id) {
      state.activeQueueId = id;
      renderPage();
    }

    async function callNext(queueId) {
      const qid = queueId || state.activeQueueId;
      if (!qid) return;
      state.calling = true;
      renderPage();
      try {
        const data = await api('/api/queue/call-next', {
          method: 'POST',
          body: { sessionId: state.session.id, queueId: qid },
        });
        if (!data.item) {
          toast(data.message || 'Fila vazia.', 'info');
        } else {
          toast(`${data.item.password} · ${data.item.patientName}`, 'success', 'Paciente chamado!');
        }
      } catch (err) {
        toast(err.message || 'Erro ao chamar próximo paciente.', 'error');
      } finally {
        state.calling = false;
        await loadAll();
      }
    }

    async function recall(itemId) {
      /* Re-chama o mesmo paciente (sem alterar estado) — apenas feedback visual + sonoro simulado */
      const item = findItem(itemId);
      if (!item) return;
      toast(`Chamando novamente: ${item.password} · ${item.patientName}`, 'info', 'Re-chamada');
    }

    async function markAbsent(itemId, password, name) {
      const ok = await confirmDialog({
        title: 'Marcar paciente como ausente?',
        message: `${password} · ${name} será marcado como ausente e removido da fila. Esta ação não pode ser desfeita.`,
        confirmText: 'Marcar Ausente',
        cancelText: 'Cancelar',
        danger: true,
      });
      if (!ok) return;
      try {
        await api(`/api/queue/${itemId}`, { method: 'PATCH', body: { status: 'ausente', reason: 'Não compareceu à chamada' } });
        toast(`${password} marcado como ausente.`, 'success');
        await loadAll();
      } catch (err) {
        toast(err.message || 'Erro ao marcar ausente.', 'error');
      }
    }

    async function reschedule(itemId, password, name) {
      const ok = await confirmDialog({
        title: 'Remarcar paciente?',
        message: `${password} · ${name} será removido da chamada atual e reinserido no final da fila com uma nova senha.`,
        confirmText: 'Remarcar',
        cancelText: 'Cancelar',
      });
      if (!ok) return;
      try {
        const data = await api(`/api/queue/${itemId}`, { method: 'PATCH', body: { status: 'remarcado' } });
        toast(data.message || 'Paciente remarcado.', 'success');
        if (data.newItem) {
          toast(`Nova senha: ${data.newItem.password}`, 'info', 'Reinserido na fila');
        }
        await loadAll();
      } catch (err) {
        toast(err.message || 'Erro ao remarcar.', 'error');
      }
    }

    async function returnToWaiting(itemId, password) {
      const ok = await confirmDialog({
        title: 'Devolver à fila?',
        message: `${password} retornará para a fila de aguardando como prioridade. Útil quando o paciente pediu para sair momentaneamente.`,
        confirmText: 'Devolver',
        cancelText: 'Cancelar',
      });
      if (!ok) return;
      try {
        await api(`/api/queue/${itemId}`, { method: 'PATCH', body: { status: 'aguardando', reason: 'Devolvido à fila pelo atendente' } });
        toast(`${password} devolvido à fila.`, 'success');
        await loadAll();
      } catch (err) {
        toast(err.message || 'Erro ao devolver à fila.', 'error');
      }
    }

    function findItem(id) {
      for (const qid of Object.keys(state.itemsByQueue)) {
        const found = state.itemsByQueue[qid].find(i => i.id === id);
        if (found) return found;
      }
      return null;
    }

    function toggleAutoRefresh() {
      state.autoRefresh = !state.autoRefresh;
      const label = document.getElementById('autorefresh-label');
      if (label) label.textContent = state.autoRefresh ? 'Pausar' : 'Retomar';
      if (state.autoRefresh) {
        startAutoRefresh();
        toast('Atualização automática retomada.', 'info');
      } else {
        stopAutoRefresh();
        toast('Atualização automática pausada.', 'info');
      }
    }

    function startAutoRefresh() {
      stopAutoRefresh();
      if (state.autoRefresh && state.session) {
        state.timerId = setInterval(loadAllSilent, 5000);
      }
    }
    function stopAutoRefresh() {
      if (state.timerId) {
        clearInterval(state.timerId);
        state.timerId = null;
      }
    }

    async function loadAllSilent() {
      try {
        await loadAll(true);
      } catch (err) { /* silencioso */ }
    }

    async function loadAll(silent = false) {
      try {
        const sessionRes = await api('/api/sessions/active');
        state.session = sessionRes.session;
        if (!state.session) {
          state.loading = false;
          renderPage();
          return;
        }
        state.queues = state.session.queues || [];
        if (!state.activeQueueId && state.queues.length) {
          state.activeQueueId = state.queues[0].id;
        }

        const queueRes = await api('/api/queue', { method: 'GET' });
        const allItems = queueRes.items || [];
        state.metrics = queueRes.metrics || null;
        state.queues.forEach(q => {
          state.itemsByQueue[q.id] = allItems.filter(i => i.queueId === q.id)
            .sort((a, b) => {
              if (a.priority !== b.priority) return a.priority === 'prioritario' ? -1 : 1;
              return a.sequence - b.sequence;
            });
          state.currentByQueue[q.id] = state.itemsByQueue[q.id]
            .find(i => ['chamado', 'em_atendimento'].includes(i.status)) || null;
        });

        state.loading = false;
        renderPage();
      } catch (err) {
        if (!silent) toast(err.message || 'Erro ao carregar fila.', 'error');
      }
    }

    /* Inicializa */
    renderSkeleton();
    loadAll().then(startAutoRefresh);
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) stopAutoRefresh();
      else if (state.autoRefresh) startAutoRefresh();
    });
</script>
</body>
</html>
