<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Solicitar Prioridade</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .criteria-banner {
      display: flex;
      align-items: flex-start;
      gap: 14px;
      background: var(--amber-50);
      border: 1px solid var(--amber-200);
      border-radius: 12px;
      padding: 16px 18px;
    }
    .criteria-banner__icon {
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
    .criteria-banner__title {
      font-size: 14px;
      font-weight: 600;
      color: var(--amber-800);
    }
    .criteria-list {
      list-style: none;
      padding: 0;
      margin: 8px 0 0 0;
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 4px 16px;
      font-size: 12px;
      color: var(--amber-800);
    }
    @media (max-width: 640px) { .criteria-list { grid-template-columns: 1fr; } }
    .criteria-list li { display: flex; align-items: center; gap: 6px; }
    .criteria-list li::before {
      content: '';
      width: 4px;
      height: 4px;
      border-radius: 50%;
      background: var(--amber-600);
      flex-shrink: 0;
    }
    .section-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 16px;
      font-weight: 600;
      margin-bottom: 12px;
    }
    .section-title__icon { display: inline-flex; }
    .section-title__count {
      margin-left: auto;
      font-size: 11px;
      color: var(--text-muted);
      font-weight: 500;
    }
    .priority-card {
      display: flex;
      flex-direction: column;
      gap: 12px;
      padding: 16px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
    }
    .priority-card__head {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      gap: 12px;
    }
    .priority-card__password {
      font-family: var(--font-mono);
      font-size: 20px;
      font-weight: 700;
      letter-spacing: 0.05em;
    }
    .priority-card__queue {
      font-size: 12px;
      color: var(--text-muted);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin-top: 2px;
    }
    .priority-card__stats {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 10px;
      padding-top: 10px;
      border-top: 1px solid var(--border);
    }
    .priority-card__stat-label {
      font-size: 11px;
      color: var(--text-muted);
    }
    .priority-card__stat-value {
      font-size: 14px;
      font-weight: 700;
      margin-top: 2px;
    }
    .requested-card {
      padding: 16px;
      border-radius: 12px;
      border: 1px solid var(--border);
      border-left-width: 4px;
      background: var(--surface);
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .requested-card--pendente  { border-left-color: var(--amber-500); background: var(--amber-50); border-color: var(--amber-200); }
    .requested-card--aprovada  { border-left-color: var(--emerald-500); background: var(--emerald-50); border-color: var(--emerald-100); }
    .requested-card--rejeitada { border-left-color: var(--rose-500); background: var(--rose-50); border-color: var(--rose-100); }
    .requested-status {
      display: flex;
      align-items: flex-start;
      gap: 12px;
    }
    .requested-status__icon {
      width: 36px;
      height: 36px;
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .requested-card--pendente .requested-status__icon  { background: var(--amber-100); color: var(--amber-700); }
    .requested-card--aprovada .requested-status__icon  { background: var(--emerald-100); color: var(--emerald-700); }
    .requested-card--rejeitada .requested-status__icon { background: var(--rose-100); color: var(--rose-700); }
    .requested-status__title { font-size: 14px; font-weight: 600; }
    .requested-status__meta { font-size: 12px; color: var(--text-muted); margin-top: 2px; }
    /* Dialog form */
    .radio-card {
      display: flex;
      align-items: flex-start;
      gap: 10px;
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 10px 12px;
      cursor: pointer;
      font-size: 13px;
      transition: border-color 0.15s, background 0.15s;
    }
    .radio-card:hover { background: var(--slate-50); }
    .radio-card--selected {
      border-color: var(--primary);
      background: var(--teal-50);
    }
    .radio-card input[type="radio"] {
      margin-top: 2px;
      accent-color: var(--primary);
    }
    .file-input-wrap {
      display: flex;
      gap: 8px;
    }
    .file-input-wrap .input { flex: 1; }
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

  const navGroups = [{
    label: 'Paciente',
    items: [
      { key: 'dashboard',  label: 'Minha Fila',          icon: 'dashboard', href: 'dashboard.jsp' },
      { key: 'meus-dados', label: 'Meus Dados',          icon: 'user',      href: 'meus-dados.jsp' },
      { key: 'prioridade', label: 'Solicitar Prioridade',icon: 'alert',     href: 'solicitar-prioridade.jsp', active: true },
    ],
  }];

  /* ---------- Estado ---------- */
  let items = [];
  let isLoading = true;
  let dialogItemId = null;
  let submitting = false;
  let formState = { reason: '', description: '', fileName: '', file: null };

  const PRIORITY_VALIDATION_LABELS = {
    nao_solicitada: 'Não solicitada',
    pendente: 'Pendente de validação',
    aprovada: 'Aprovada',
    rejeitada: 'Rejeitada',
  };

  function renderShell() {
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Solicitar Prioridade',
      user,
      childrenHtml: `<div id="page-content"></div>`,
    });
  }

  function eligibleCard(item) {
    return `
      <article class="priority-card">
        <div class="priority-card__head">
          <div style="min-width:0">
            <div class="priority-card__password">${escapeHtml(item.password)}</div>
            <div class="priority-card__queue">${escapeHtml(item.queueName || '—')}</div>
          </div>
          <span class="badge badge--slate">Comum</span>
        </div>
        <div class="priority-card__stats">
          <div>
            <div class="priority-card__stat-label">Posição</div>
            <div class="priority-card__stat-value">${item.position > 0 ? `${item.position}ª` : '—'}</div>
          </div>
          <div>
            <div class="priority-card__stat-label">Espera estimada</div>
            <div class="priority-card__stat-value">${formatMinutes(item.estimatedWaitMinutes)}</div>
          </div>
        </div>
        <button type="button" class="btn btn--primary btn--block" style="background:var(--amber-600);gap:8px" onclick="openPriorityDialog('${escapeHtml(item.id)}')">
          ${ICONS.alert}
          <span>Solicitar Prioridade</span>
        </button>
      </article>
    `;
  }

  function requestedCard(item) {
    const status = item.priorityValidation;
    const isApproved = status === 'aprovada';
    const isPending = status === 'pendente';
    const isRejected = status === 'rejeitada';
    const statusIcon = isApproved ? ICONS.check : isPending ? ICONS.clock : ICONS.x;
    const statusText = PRIORITY_VALIDATION_LABELS[status] || status;
    const reasonText = item.priorityReason ? (PRIORITY_REASON_LABELS[item.priorityReason] || item.priorityReason) : '';

    let meta = '';
    if (isPending) meta = 'Aguarde: um médico irá validar sua solicitação.';
    else if (isApproved && item.priorityValidatedAt) meta = `Validado em ${formatDateTime(item.priorityValidatedAt)}.`;
    else if (isRejected) meta = item.priorityRejectionReason || 'Solicitação não aprovada.';

    return `
      <article class="requested-card requested-card--${status}">
        <div class="priority-card__head">
          <div style="min-width:0">
            <div class="priority-card__password">${escapeHtml(item.password)}</div>
            <div class="priority-card__queue">${escapeHtml(item.queueName || '—')}</div>
          </div>
          <span class="badge badge--amber">Prioritário</span>
        </div>
        <div class="requested-status">
          <div class="requested-status__icon">${statusIcon}</div>
          <div style="flex:1;min-width:0">
            <div class="requested-status__title">${escapeHtml(statusText)}</div>
            ${reasonText ? `<div class="requested-status__meta">Motivo: ${escapeHtml(reasonText)}</div>` : ''}
            ${meta ? `<div class="requested-status__meta" style="margin-top:4px">${escapeHtml(meta)}</div>` : ''}
          </div>
        </div>
      </article>
    `;
  }

  function renderPage() {
    const c = document.getElementById('page-content');
    if (!c) return;

    const notRequested = items.filter(i => i.priorityValidation === 'nao_solicitada');
    const requested = items.filter(i => i.priorityValidation !== 'nao_solicitada');

    let content;
    if (isLoading) {
      content = `
        ${pageHeader({ title: 'Solicitar Prioridade', subtitle: 'Se você se enquadra em algum dos critérios abaixo, solicite a avaliação. Um médico responsável validará sua solicitação com base no documento enviado.' })}
        <div class="criteria-banner" style="margin-bottom:16px">
          <div class="criteria-banner__icon">${ICONS.alert}</div>
          <div style="flex:1;min-width:0">
            <div class="criteria-banner__title">Critérios de prioridade</div>
            <ul class="criteria-list">
              ${Object.entries(PRIORITY_REASON_LABELS).map(([k, l]) => `<li>${escapeHtml(l)}</li>`).join('')}
            </ul>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:12px">
          <div class="skeleton" style="height:112px"></div>
          <div class="skeleton" style="height:112px"></div>
        </div>
      `;
    } else if (items.length === 0) {
      content = `
        ${pageHeader({ title: 'Solicitar Prioridade', subtitle: 'Se você se enquadra em algum dos critérios de prioridade abaixo, solicite a avaliação. Um médico responsável validará sua solicitação com base no documento enviado.' })}
        <div class="criteria-banner" style="margin-bottom:16px">
          <div class="criteria-banner__icon">${ICONS.alert}</div>
          <div style="flex:1;min-width:0">
            <div class="criteria-banner__title">Critérios de prioridade</div>
            <ul class="criteria-list">
              ${Object.entries(PRIORITY_REASON_LABELS).map(([k, l]) => `<li>${escapeHtml(l)}</li>`).join('')}
            </ul>
          </div>
        </div>
        ${emptyState({
          icon: 'ticket',
          title: 'Sem senhas ativas',
          message: 'Você não possui senhas em atendimento no momento. Gere uma senha primeiro para depois solicitar prioridade.',
        })}
      `;
    } else {
      content = `
        ${pageHeader({ title: 'Solicitar Prioridade', subtitle: 'Se você se enquadra em algum dos critérios abaixo, solicite a avaliação. Um médico responsável validará sua solicitação com base no documento enviado.' })}

        <div class="criteria-banner">
          <div class="criteria-banner__icon">${ICONS.alert}</div>
          <div style="flex:1;min-width:0">
            <div class="criteria-banner__title">Critérios de prioridade</div>
            <ul class="criteria-list">
              ${Object.entries(PRIORITY_REASON_LABELS).map(([k, l]) => `<li>${escapeHtml(l)}</li>`).join('')}
            </ul>
          </div>
        </div>

        <section style="margin-top:24px" aria-labelledby="eligible-title">
          <h3 id="eligible-title" class="section-title">
            <span class="section-title__icon" style="color:var(--amber-600)">${ICONS.alert}</span>
            Elegíveis para solicitação
            <span class="section-title__count">${notRequested.length} ${notRequested.length === 1 ? 'senha' : 'senhas'}</span>
          </h3>
          ${notRequested.length === 0
            ? emptyState({ icon: 'check', title: 'Nenhuma senha elegível', message: 'No momento você não tem nenhuma senha elegível para solicitação de prioridade.' })
            : `<div class="grid grid-2">${notRequested.map(eligibleCard).join('')}</div>`}
        </section>

        ${requested.length > 0 ? `
          <section style="margin-top:24px" aria-labelledby="requested-title">
            <h3 id="requested-title" class="section-title">
              <span class="section-title__icon" style="color:var(--primary)">${ICONS.clock}</span>
              Solicitações enviadas
              <span class="section-title__count">${requested.length} ${requested.length === 1 ? 'senha' : 'senhas'}</span>
            </h3>
            <div class="grid grid-2">${requested.map(requestedCard).join('')}</div>
          </section>
        ` : ''}
      `;
    }

    c.innerHTML = content;
  }

  /* ---------- Dialog ---------- */
  function openPriorityDialog(itemId) {
    const item = items.find(i => i.id === itemId);
    if (!item) return;
    dialogItemId = itemId;
    formState = { reason: '', description: '', fileName: '', file: null };
    renderDialog();
  }

  function renderDialog() {
    const item = items.find(i => i.id === dialogItemId);
    if (!item) return;
    const reasonsHtml = Object.entries(PRIORITY_REASON_LABELS).map(([key, label]) => `
      <label class="radio-card ${formState.reason === key ? 'radio-card--selected' : ''}" data-reason="${key}">
        <input type="radio" name="reason" value="${key}" ${formState.reason === key ? 'checked' : ''} onchange="setReason('${key}')">
        <span>${escapeHtml(label)}</span>
      </label>
    `).join('');

    const footer = `
      <button class="btn btn--outline" onclick="closePriorityDialog()" ${submitting ? 'disabled' : ''}>Cancelar</button>
      <button class="btn btn--primary" onclick="submitPriority()" ${submitting ? 'disabled' : ''} style="background:var(--amber-600);gap:8px">
        ${submitting ? '<span class="spinner"></span>' : ICONS.check}
        <span>${submitting ? 'Enviando...' : 'Enviar solicitação'}</span>
      </button>
    `;

    showDialog({
      title: 'Solicitar Prioridade',
      size: 'lg',
      body: `
        <p style="font-size:13px;color:var(--text-muted);margin-bottom:14px">
          Senha <strong style="font-family:var(--font-mono)">${escapeHtml(item.password)}</strong>
          — ${escapeHtml(item.queueName || 'fila')}
        </p>
        <div style="margin-bottom:14px">
          <div style="font-size:13px;font-weight:500;margin-bottom:8px">
            Motivo da prioridade <span style="color:var(--rose-600)">*</span>
          </div>
          <div style="display:flex;flex-direction:column;gap:6px">${reasonsHtml}</div>
        </div>
        <div style="margin-bottom:14px">
          <label for="doc-desc" style="font-size:13px;font-weight:500;display:block;margin-bottom:6px">
            Descrição do documento <span style="color:var(--rose-600)">*</span>
          </label>
          <textarea
            id="doc-desc"
            class="textarea"
            placeholder="Ex.: Laudo médico constatando gestação de alto risco, emitido em 12/03/2025."
            rows="3"
            oninput="setDescription(this.value)"
          >${escapeHtml(formState.description)}</textarea>
          <p style="font-size:11px;color:var(--text-muted);margin-top:4px">Descreva o documento que comprova o motivo selecionado.</p>
        </div>
        <div>
          <label for="doc-file" style="font-size:13px;font-weight:500;display:block;margin-bottom:6px">
            Documento comprobatório <span style="color:var(--rose-600)">*</span>
          </label>
          <div class="file-input-wrap">
            <input
              id="doc-file"
              class="input"
              type="file"
              accept=".pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png"
              onchange="setFile(this.files[0])"
              style="padding-left:36px"
            >
          </div>
          <p style="font-size:11px;color:var(--text-muted);margin-top:4px">
            Formatos aceitos: PDF, JPG e PNG, com até 10 MB.
          </p>
        </div>
      `,
      footer,
    });
  }

  function setReason(reason) {
    formState.reason = reason;
    // Atualiza apenas a classe selected dos radio cards sem re-renderizar o dialog inteiro
    document.querySelectorAll('.radio-card[data-reason]').forEach(el => {
      el.classList.toggle('radio-card--selected', el.getAttribute('data-reason') === reason);
    });
  }
  function setDescription(value) { formState.description = value; }
  function setFile(file) {
    formState.file = file || null;
    formState.fileName = file?.name || '';
  }

  function closePriorityDialog() {
    dialogItemId = null;
    submitting = false;
    closeDialog();
  }

  async function submitPriority() {
    if (!formState.reason) {
      toast('Selecione um motivo de prioridade.', 'error');
      return;
    }
    if (!formState.fileName.trim()) {
      toast('Informe o nome do documento anexado.', 'error');
      return;
    }
    if (!formState.description.trim()) {
      toast('Descreva o documento enviado para validação.', 'error');
      return;
    }
    const formData = new FormData();
    formData.append('itemId', dialogItemId);
    formData.append('reason', formState.reason);
    formData.append('description', formState.description.trim());
    formData.append('file', formState.file, formState.fileName);
    submitting = true;
    renderDialog();
    try {
      await api('/api/priority', {
        method: 'POST',
        body: formData,
      });
      toast('Solicitação de prioridade enviada para validação.', 'success');
      closePriorityDialog();
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao solicitar prioridade.', 'error');
      submitting = false;
      renderDialog();
    }
  }

  /* ---------- Data ---------- */
  async function load() {
    try {
      const data = await api('/api/my-queue');
      items = data.items || [];
    } catch (err) {
      toast(err.message || 'Erro ao carregar suas senhas.', 'error');
      items = [];
    } finally {
      isLoading = false;
      renderPage();
    }
  }

  /* ---------- Expor funções no escopo global para onclick ---------- */
  window.openPriorityDialog = openPriorityDialog;
  window.closePriorityDialog = closePriorityDialog;
  window.submitPriority = submitPriority;
  window.setReason = setReason;
  window.setDescription = setDescription;
  window.setFile = setFile;

  renderShell();
  renderPage();
  load();
  // Auto-refresh a cada 20s
  setInterval(load, 20000);
</script>
</body>
</html>
