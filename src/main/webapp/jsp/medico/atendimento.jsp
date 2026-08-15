<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Atendimento</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    @keyframes pulse-ring {
      0%, 100% { box-shadow: 0 0 0 0 rgba(13, 148, 136, 0.5); }
      50%      { box-shadow: 0 0 0 10px rgba(13, 148, 136, 0); }
    }
    .pulse-ring { animation: pulse-ring 1.6s infinite; }

    .att-grid {
      display: grid; grid-template-columns: 1.4fr 1fr; gap: 16px; align-items: start;
    }
    @media (max-width: 1024px) { .att-grid { grid-template-columns: 1fr; } }

    .info-row { display: flex; gap: 10px; align-items: flex-start; padding: 6px 0; }
    .info-row__icon { color: var(--text-muted); flex-shrink: 0; margin-top: 2px; }
    .info-row__label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); font-weight: 600; }
    .info-row__value { font-size: 14px; font-weight: 500; }

    .doc-item {
      display: flex; align-items: center; gap: 12px;
      padding: 10px 12px; border: 1px solid var(--border);
      border-radius: var(--radius); margin-bottom: 8px;
      transition: background 0.15s, border-color 0.15s;
    }
    .doc-item:hover { background: var(--slate-50); border-color: var(--border-strong); }
    .doc-item__icon {
      width: 36px; height: 36px; border-radius: 8px;
      background: var(--teal-50); color: var(--teal-700);
      display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    }
    .doc-item__info { flex: 1; min-width: 0; }
    .doc-item__name {
      font-size: 14px; font-weight: 500;
      overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .doc-item__desc {
      font-size: 12px; color: var(--text-muted); margin-top: 2px;
      overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .doc-item__date { font-size: 11px; color: var(--text-muted); flex-shrink: 0; }

    /* Timeline */
    .timeline { position: relative; padding-left: 4px; }
    .tl-step {
      display: flex; gap: 14px; position: relative;
      padding-bottom: 22px;
    }
    .tl-step:last-child { padding-bottom: 0; }
    .tl-step::before {
      content: ''; position: absolute;
      left: 9px; top: 22px; bottom: -4px;
      width: 2px; background: var(--border);
    }
    .tl-step:last-child::before { display: none; }
    .tl-step__node {
      width: 20px; height: 20px; border-radius: 50%;
      flex-shrink: 0; background: var(--slate-200);
      border: 3px solid var(--surface);
      box-shadow: 0 0 0 1px var(--border);
      margin-top: 2px; z-index: 1;
      display: flex; align-items: center; justify-content: center;
    }
    .tl-step--done .tl-step__node { background: var(--emerald-500); }
    .tl-step--done .tl-step__node::after {
      content: ''; width: 8px; height: 5px;
      border-left: 2px solid #fff; border-bottom: 2px solid #fff;
      transform: rotate(-45deg) translate(1px, -1px);
    }
    .tl-step--current .tl-step__node {
      background: var(--teal-500);
      box-shadow: 0 0 0 1px var(--teal-200), 0 0 0 5px var(--teal-100);
      animation: pulse-ring 1.6s infinite;
    }
    .tl-step--pending .tl-step__node { background: var(--surface); }
    .tl-step--current .tl-step__title { color: var(--teal-700); font-weight: 600; }
    .tl-step__title { font-size: 14px; font-weight: 500; }
    .tl-step__time { font-size: 12px; color: var(--text-muted); margin-top: 2px; }
    .tl-step__badge {
      display: inline-block; margin-left: 6px;
      font-size: 10px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.05em; color: var(--teal-700);
    }

    .call-row {
      display: flex; align-items: center; gap: 12px;
      padding: 12px 16px; border-bottom: 1px solid var(--border);
      transition: background 0.15s;
    }
    .call-row:hover { background: var(--slate-50); }
    .call-row:last-child { border-bottom: none; }
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
  let patient = null;     // prontuário completo (com documentos)
  let calledItems = [];
  let pendingCount = 0;
  let shellRendered = false;
  let firstLoad = true;

  // ---------- Helpers ----------
  function buildNavGroups() {
    return [{
      label: 'Médico',
      items: [
        { key: 'dashboard',   label: 'Painel',            icon: 'dashboard',   href: 'dashboard.jsp' },
        { key: 'atendimento', label: 'Atendimento',        icon: 'stethoscope', href: 'atendimento.jsp',       active: true },
        { key: 'prioridade',  label: 'Validar Prioridade', icon: 'shield',      href: 'validar-prioridade.jsp', badge: pendingCount || undefined },
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
      title: 'Atendimento',
      user,
      childrenHtml: '<div id="page-content"></div>',
    });
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

  // ---------- Render: com atendimento em andamento ----------
  function renderAttendance() {
    const qName = queueNameOf(attendance.queueId);
    const docs = (patient && patient.documents) || [];
    const startedAt = attendance.attendedAt || attendance.calledAt;

    return `
      ${pageHeader({
        title: 'Atendimento em andamento',
        subtitle: `${escapeHtml(qName || 'Fila')} · Multirão ${escapeHtml(activeSession ? activeSession.name : '')}`,
        actions: `
          <a href="dashboard.jsp" class="btn btn--outline btn--sm">${ICONS.arrowLeft} Voltar</a>
          <button class="btn btn--success btn--sm" onclick="finalizarAtendimento('${attendance.id}')">${ICONS.check} Finalizar Atendimento</button>
        `,
      })}

      <div class="att-grid">
        <!-- Coluna principal: paciente + documentos + timeline -->
        <div class="flex flex-col gap-4">

          <!-- Cartão do paciente -->
          <div class="card">
            <div class="card__header">
              <div class="flex items-center gap-2">
                <span class="pulse-ring" style="width:10px;height:10px;border-radius:50%;background:var(--teal-500);display:inline-block"></span>
                <div class="card__title">Paciente em atendimento</div>
              </div>
              <div class="font-mono font-bold" style="font-size:22px;color:var(--teal-700)">${escapeHtml(attendance.password)}</div>
            </div>
            <div class="card__body">
              <h3 style="font-size:20px;font-weight:700;margin-bottom:12px">${escapeHtml(attendance.patientName || patient?.name || '—')}</h3>
              <div class="grid grid-2" style="gap:12px">
                <div class="info-row">
                  <div class="info-row__icon">${ICONS.user}</div>
                  <div>
                    <div class="info-row__label">Idade</div>
                    <div class="info-row__value">${attendance.patientAge != null ? attendance.patientAge + ' anos' : '—'}</div>
                  </div>
                </div>
                <div class="info-row">
                  <div class="info-row__icon">${ICONS.idCard}</div>
                  <div>
                    <div class="info-row__label">CPF</div>
                    <div class="info-row__value font-mono">${escapeHtml(attendance.patientCpf || patient?.cpf || '—')}</div>
                  </div>
                </div>
                ${patient?.cns ? `
                  <div class="info-row">
                    <div class="info-row__icon">${ICONS.idCard}</div>
                    <div>
                      <div class="info-row__label">CNS</div>
                      <div class="info-row__value font-mono">${escapeHtml(patient.cns)}</div>
                    </div>
                  </div>
                ` : ''}
                ${patient?.phone ? `
                  <div class="info-row">
                    <div class="info-row__icon">${ICONS.phone}</div>
                    <div>
                      <div class="info-row__label">Telefone</div>
                      <div class="info-row__value font-mono">${escapeHtml(patient.phone)}</div>
                    </div>
                  </div>
                ` : ''}
              </div>

              <div class="flex items-center gap-2 mt-4" style="flex-wrap:wrap;padding-top:12px;border-top:1px solid var(--border)">
                ${priorityBadge(attendance.priority)}
                ${attendance.priorityReason ? `
                  <span class="text-sm text-muted">
                    Motivo: <strong style="color:var(--amber-700)">${escapeHtml(PRIORITY_REASON_LABELS[attendance.priorityReason] || attendance.priorityReason)}</strong>
                  </span>
                ` : `<span class="text-sm text-muted">Atendimento comum</span>`}
                <span style="margin-left:auto">${statusBadge(attendance.status)}</span>
              </div>
            </div>
          </div>

          <!-- Documentos -->
          <div class="card">
            <div class="card__header">
              <div class="card__title">${ICONS.fileText} Documentos do paciente</div>
              <span class="badge badge--slate">${docs.length} arquivo(s)</span>
            </div>
            <div class="card__body">
              ${docs.length === 0 ? `
                <div class="empty-state" style="padding:24px">
                  <div class="empty-state__icon" style="width:40px;height:40px">${ICONS.fileText}</div>
                  <div class="empty-state__title" style="font-size:14px">Nenhum documento enviado</div>
                  <div class="empty-state__message" style="font-size:12px">O paciente não anexou documentos para esta solicitação.</div>
                </div>
              ` : `
                <div style="max-height:280px;overflow-y:auto" class="custom-scroll">
                  ${docs.map(d => `
                    <div class="doc-item">
                      <div class="doc-item__icon">${ICONS.fileText}</div>
                      <div class="doc-item__info">
                        <div class="doc-item__name">${escapeHtml(d.fileName || 'documento')}</div>
                        ${d.description ? `<div class="doc-item__desc">${escapeHtml(d.description)}</div>` : ''}
                      </div>
                      <div class="doc-item__date">${formatDate(d.uploadedAt)}</div>
                    </div>
                  `).join('')}
                </div>
              `}
            </div>
          </div>

          <!-- Timeline -->
          <div class="card">
            <div class="card__header">
              <div class="card__title">${ICONS.history} Linha do tempo</div>
            </div>
            <div class="card__body">
              <div class="timeline">
                <div class="tl-step tl-step--done">
                  <div class="tl-step__node"></div>
                  <div>
                    <div class="tl-step__title">Entrada na fila</div>
                    <div class="tl-step__time">${formatDateTime(attendance.enteredAt)} · ${relativeTime(attendance.enteredAt)}</div>
                  </div>
                </div>
                <div class="tl-step tl-step--done">
                  <div class="tl-step__node"></div>
                  <div>
                    <div class="tl-step__title">Chamado pelo atendente</div>
                    <div class="tl-step__time">${attendance.calledAt ? formatDateTime(attendance.calledAt) + ' · ' + relativeTime(attendance.calledAt) : '—'}</div>
                  </div>
                </div>
                <div class="tl-step tl-step--current">
                  <div class="tl-step__node"></div>
                  <div>
                    <div class="tl-step__title">
                      Em atendimento
                      <span class="tl-step__badge">agora</span>
                    </div>
                    <div class="tl-step__time">
                      ${startedAt ? 'Iniciado em ' + formatDateTime(startedAt) + ' · ' + relativeTime(startedAt) : '—'}
                    </div>
                  </div>
                </div>
                <div class="tl-step tl-step--pending">
                  <div class="tl-step__node"></div>
                  <div>
                    <div class="tl-step__title" style="color:var(--text-muted)">Finalizado</div>
                    <div class="tl-step__time">Aguardando encerramento do atendimento</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Coluna lateral: ações -->
        <div class="flex flex-col gap-4">
          <div class="card" style="border-color:var(--emerald-200);background:linear-gradient(135deg,#fff,var(--emerald-50))">
            <div class="card__body">
              <div class="text-sm text-muted" style="font-weight:600;text-transform:uppercase;letter-spacing:0.05em">Tempo de atendimento</div>
              <div class="font-mono font-bold" style="font-size:32px;color:var(--emerald-700);margin-top:4px" id="elapsed-time">
                ${startedAt ? formatElapsed(startedAt) : '—'}
              </div>
              <div class="text-xs text-muted mt-2">Iniciado às ${startedAt ? formatTime(startedAt) : '—'}</div>

              <button class="btn btn--success btn--block btn--lg mt-4" onclick="finalizarAtendimento('${attendance.id}')">
                ${ICONS.check} Finalizar Atendimento
              </button>
              <p class="text-xs text-muted text-center mt-3">
                O paciente será marcado como atendido e a senha será encerrada.
              </p>
            </div>
          </div>

          ${attendance.priority === 'prioritario' ? `
            <div class="card">
              <div class="card__header">
                <div class="card__title">${ICONS.shield} Prioridade</div>
              </div>
              <div class="card__body">
                <div class="flex items-center gap-2 mb-2">
                  ${priorityBadge(attendance.priority)}
                </div>
                <div class="text-sm">
                  <strong style="color:var(--amber-700)">${escapeHtml(PRIORITY_REASON_LABELS[attendance.priorityReason] || attendance.priorityReason || '—')}</strong>
                </div>
                <div class="text-xs text-muted mt-2">
                  Validação: ${attendance.priorityValidation === 'aprovada' ? 'Aprovada' : escapeHtml(attendance.priorityValidation || '—')}
                </div>
              </div>
            </div>
          ` : ''}
        </div>
      </div>
    `;
  }

  function formatElapsed(startIso) {
    const ms = Date.now() - new Date(startIso).getTime();
    const totalSec = Math.max(0, Math.floor(ms / 1000));
    const h = Math.floor(totalSec / 3600);
    const m = Math.floor((totalSec % 3600) / 60);
    const s = totalSec % 60;
    const pad = n => String(n).padStart(2, '0');
    return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
  }

  // ---------- Render: sem atendimento (lista de chamados) ----------
  function renderNoAttendance() {
    return `
      ${pageHeader({
        title: 'Atendimento',
        subtitle: 'Pacientes chamados pelo atendente, aguardando início do atendimento médico',
        actions: `<a href="dashboard.jsp" class="btn btn--outline btn--sm">${ICONS.arrowLeft} Voltar ao painel</a>`,
      })}

      <div class="card mb-6" style="background:linear-gradient(135deg,var(--amber-50),#fff);border-color:var(--amber-200)">
        <div class="card__body flex items-center gap-3">
          <div style="width:44px;height:44px;border-radius:50%;background:var(--amber-100);color:var(--amber-700);display:flex;align-items:center;justify-content:center;flex-shrink:0">${ICONS.info}</div>
          <div>
            <div style="font-weight:600;color:var(--amber-800)">Você não está com nenhum paciente em atendimento</div>
            <div class="text-sm text-muted mt-2">Selecione um paciente abaixo para iniciar o atendimento. A senha será movida para "Em Atendimento".</div>
          </div>
        </div>
      </div>

      <div class="flex items-center justify-between mb-3" style="gap:8px;flex-wrap:wrap">
        <h2 style="font-size:16px;font-weight:600;display:flex;align-items:center;gap:6px">
          <span style="color:var(--violet-600)">${ICONS.activity}</span>
          Pacientes chamados aguardando atendimento
        </h2>
        <span class="badge badge--violet">${calledItems.length} aguardando</span>
      </div>

      ${calledItems.length === 0 ? `
        ${emptyState({
          icon: 'check',
          title: 'Nenhum paciente aguardando',
          message: 'No momento não há pacientes chamados pelo atendente. Aguarde a próxima chamada — esta página será atualizada automaticamente.',
          action: `<a href="dashboard.jsp" class="btn btn--outline mt-4">${ICONS.dashboard} Ir para o painel</a>`,
        })}
      ` : `
        <div class="card" style="padding:0;max-height:480px;overflow-y:auto">
          ${calledItems.map(item => `
            <div class="call-row">
              <div class="font-mono font-bold" style="font-size:18px;color:var(--violet-600);min-width:80px">${escapeHtml(item.password)}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:15px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(item.patientName || '—')}</div>
                <div class="text-xs text-muted" style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                  ${escapeHtml(queueNameOf(item.queueId) || '—')}
                  ${item.patientAge != null ? ' · ' + item.patientAge + ' anos' : ''}
                  ${item.patientCpf ? ' · CPF ' + escapeHtml(item.patientCpf) : ''}
                  ${item.calledAt ? ' · chamado ' + relativeTime(item.calledAt) : ''}
                </div>
              </div>
              ${item.priority === 'prioritario' ? `<span class="badge badge--amber">Prioritário</span>` : ''}
              <button class="btn btn--primary" onclick="iniciarAtendimento('${item.id}')">
                ${ICONS.play} Iniciar Atendimento
              </button>
            </div>
          `).join('')}
        </div>
      `}
    `;
  }

  // ---------- Ações ----------
  async function iniciarAtendimento(itemId) {
    try {
      const res = await api('/api/attendance', { method: 'POST', body: { itemId } });
      toast(`Atendimento de ${res.item.patientName} iniciado.`, 'success', 'Paciente em atendimento');
      refresh();
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
      redirectTo('dashboard.jsp');
    } catch (err) {
      toast(err.message || 'Erro ao finalizar atendimento', 'error');
    }
  }

  // ---------- Refresh ----------
  async function refresh() {
    if (document.getElementById('dialog-overlay')) return;
    try {
      const [sessRes, attRes, pendRes] = await Promise.all([
        api('/api/sessions/active'),
        api('/api/attendance?medicId=' + encodeURIComponent(user.id)),
        api('/api/priority?status=pendente'),
      ]);
      activeSession = sessRes.session;
      attendance = attRes.attendance;
      pendingCount = (pendRes.items || []).length;

      // Busca documentos do paciente se houver atendimento
      if (attendance && attendance.patientId) {
        try {
          const pRes = await api('/api/patients/' + encodeURIComponent(attendance.patientId));
          patient = pRes.patient;
        } catch { patient = null; }
      } else {
        patient = null;
      }

      // Lista de chamados (sempre, mesmo com atendimento, para mostrar no topo caso venha a finalizar)
      if (activeSession) {
        const calledRes = await api('/api/queue?sessionId=' + encodeURIComponent(activeSession.id) + '&status=chamado');
        calledItems = calledRes.items || [];
      } else {
        calledItems = [];
      }

      if (attendance) {
        renderContent(renderAttendance());
      } else {
        renderContent(renderNoAttendance());
      }
      firstLoad = false;
    } catch (err) {
      console.error(err);
      if (firstLoad) {
        renderContent(`
          <div class="card">
            <div class="empty-state">
              <div class="empty-state__icon" style="background:var(--rose-50);color:var(--rose-600)">${ICONS.alert}</div>
              <div class="empty-state__title">Não foi possível carregar o atendimento</div>
              <div class="empty-state__message">${escapeHtml(err.message || 'Erro desconhecido')}</div>
              <button class="btn btn--primary mt-4" onclick="refresh()">${ICONS.refresh} Tentar novamente</button>
            </div>
          </div>
        `);
      } else {
        toast(err.message || 'Erro ao atualizar atendimento', 'error');
      }
    }
  }

  // ---------- Tick: atualiza cronômetro a cada segundo ----------
  function tickElapsed() {
    if (!attendance) return;
    const startedAt = attendance.attendedAt || attendance.calledAt;
    const el = document.getElementById('elapsed-time');
    if (el && startedAt) el.textContent = formatElapsed(startedAt);
  }

  // ---------- Boot ----------
  renderShellOnce();
  renderLoading();
  refresh();
  setInterval(refresh, 5000);
  setInterval(tickElapsed, 1000);
</script>
</body>
</html>
