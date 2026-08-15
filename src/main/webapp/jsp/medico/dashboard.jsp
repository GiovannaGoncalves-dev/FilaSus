<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Painel do Médico</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    @keyframes pulse-dot {
      0%, 100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.6); }
      50%      { box-shadow: 0 0 0 8px rgba(16, 185, 129, 0); }
    }
    .pulse-dot {
      width: 8px; height: 8px; border-radius: 50%;
      background: var(--emerald-500);
      animation: pulse-dot 1.5s infinite;
      display: inline-block;
    }
    .call-row {
      display: flex; align-items: center; gap: 12px;
      padding: 12px 16px; border-bottom: 1px solid var(--border);
      transition: background 0.15s;
    }
    .call-row:hover { background: var(--slate-50); }
    .call-row:last-child { border-bottom: none; }
    .pending-mini {
      padding: 14px; border: 1px solid var(--border);
      border-radius: var(--radius-lg); background: var(--surface);
      transition: border-color 0.15s, box-shadow 0.15s;
    }
    .pending-mini:hover { border-color: var(--amber-200); box-shadow: var(--shadow-sm); }
    .dash-grid {
      display: grid; grid-template-columns: 1.4fr 1fr; gap: 16px;
    }
    @media (max-width: 1024px) { .dash-grid { grid-template-columns: 1fr; } }
    .greeting-icon {
      width: 52px; height: 52px; border-radius: 50%;
      background: var(--teal-100); color: var(--teal-700);
      display: flex; align-items: center; justify-content: center;
      flex-shrink: 0;
    }
    .greeting-icon svg { width: 26px; height: 26px; }
  </style>
