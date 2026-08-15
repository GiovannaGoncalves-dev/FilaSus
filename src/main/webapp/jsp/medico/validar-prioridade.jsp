<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Validar Prioridade</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .pri-grid {
      display: flex;
      gap: 16px;
      align-items: stretch;
      padding-bottom: 4px;
      scroll-snap-type: x proximity;
    }
    #pri-cards-scroller { margin-bottom: 0; border-bottom: none; }

    .pri-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-left: 4px solid var(--amber-400);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-sm);
      overflow: hidden;
      display: flex; flex-direction: column;
      flex: 0 0 400px;
      width: 400px;
      scroll-snap-align: start;
    }
    .pri-card__body { flex: 1; display: flex; flex-direction: column; }
    .pri-card__docs { flex: 1; }
    @media (max-width: 480px) { .pri-card { flex-basis: 88vw; width: 88vw; } }
    .pri-card__header {
      padding: 14px 16px;
      border-bottom: 1px solid var(--border);
      background: linear-gradient(135deg, var(--amber-50), #fff);
      display: flex; align-items: center; justify-content: space-between;
      gap: 8px;
    }
    .pri-card__password {
      font-family: var(--font-mono);
      font-weight: 800;
      font-size: 22px;
      color: var(--amber-700);
      line-height: 1;
    }
    .pri-card__body { padding: 14px 16px; }
    .pri-card__footer {
      padding: 12px 16px;
      border-top: 1px solid var(--border);
      background: var(--surface-2);
      display: flex; gap: 8px;
    }
    .pri-card__footer .btn { flex: 1; }

    .info-row { display: flex; gap: 8px; align-items: center; padding: 3px 0; font-size: 13px; }
    .info-row__icon { color: var(--text-muted); flex-shrink: 0; display: flex; }
    .info-row__label { color: var(--text-muted); }

    .doc-item {
      display: flex; align-items: center; gap: 10px;
      padding: 8px 10px; border: 1px solid var(--border);
      border-radius: var(--radius); background: var(--surface);
      margin-bottom: 6px;
      transition: background 0.15s, border-color 0.15s;
    }
    .doc-item:hover { background: var(--slate-50); border-color: var(--border-strong); }
    .doc-item__icon {
      width: 32px; height: 32px; border-radius: 8px;
      background: var(--teal-50); color: var(--teal-700);
      display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    }
    .doc-item__info { flex: 1; min-width: 0; }
    .doc-item__name {
      font-size: 13px; font-weight: 500;
      overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .doc-item__desc {
      font-size: 11px; color: var(--text-muted); margin-top: 1px;
      overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .doc-item__date { font-size: 10px; color: var(--text-muted); flex-shrink: 0; }

    .reason-box {
      background: var(--amber-50);
      border: 1px solid var(--amber-200);
      border-radius: var(--radius);
      padding: 10px 12px;
      margin-top: 8px;
      display: flex; gap: 8px; align-items: flex-start;
    }
    .reason-box__icon { color: var(--amber-600); flex-shrink: 0; margin-top: 1px; }
    .reason-box__label {
      font-size: 10px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.05em; color: var(--amber-700);
    }
    .reason-box__value { font-size: 14px; font-weight: 600; color: var(--amber-800); }
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
  let pendingItems = [];
  let pendingCount = 0;
  let shellRendered = false;
  let firstLoad = true;

  // ---------- Helpers ----------
  function buildNavGroups() {
    return [{
      label: 'Médico',
      items: [
        { key: 'dashboard',   label: 'Painel',            icon: 'dashboard',   href: 'dashboard.jsp' },
        { key: 'atendimento', label: 'Atendimento',        icon: 'stethoscope', href: 'atendimento.jsp' },
        { key: 'prioridade',  label: 'Validar Prioridade', icon: 'shield',      href: 'validar-prioridade.jsp', active: true, badge: pendingCount || undefined },
      ],
    }];
  }

  function renderShellOnce() {
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups: buildNavGroups(),
      title: 'Validar Prioridade',
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
        <div class="spinner spinner--lg" style="color:var(--amber-600)"></div>
      </div>
    `);
  }

  function renderCard(item) {
    const docs = item.documents || [];
    return `
      <div class="pri-card">
        <div class="pri-card__header">
          <div>
            <div class="text-xs text-muted" style="font-weight:600;text-transform:uppercase;letter-spacing:0.05em">Senha</div>
            <div class="pri-card__password">${escapeHtml(item.password)}</div>
          </div>
          <div style="text-align:right">
            <span class="badge badge--amber">${escapeHtml(PRIORITY_REASON_LABELS[item.priorityReason] || item.priorityReason || '—')}</span>
            <div class="text-xs text-muted mt-2">${escapeHtml(item.queueName || '—')}</div>
          </div>
        </div>

        <div class="pri-card__body">
          <h3 style="font-size:16px;font-weight:700;margin-bottom:8px">${escapeHtml(item.patientName || '—')}</h3>

          <div class="info-row">
            <span class="info-row__icon">${ICONS.user}</span>
            <span class="info-row__label">Idade:</span>
            <strong>${item.patientAge != null ? item.patientAge + ' anos' : '—'}</strong>
          </div>
          <div class="info-row">
            <span class="info-row__icon">${ICONS.idCard}</span>
            <span class="info-row__label">CPF:</span>
            <strong class="font-mono">${escapeHtml(item.patientCpf || '—')}</strong>
          </div>
          ${item.sessionName ? `
            <div class="info-row">
              <span class="info-row__icon">${ICONS.mapPin}</span>
              <span class="info-row__label">Multirão:</span>
              <span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(item.sessionName)}</span>
            </div>
          ` : ''}
          <div class="info-row">
            <span class="info-row__icon">${ICONS.clock}</span>
            <span class="info-row__label">Solicitado:</span>
            <span>${relativeTime(item.enteredAt)}</span>
          </div>

          <div class="reason-box">
            <span class="reason-box__icon">${ICONS.shield}</span>
            <div>
              <div class="reason-box__label">Motivo alegado</div>
              <div class="reason-box__value">${escapeHtml(PRIORITY_REASON_LABELS[item.priorityReason] || item.priorityReason || 'Não informado')}</div>
            </div>
          </div>

          <div class="mt-4 pri-card__docs">
            <div class="flex items-center justify-between mb-2" style="gap:8px">
              <div class="text-xs text-muted" style="font-weight:600;text-transform:uppercase;letter-spacing:0.05em;display:flex;align-items:center;gap:6px">
                ${ICONS.fileText} Documentos comprobatórios
              </div>
              <span class="badge badge--slate">${docs.length}</span>
            </div>
            ${docs.length === 0 ? `
              <div style="min-height:48px;display:flex;align-items:center;justify-content:center;text-align:center;border:1px dashed var(--border);border-radius:var(--radius);color:var(--text-muted);font-size:12px">
                Nenhum documento anexado pelo paciente.
              </div>
            ` : `
              <div style="max-height:200px;overflow-y:auto" class="custom-scroll">
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

        <div class="pri-card__footer">
          <button class="btn btn--success" onclick="aprovarPrioridade('${item.id}', this)">
            ${ICONS.check} Aprovar
          </button>
          <button class="btn btn--danger" onclick="abrirDialogRejeitar('${item.id}', this)">
            ${ICONS.x} Rejeitar
          </button>
        </div>
      </div>
    `;
  }

  function renderList() {
    return `
      ${pageHeader({
        title: 'Validar Prioridade',
        subtitle: 'Solicitações de prioridade enviadas pelos pacientes, aguardando análise do médico',
        actions: `<a href="dashboard.jsp" class="btn btn--outline btn--sm">${ICONS.arrowLeft} Voltar ao painel</a>`,
      })}

      <div class="card mb-6" style="background:linear-gradient(135deg,var(--amber-50),#fff);border-color:var(--amber-200)">
        <div class="card__body flex items-center gap-3" style="flex-wrap:wrap">
          <div style="width:44px;height:44px;border-radius:50%;background:var(--amber-100);color:var(--amber-700);display:flex;align-items:center;justify-content:center;flex-shrink:0">${ICONS.shield}</div>
          <div style="flex:1;min-width:160px">
            <div style="font-weight:600;color:var(--amber-800)">
              ${pendingCount === 0 ? 'Nenhuma solicitação pendente' :
                pendingCount === 1 ? '1 solicitação aguardando análise' :
                `${pendingCount} solicitações aguardando análise`}
            </div>
            <div class="text-sm text-muted mt-2">
              Analise os documentos e o motivo alegado. Ao aprovar, o paciente passa a ter prioridade no atendimento. Ao rejeitar, ele permanece na fila como prioridade comum.
            </div>
          </div>
          <span class="badge badge--amber" style="font-size:14px;padding:6px 14px">${pendingCount} pendente(s)</span>
        </div>
      </div>

      ${pendingItems.length === 0 ? `
        ${emptyState({
          icon: 'check',
          title: 'Tudo em dia!',
          message: 'Não há solicitações de prioridade pendentes no momento. Quando um paciente solicitar prioridade, ela aparecerá aqui automaticamente.',
          action: `<a href="dashboard.jsp" class="btn btn--outline mt-4">${ICONS.dashboard} Voltar ao painel</a>`,
        })}
      ` : `
        ${tabsScroller(
          `<div class="pri-grid">${pendingItems.map(renderCard).join('')}</div>`,
          'pri-cards-scroller',
          420
        )}
      `}
    `;
  }

  // ---------- Ações ----------
  function findItem(itemId) {
    return pendingItems.find(i => i.id === itemId);
  }

  async function aprovarPrioridade(itemId, btn) {
    const item = findItem(itemId);
    const patientName = item ? (item.patientName || 'paciente') : 'paciente';
    const ok = await confirmDialog({
      title: 'Aprovar prioridade',
      message: `Deseja aprovar a solicitação de prioridade de ${patientName}? O paciente passará a ter atendimento prioritário na fila.`,
      confirmText: 'Aprovar',
      cancelText: 'Cancelar',
      danger: false,
    });
    if (!ok) return;
    const original = btn ? btn.innerHTML : '';
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Aprovando...'; }
    try {
      await api('/api/priority/' + itemId, { method: 'PATCH', body: { action: 'approve' } });
      toast(`Prioridade aprovada para ${patientName}.`, 'success', 'Solicitação aprovada');
      refresh();
    } catch (err) {
      toast(err.message || 'Erro ao aprovar solicitação', 'error');
      if (btn) { btn.disabled = false; btn.innerHTML = original; }
    }
  }

  function abrirDialogRejeitar(itemId, btn) {
    const item = findItem(itemId);
    const patientName = item ? (item.patientName || 'paciente') : 'paciente';
    showDialog({
      title: 'Rejeitar solicitação de prioridade',
      body: `
        <div class="alert alert--warning mb-4">
          <span style="color:var(--amber-600)">${ICONS.info}</span>
          <div>
            <div class="alert__title">Rejeitar prioridade de ${escapeHtml(patientName)}</div>
            <div class="alert__message">O paciente permanecerá na fila como prioridade <strong>comum</strong>. Informe o motivo da rejeição.</div>
          </div>
        </div>
        <div class="field">
          <label class="field__label field__label--required" for="reject-reason">Motivo da rejeição</label>
          <textarea
            class="textarea"
            id="reject-reason"
            placeholder="Ex: Documentação insuficiente para comprovar a condição prioritária alegada..."
            rows="4"
            minlength="5"
          ></textarea>
          <div class="field__hint">Mínimo de 5 caracteres. Este motivo poderá ser consultado pelo atendente.</div>
        </div>
      `,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog()">Cancelar</button>
        <button class="btn btn--danger" onclick="confirmarRejeicao('${itemId}', this)">
          ${ICONS.x} Confirmar Rejeição
        </button>
      `,
    });
    // Foco no textarea
    setTimeout(() => {
      const ta = document.getElementById('reject-reason');
      if (ta) ta.focus();
    }, 50);
  }

  async function confirmarRejeicao(itemId, btn) {
    const item = findItem(itemId);
    const patientName = item ? (item.patientName || 'paciente') : 'paciente';
    const ta = document.getElementById('reject-reason');
    const reason = ta ? ta.value.trim() : '';
    if (reason.length < 5) {
      toast('Informe um motivo com pelo menos 5 caracteres.', 'warning', 'Motivo obrigatório');
      if (ta) { ta.focus(); ta.classList.add('input--error'); }
      return;
    }
    const original = btn ? btn.innerHTML : '';
    if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner"></span> Rejeitando...'; }
    try {
      await api('/api/priority/' + itemId, {
        method: 'PATCH',
        body: { action: 'reject', rejectionReason: reason },
      });
      closeDialog();
      toast(`Prioridade rejeitada para ${patientName}. Paciente permanece na fila com prioridade comum.`, 'success', 'Solicitação rejeitada');
      refresh();
    } catch (err) {
      toast(err.message || 'Erro ao rejeitar solicitação', 'error');
      if (btn) { btn.disabled = false; btn.innerHTML = original; }
    }
  }

  // ---------- Refresh ----------
  async function refresh() {
    if (document.getElementById('dialog-overlay')) return;
    try {
      const sessRes = await api('/api/sessions/active');
      activeSession = sessRes.session;
      const qs = 'status=pendente' + (activeSession ? '&sessionId=' + encodeURIComponent(activeSession.id) : '');
      const pendRes = await api('/api/priority?' + qs);
      pendingItems = pendRes.items || [];
      pendingCount = pendingItems.length;
      renderContent(renderList());
      firstLoad = false;
    } catch (err) {
      console.error(err);
      if (firstLoad) {
        renderContent(`
          <div class="card">
            <div class="empty-state">
              <div class="empty-state__icon" style="background:var(--rose-50);color:var(--rose-600)">${ICONS.alert}</div>
              <div class="empty-state__title">Não foi possível carregar as solicitações</div>
              <div class="empty-state__message">${escapeHtml(err.message || 'Erro desconhecido')}</div>
              <button class="btn btn--primary mt-4" onclick="refresh()">${ICONS.refresh} Tentar novamente</button>
            </div>
          </div>
        `);
      } else {
        toast(err.message || 'Erro ao atualizar lista', 'error');
      }
    }
  }

  // ---------- Boot ----------
  renderShellOnce();
  renderLoading();
  refresh();
  setInterval(refresh, 10000);
</script>
</body>
</html>
