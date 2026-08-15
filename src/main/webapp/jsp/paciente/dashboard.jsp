<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Minha Fila</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    /* Hero específico do dashboard do paciente */
    .hero-paciente {
      position: relative;
      overflow: hidden;
      border-radius: 16px;
      border: 2px solid var(--teal-200);
      background:
        radial-gradient(120% 120% at 100% 0%, var(--amber-50) 0%, transparent 45%),
        radial-gradient(120% 120% at 0% 100%, var(--emerald-50) 0%, transparent 45%),
        linear-gradient(135deg, var(--teal-50), var(--surface));
      padding: 28px;
    }
    .hero-paciente__badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(255,255,255,0.7);
      color: var(--teal-700);
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      border: 1px solid var(--teal-100);
    }
    .hero-paciente__title {
      font-size: 28px;
      font-weight: 700;
      letter-spacing: -0.01em;
      margin-top: 12px;
      line-height: 1.15;
    }
    .hero-paciente__subtitle {
      font-size: 14px;
      color: var(--text-muted);
      margin-top: 6px;
      max-width: 640px;
    }
    .hero-paciente__stats {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      margin-top: 20px;
    }
    .hero-stat {
      background: rgba(255,255,255,0.8);
      backdrop-filter: blur(4px);
      border: 1px solid var(--teal-100);
      border-radius: 12px;
      padding: 12px 14px;
    }
    .hero-stat__label {
      display: flex;
      align-items: center;
      gap: 6px;
      color: var(--teal-700);
      font-size: 10px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .hero-stat__value {
      font-size: 26px;
      font-weight: 700;
      letter-spacing: -0.01em;
      margin-top: 4px;
    }
    @media (max-width: 640px) {
      .hero-paciente { padding: 20px; }
      .hero-paciente__title { font-size: 22px; }
      .hero-paciente__stats { grid-template-columns: 1fr; }
    }
    .info-banner {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      background: var(--amber-50);
      border: 1px solid var(--amber-200);
      border-radius: 12px;
      padding: 16px 18px;
    }
    .info-banner__icon {
      flex-shrink: 0;
      width: 38px;
      height: 38px;
      border-radius: 10px;
      background: var(--amber-100);
      color: var(--amber-700);
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .info-banner__title { font-size: 14px; font-weight: 600; color: var(--amber-800); }
    .info-banner__message {
      font-size: 12.5px;
      color: var(--amber-800);
      margin-top: 2px;
      line-height: 1.5;
    }
    .section-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 14px;
    }
    .section-title__icon { color: var(--primary); display: inline-flex; }
    .section-title__count {
      font-size: 11px;
      color: var(--text-muted);
      margin-left: auto;
      font-weight: 500;
    }
    .ticket-card-wrap { display: flex; flex-direction: column; gap: 8px; }
    .ticket-meta {
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 8px;
      padding: 0 4px;
    }
    .ticket-session {
      font-size: 11px;
      color: var(--text-muted);
      padding: 0 4px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .history-table-wrap { max-height: 384px; overflow-y: auto; }
    .history-grid {
      display: grid;
      grid-template-columns: 80px 1.6fr 1.4fr 1fr 1fr;
      gap: 12px;
      padding: 10px 16px;
      border-bottom: 1px solid var(--border);
      align-items: center;
      font-size: 13px;
    }
    .history-grid--header {
      background: var(--surface-2);
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--text-muted);
      font-weight: 600;
    }
    .history-grid:hover:not(.history-grid--header) { background: var(--slate-50); }
    .history-grid:last-child { border-bottom: none; }
    .history-password {
      font-family: var(--font-mono);
      font-weight: 700;
      letter-spacing: 0.05em;
    }
    .history-sub { font-size: 10.5px; color: var(--text-muted); margin-top: 2px; }
    @media (max-width: 768px) {
      .history-grid { grid-template-columns: 1fr; gap: 4px; padding: 12px 14px; }
      .history-grid--header { display: none; }
      .history-password { font-size: 16px; }
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
  const firstName = (user.name || 'Paciente').split(' ')[0];

  const navGroups = [{
    label: 'Paciente',
    items: [
      { key: 'dashboard',  label: 'Minha Fila',          icon: 'dashboard', href: 'dashboard.jsp',           active: true },
      { key: 'meus-dados', label: 'Meus Dados',          icon: 'user',      href: 'meus-dados.jsp' },
      { key: 'prioridade', label: 'Solicitar Prioridade',icon: 'alert',     href: 'solicitar-prioridade.jsp' },
    ],
  }];

  /* ---------- Estado ---------- */
  let myItems = [];
  let historyItems = [];
  let isLoadingQueue = true;
  let isLoadingHistory = true;

  /* ---------- Render shell ---------- */
  function renderShell() {
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Minha Fila',
      user,
      childrenHtml: `
        <div id="page-content">
          <div class="flex items-center justify-center" style="min-height:300px">
            <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
          </div>
        </div>
      `,
    });
  }

  /* ---------- Hero ---------- */
  function heroHtml() {
    const activeCount = myItems.length;
    const waitingCount = myItems.filter(i => i.status === 'aguardando').length;
    const historyCount = historyItems.length;
    const subtitle = activeCount > 0
      ? `Você possui ${activeCount} ${activeCount === 1 ? 'senha ativa' : 'senhas ativas'}`
        + (waitingCount > 0 ? ` · ${waitingCount} aguardando atendimento.` : '.')
      : 'Você não possui senhas ativas no momento.';
    return `
      <section class="hero-paciente" aria-labelledby="hero-title">
        <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px">
          <div style="min-width:0">
            <span class="hero-paciente__badge">
              <span style="width:8px;height:8px;background:var(--teal-500);border-radius:50%;display:inline-block"></span>
              Bem-vindo(a)
            </span>
            <h2 id="hero-title" class="hero-paciente__title">Olá, ${escapeHtml(firstName)}!</h2>
            <p class="hero-paciente__subtitle">${escapeHtml(subtitle)}</p>
          </div>
          <a href="meus-dados.jsp" class="btn btn--outline btn--sm" style="flex-shrink:0;gap:6px">
            ${ICONS.user}<span class="hidden-mobile">Ver meus dados</span>
          </a>
        </div>
        <div class="hero-paciente__stats">
          <div class="hero-stat">
            <div class="hero-stat__label">${ICONS.ticket}<span>Senhas ativas</span></div>
            <div class="hero-stat__value">${activeCount}</div>
          </div>
          <div class="hero-stat">
            <div class="hero-stat__label">${ICONS.users}<span>Aguardando</span></div>
            <div class="hero-stat__value">${waitingCount}</div>
          </div>
          <div class="hero-stat">
            <div class="hero-stat__label">${ICONS.history}<span>Atendimentos anteriores</span></div>
            <div class="hero-stat__value">${historyCount}</div>
          </div>
        </div>
      </section>
    `;
  }

  /* ---------- Banner "Como entrar em uma fila?" ---------- */
  function bannerHtml() {
    return `
      <section class="info-banner" aria-labelledby="how-to-title" style="margin-top:20px">
        <div class="info-banner__icon">${ICONS.info}</div>
        <div style="min-width:0">
          <div id="how-to-title" class="info-banner__title">Como entrar em uma fila de atendimento?</div>
          <p class="info-banner__message">
            A entrada em filas é feita <strong>exclusivamente pelo atendente</strong> na recepção do mutirão.
            Dirija-se ao balcão, apresente seu CPF e o atendente irá inseri-lo na fila adequada, gerando sua senha.
            Você poderá acompanhar sua posição e o tempo de espera por aqui.
          </p>
        </div>
      </section>
    `;
  }

  /* ---------- Active tickets ---------- */
  function activeTicketsHtml() {
    if (isLoadingQueue) {
      return `
        <section aria-labelledby="active-title" style="margin-top:24px">
          <h3 id="active-title" class="section-title">
            <span class="section-title__icon">${ICONS.ticket}</span>
            Minhas Senhas Ativas
          </h3>
          ${skeletonGrid(2, '180px')}
        </section>
      `;
    }
    if (myItems.length === 0) {
      return `
        <section aria-labelledby="active-title" style="margin-top:24px">
          <h3 id="active-title" class="section-title">
            <span class="section-title__icon">${ICONS.ticket}</span>
            Minhas Senhas Ativas
          </h3>
          ${emptyState({
            icon: 'ticket',
            title: 'Nenhuma senha ativa',
            message: 'Você não está em nenhuma fila no momento. Dirija-se à recepção do mutirão para que um atendente insira você na fila e gere sua senha.',
          })}
        </section>
      `;
    }
    const cards = myItems.map(item => `
      <article class="ticket-card-wrap">
        ${passwordTicket({
          password: item.password,
          patientName: item.patientName,
          queueName: item.queueName,
          sessionName: item.sessionName,
          position: item.position,
          estimatedWaitMinutes: item.estimatedWaitMinutes,
          priority: item.priority,
          priorityReason: item.priorityReason,
          status: item.status,
          priorityValidation: item.priorityValidation,
          size: 'md',
        })}
      </article>
    `).join('');
    return `
      <section aria-labelledby="active-title" style="margin-top:24px">
        <h3 id="active-title" class="section-title">
          <span class="section-title__icon">${ICONS.ticket}</span>
          Minhas Senhas Ativas
          <span class="section-title__count">${myItems.length} ${myItems.length === 1 ? 'senha' : 'senhas'}</span>
        </h3>
        <div class="grid grid-3">${cards}</div>
      </section>
    `;
  }

  /* ---------- History ---------- */
  function historyHtml() {
    if (isLoadingHistory) {
      return `
        <section aria-labelledby="history-title" style="margin-top:24px">
          <h3 id="history-title" class="section-title">
            <span class="section-title__icon">${ICONS.history}</span>
            Meu Histórico
          </h3>
          <div class="card">
            <div style="padding:16px;display:flex;flex-direction:column;gap:8px">
              <div class="skeleton" style="height:48px"></div>
              <div class="skeleton" style="height:48px"></div>
              <div class="skeleton" style="height:48px"></div>
            </div>
          </div>
        </section>
      `;
    }
    if (historyItems.length === 0) {
      return `
        <section aria-labelledby="history-title" style="margin-top:24px">
          <h3 id="history-title" class="section-title">
            <span class="section-title__icon">${ICONS.history}</span>
            Meu Histórico
          </h3>
          ${emptyState({
            icon: 'history',
            title: 'Sem atendimentos anteriores',
            message: 'Você ainda não possui atendimentos finalizados. Seu histórico aparecerá aqui após ser atendido.',
          })}
        </section>
      `;
    }
    const rows = historyItems.map(h => {
      const when = h.finishedAt || h.calledAt || h.enteredAt;
      return `
        <div class="history-grid">
          <div class="history-password">${escapeHtml(h.password)}</div>
          <div style="min-width:0">
            <div style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(h.queueName || '—')}</div>
            <div class="history-sub" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(h.sessionName || '')}</div>
          </div>
          <div>
            <div>${formatDate(when)}</div>
            <div class="history-sub">${relativeTime(when)}</div>
          </div>
          <div>${priorityBadge(h.priority)}</div>
          <div>${statusBadge(h.status)}</div>
        </div>
      `;
    }).join('');
    return `
      <section aria-labelledby="history-title" style="margin-top:24px">
        <h3 id="history-title" class="section-title">
          <span class="section-title__icon">${ICONS.history}</span>
          Meu Histórico
          <span class="section-title__count">${historyItems.length} ${historyItems.length === 1 ? 'registro' : 'registros'}</span>
        </h3>
        <div class="card" style="padding:0">
          <div class="history-grid history-grid--header">
            <div>Senha</div>
            <div>Fila</div>
            <div>Data</div>
            <div>Prioridade</div>
            <div>Status</div>
          </div>
          <div class="history-table-wrap custom-scroll">${rows}</div>
        </div>
      </section>
    `;
  }

  function renderPage() {
    const container = document.getElementById('page-content');
    if (!container) return;
    container.innerHTML = `
      ${heroHtml()}
      ${bannerHtml()}
      ${activeTicketsHtml()}
      ${historyHtml()}
    `;
  }

  /* ---------- Data fetching ---------- */
  async function loadQueue() {
    try {
      const data = await api('/api/my-queue');
      myItems = data.items || [];
    } catch (err) {
      toast(err.message || 'Erro ao carregar suas senhas.', 'error');
      myItems = [];
    } finally {
      isLoadingQueue = false;
      renderPage();
    }
  }

  async function loadHistory() {
    if (!patientId) { isLoadingHistory = false; renderPage(); return; }
    try {
      const data = await api(`/api/history?patientId=${encodeURIComponent(patientId)}`);
      historyItems = data.history || [];
    } catch (err) {
      historyItems = [];
    } finally {
      isLoadingHistory = false;
      renderPage();
    }
  }

  /* ---------- Init ---------- */
  renderShell();
  renderPage();
  loadQueue();
  loadHistory();
  // Auto-refresh das senhas ativas a cada 15s
  setInterval(loadQueue, 15000);
</script>
</body>
</html>