</head>
<body>
<div id="root"></div>
<script src="../../js/utils.js?v=5"></script>
<script src="../../js/auth.js?v=5"></script>
<script src="../../mock/data.js?v=5"></script>
<script src="../../js/components.js?v=5"></script>
<script>
  // ---------- Guard ----------
  if (!requireRole('medico')) throw new Error('Não autorizado');
  const user = getCurrentUser();

  // ---------- Estado ----------
  let activeSession = null;
  let attendance = null;
  let calledItems = [];
  let pendingItems = [];
  let pendingCount = 0;
  let stats = { attendedToday: 0, avgMinutes: 0, pending: 0, calledWaiting: 0 };
  let shellRendered = false;
  let firstLoad = true;

  // ---------- Helpers ----------
  function greeting() {
    const h = new Date().getHours();
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  function buildNavGroups() {
    return [{
      label: 'Médico',
      items: [
        { key: 'dashboard',  label: 'Painel',              icon: 'dashboard',   href: 'dashboard.jsp',         active: true },
        { key: 'atendimento',label: 'Atendimento',          icon: 'stethoscope', href: 'atendimento.jsp' },
        { key: 'prioridade', label: 'Validar Prioridade',   icon: 'shield',      href: 'validar-prioridade.jsp', badge: pendingCount || undefined },
      ],
    }];
  }

  function queueNameOf(queueId) {
    if (!activeSession) return '';
    const q = activeSession.queues.find(qq => qq.id === queueId);
    return q ? q.name : '';
  }

  function renderShellOnce() {
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups: buildNavGroups(),
      title: 'Painel do Médico',
      user,
      childrenHtml: '<div id="page-content"></div>',
    });
    // Garante que o elemento de badge exista para atualização dinâmica
    const link = document.querySelector('.sidebar__item[href="validar-prioridade.jsp"]');
    if (link && !link.querySelector('.sidebar__item-badge')) {
      const b = document.createElement('span');
      b.className = 'sidebar__item-badge';
      b.style.display = 'none';
      link.appendChild(b);
    }
    shellRendered = true;
  }

  function updateBadge() {
    const link = document.querySelector('.sidebar__item[href="validar-prioridade.jsp"]');
    const badge = link && link.querySelector('.sidebar__item-badge');
    if (!badge) return;
    if (pendingCount > 0) {
      badge.textContent = pendingCount;
      badge.style.display = '';
    } else {
      badge.style.display = 'none';
    }
  }

  function renderContent(html) {
    if (!shellRendered) renderShellOnce();
    const el = document.getElementById('page-content');
    if (el) el.innerHTML = html;
    updateBadge();
  }

  function renderLoading() {
    renderContent(`
      <div class="flex items-center justify-center" style="min-height:320px">
        <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
      </div>
    `);
  }

  // ---------- Render principal ----------
  function renderDashboard() {
    let html = '';

    // Cartão de saudação
    html += `
      <div class="card mb-6" style="background:linear-gradient(135deg,var(--teal-50),var(--emerald-50));border-color:var(--teal-200)">
        <div class="card__body">
          <div class="flex items-center justify-between" style="gap:16px;flex-wrap:wrap">
            <div style="min-width:0">
              <div class="text-sm text-muted" style="font-weight:500">${greeting()},</div>
              <h1 style="font-size:24px;font-weight:700;margin-top:2px;overflow:hidden;text-overflow:ellipsis">${escapeHtml(user.name)}</h1>
              <div class="flex items-center gap-2 mt-3" style="flex-wrap:wrap">
                <span class="badge badge--emerald">${escapeHtml(user.specialty || 'Médico')}</span>
                ${activeSession ? `
                  <span class="badge badge--teal">${escapeHtml(SESSION_STATUS_LABELS[activeSession.status] || activeSession.status)}</span>
                  <span class="text-sm text-muted" style="display:inline-flex;align-items:center;gap:4px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:100%">
                    ${ICONS.mapPin || ''} ${escapeHtml(activeSession.name)}${activeSession.location ? ' · ' + escapeHtml(activeSession.location) : ''}
                  </span>
                ` : `<span class="text-sm text-muted">Nenhum multirão ativo no momento</span>`}
              </div>
            </div>
            <div class="greeting-icon">${ICONS.stethoscope}</div>
          </div>
        </div>
      </div>
    `;

    // Cartão de atendimento em andamento
    if (attendance) {
      const startedAt = attendance.attendedAt || attendance.calledAt;
      const qName = queueNameOf(attendance.queueId);
      html += `
        <div class="card mb-6" style="border-color:var(--emerald-300);background:linear-gradient(135deg,#fff,var(--emerald-50))">
          <div class="card__body">
            <div class="flex items-center gap-2 mb-3">
              <span class="pulse-dot"></span>
              <span class="text-sm font-semibold" style="color:var(--emerald-700);text-transform:uppercase;letter-spacing:0.05em">Em atendimento agora</span>
            </div>
            <div class="flex items-center justify-between" style="gap:16px;flex-wrap:wrap">
              <div style="min-width:0">
                <div class="font-mono font-bold" style="font-size:36px;color:var(--emerald-700);line-height:1">${escapeHtml(attendance.password)}</div>
                <div class="text-md font-medium mt-2" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:100%">${escapeHtml(attendance.patientName || '—')}</div>
                <div class="text-sm text-muted mt-2">
                  ${attendance.patientAge ? attendance.patientAge + ' anos · ' : ''}${escapeHtml(qName || 'Fila')}
                  ${attendance.patientCpf ? ' · CPF ' + escapeHtml(attendance.patientCpf) : ''}
                </div>
                <div class="text-xs text-muted mt-3" style="display:flex;align-items:center;gap:4px">
                  ${ICONS.clock} Iniciado às ${formatTime(startedAt)} · ${relativeTime(startedAt)}
                </div>
              </div>
              <div class="flex gap-2" style="flex-wrap:wrap">
                <a href="atendimento.jsp" class="btn btn--primary btn--lg">${ICONS.stethoscope} Ver Atendimento</a>
                <button class="btn btn--outline btn--lg" onclick="finalizarAtendimento('${attendance.id}')">${ICONS.check} Finalizar</button>
              </div>
            </div>
          </div>
        </div>
      `;
    }

    // Linha de estatísticas
    html += `
      <div class="grid grid-4 mb-6">
        ${statCard({ label: 'Atendidos hoje',       value: stats.attendedToday,            hint: 'pacientes neste multirão',  icon: 'check',    accent: 'emerald' })}
        ${statCard({ label: 'Tempo médio',          value: formatMinutes(stats.avgMinutes), hint: 'por atendimento',           icon: 'clock',    accent: 'teal' })}
        ${statCard({ label: 'Validações pendentes',  value: stats.pending,                   hint: 'aguardando análise',        icon: 'shield',   accent: 'amber' })}
        ${statCard({ label: 'Chamados aguardando',   value: stats.calledWaiting,             hint: 'prontos para atendimento',  icon: 'activity', accent: 'violet' })}
      </div>
    `;

    // Grid: Fila de chamados + Validações pendentes
    html += `<div class="dash-grid">`;

    // Fila de chamados
    html += `
      <div>
        <div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
          <h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
            <span style="color:var(--violet-600)">${ICONS.activity}</span>
            Fila de chamados
          </h2>
          <span class="badge badge--violet">${calledItems.length} aguardando</span>
        </div>
        ${calledItems.length === 0 ? `
          <div class="card">
            <div class="empty-state">
              <div class="empty-state__icon" style="background:var(--violet-50);color:var(--violet-600)">${ICONS.check}</div>
              <div class="empty-state__title">Nenhum chamado aguardando</div>
              <div class="empty-state__message">
                ${attendance ? 'Você já está com um paciente em atendimento. Finalize-o para iniciar o próximo.'
                              : 'Todos os pacientes chamados já estão em atendimento ou foram atendidos.'}
              </div>
            </div>
          </div>
        ` : `
          <div class="card" style="padding:0">
            <div style="max-height:480px;overflow-y:auto" class="custom-scroll">
              ${calledItems.map(item => `
                <div class="call-row">
                  <div class="font-mono font-bold" style="font-size:16px;color:var(--violet-600);min-width:72px">${escapeHtml(item.password)}</div>
                  <div style="flex:1;min-width:0">
                    <div style="font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(item.patientName || '—')}</div>
                    <div class="text-xs text-muted" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                      ${escapeHtml(queueNameOf(item.queueId) || '—')} · ${item.patientAge != null ? item.patientAge + ' anos' : ''}
                      ${item.calledAt ? ' · chamado ' + relativeTime(item.calledAt) : ''}
                    </div>
                  </div>
                  ${item.priority === 'prioritario' ? `<span class="badge badge--amber">Prioritário</span>` : ''}
                  <button class="btn btn--primary btn--sm" onclick="iniciarAtendimento('${item.id}')" ${attendance ? 'disabled title="Finalize o atendimento atual primeiro"' : ''}>
                    ${ICONS.play} Iniciar Atendimento
                  </button>
                </div>
              `).join('')}
            </div>
          </div>
        `}
      </div>
    `;

    // Validações pendentes (preview top 3)
    html += `
      <div>
        <div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
          <h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
            <span style="color:var(--amber-600)">${ICONS.shield}</span>
            Validações pendentes
          </h2>
          <a href="validar-prioridade.jsp" class="btn btn--ghost btn--sm">
            Ver todas ${ICONS.arrowRight}
          </a>
        </div>
        ${pendingItems.length === 0 ? `
          <div class="card">
            <div class="empty-state">
              <div class="empty-state__icon" style="background:var(--emerald-50);color:var(--emerald-600)">${ICONS.check}</div>
              <div class="empty-state__title">Tudo em dia</div>
              <div class="empty-state__message">Nenhuma validação de prioridade pendente no momento.</div>
            </div>
          </div>
        ` : `
          <div class="flex flex-col gap-3">
            ${pendingItems.slice(0, 3).map(item => `
              <div class="pending-mini">
                <div class="flex items-center justify-between mb-2" style="gap:8px">
                  <div class="font-mono font-bold" style="color:var(--amber-700);font-size:15px">${escapeHtml(item.password)}</div>
                  <span class="badge badge--amber">${escapeHtml(PRIORITY_REASON_LABELS[item.priorityReason] || item.priorityReason || '—')}</span>
                </div>
                <div style="font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(item.patientName || '—')}</div>
                <div class="text-xs text-muted mt-2">
                  ${escapeHtml(item.queueName || '—')}${item.patientAge != null ? ' · ' + item.patientAge + ' anos' : ''}
                </div>
                <a href="validar-prioridade.jsp" class="btn btn--outline btn--sm btn--block mt-3">
                  ${ICONS.shield} Analisar solicitação
                </a>
              </div>
            `).join('')}
            ${pendingItems.length > 3 ? `
              <a href="validar-prioridade.jsp" class="btn btn--ghost btn--sm btn--block">
                + ${pendingItems.length - 3} solicitação(ões) restante(s)
              </a>
            ` : ''}
          </div>
        `}
      </div>
    `;

    html += `</div>`;
    return html;
  }

  // ---------- Ações ----------
  async function iniciarAtendimento(itemId) {
    if (attendance) {
      toast('Finalize o atendimento atual antes de iniciar outro.', 'warning');
      return;
    }
    try {
      const res = await api('/api/attendance', { method: 'POST', body: { itemId } });
      toast(`Atendimento de ${res.item.patientName} iniciado.`, 'success', 'Paciente em atendimento');
      redirectTo('atendimento.jsp');
    } catch (err) {
      toast(err.message || 'Erro ao iniciar atendimento', 'error');
    }
  }

  async function finalizarAtendimento(attId) {
    const ok = await confirmDialog({
      title: 'Finalizar atendimento',
      message: 'Deseja realmente finalizar este atendimento? O paciente será marcado como atendido e a senha será encerrada.',
      confirmText: 'Finalizar Atendimento',
      cancelText: 'Cancelar',
      danger: false,
    });
    if (!ok) return;
    try {
      await api('/api/attendance/' + attId, { method: 'PATCH' });
      toast('Atendimento finalizado com sucesso.', 'success', 'Paciente atendido');
      refresh();
    } catch (err) {
      toast(err.message || 'Erro ao finalizar atendimento', 'error');
    }
  }

  // ---------- Refresh ----------
  async function refresh() {
    // Não interrompe dialogs em aberto
    if (document.getElementById('dialog-overlay')) return;
    try {
      const [sessRes, attRes, pendRes] = await Promise.all([
        api('/api/sessions/active'),
        api('/api/attendance?medicId=' + encodeURIComponent(user.id)),
        api('/api/priority?status=pendente'),
      ]);
      activeSession = sessRes.session;
      attendance = attRes.attendance;
      const attendanceMetrics = attRes.metrics || {};
      pendingItems = pendRes.items || [];
      pendingCount = pendingItems.length;

      if (activeSession) {
        const [calledRes, queueRes] = await Promise.all([
          api('/api/queue?sessionId=' + encodeURIComponent(activeSession.id) + '&status=chamado'),
          api('/api/queue?sessionId=' + encodeURIComponent(activeSession.id)),
        ]);
        calledItems = calledRes.items || [];

        stats = {
          attendedToday: attendanceMetrics.attendedToday || 0,
          avgMinutes: attendanceMetrics.avgMinutes || 0,
          pending: pendingCount,
          calledWaiting: calledItems.length,
        };
      } else {
        calledItems = [];
        stats = {
          attendedToday: attendanceMetrics.attendedToday || 0,
          avgMinutes: attendanceMetrics.avgMinutes || 0,
          pending: pendingCount,
          calledWaiting: 0
        };
      }

      renderContent(renderDashboard());
      firstLoad = false;
    } catch (err) {
      console.error(err);
      if (firstLoad) {
        renderContent(`
          <div class="card">
            <div class="empty-state">
              <div class="empty-state__icon" style="background:var(--rose-50);color:var(--rose-600)">${ICONS.alert}</div>
              <div class="empty-state__title">Não foi possível carregar o painel</div>
              <div class="empty-state__message">${escapeHtml(err.message || 'Erro desconhecido')}</div>
              <button class="btn btn--primary mt-4" onclick="refresh()">${ICONS.refresh} Tentar novamente</button>
            </div>
          </div>
        `);
      } else {
        toast(err.message || 'Erro ao atualizar painel', 'error');
      }
    }
  }

  // ---------- Boot ----------
  renderShellOnce();
  renderLoading();
  refresh();
  setInterval(refresh, 5000);
</script>
</body>
</html>
