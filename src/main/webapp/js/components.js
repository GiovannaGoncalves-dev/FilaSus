/* =========================================================================
 * FilaSUS — Componentes reutilizáveis
 * Funções que geram HTML padrão (sidebar, header, card, badge, etc.)
 * Uso: chamar a função e inserir o retorno via innerHTML ou insertAdjacentHTML.
 * ========================================================================= */

/* ---------- Tabs Scroller (setas < > quando há muitos itens) ---------- */
/* Envolve um bloco de tabs (ou qualquer strip horizontal) com botões de
   rolagem — usado quando a lista pode crescer (filas, categorias etc.) e
   não caberia toda visível ao mesmo tempo. */
function tabsScroller(innerHtml, id, amount = 200) {
  return `
    <div class="tabs-scroller" id="${id}">
      <button type="button" class="tabs-scroller__arrow" onclick="scrollTabsBy('${id}', ${-amount})" aria-label="Rolar para a esquerda">${ICONS.arrowLeft}</button>
      <div class="tabs-scroller__viewport">${innerHtml}</div>
      <button type="button" class="tabs-scroller__arrow" onclick="scrollTabsBy('${id}', ${amount})" aria-label="Rolar para a direita">${ICONS.arrowRight}</button>
    </div>
  `;
}
function scrollTabsBy(id, amount) {
  const el = document.querySelector(`#${id} .tabs-scroller__viewport`);
  if (el) el.scrollBy({ left: amount, behavior: 'smooth' });
}

/* ---------- App Shell (sidebar + header + main + footer) ---------- */
function renderAppShell({ navGroups, title, user, onLogout, childrenHtml }) {
  const initials = user?.name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '?';
  const roleLabel = ROLE_LABELS[user?.role] || '';
  const subtitle = user?.specialty ? ` · ${user.specialty}` : user?.station ? ` · ${user.station}` : '';
  // Calcula o caminho relativo para a raiz /jsp (onde está painel.jsp e login.jsp)
  // As páginas internas ficam em /jsp/{role}/*.jsp, então precisamos subir 1 nível.
  const basePath = (window.__JSP_BASE_PATH__) || '../';
  return `
    <div class="app-shell">
      <header class="header">
        <div class="header__title">
          <button class="header__mobile-toggle" onclick="toggleMobileSidebar()" aria-label="Abrir menu" aria-expanded="false" aria-controls="sidebar">
            ${ICONS.list}
          </button>
          <span>${escapeHtml(title || 'Painel')}</span>
        </div>
        <div class="header__actions">
          <a href="${basePath}painel.jsp" class="btn btn--outline btn--sm">
            ${ICONS.tv}
            <span class="hidden-mobile">Painel</span>
          </a>
        </div>
      </header>
      <div class="app-shell__body">
        <aside class="sidebar" id="sidebar">
          <div class="sidebar__brand">
            <div class="sidebar__brand-icon">${ICONS.heart}</div>
            <div>
              <div style="font-weight:700;line-height:1.1">FilaSUS</div>
              <div style="font-size:10px;color:var(--text-muted);line-height:1.1">Fila de Atendimento</div>
            </div>
          </div>
          <nav class="sidebar__nav">
            ${navGroups.map(g => `
              <div>
                <div class="sidebar__group-label">${escapeHtml(g.label)}</div>
                ${g.items.map(item => `
                  <a href="${item.href}" class="sidebar__item ${item.active ? 'sidebar__item--active' : ''}">
                    <span class="sidebar__item-icon">${ICONS[item.icon] || ICONS.dashboard}</span>
                    <span class="sidebar__item-label">${escapeHtml(item.label)}</span>
                    ${item.badge ? `<span class="sidebar__item-badge">${item.badge}</span>` : ''}
                  </a>
                `).join('')}
              </div>
            `).join('')}
          </nav>
          <div class="sidebar__user">
            <div class="sidebar__user-card">
              <div class="avatar avatar--${user?.role}">${initials}</div>
              <div style="flex:1;min-width:0">
                <div style="font-size:13px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(user?.name || '')}</div>
                <div style="font-size:10px;color:var(--text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${roleLabel}${subtitle}</div>
              </div>
              <button class="btn btn--ghost btn--icon" onclick="logout()" title="Sair" style="color:var(--text-muted)">${ICONS.logout}</button>
            </div>
          </div>
        </aside>
        <main class="main">
          <div class="main__inner">
            ${childrenHtml}
          </div>
        </main>
      </div>
      <footer class="footer">
        FilaSUS © ${new Date().getFullYear()} — Giovanna Gonçalves & Matheus Souza Rosa
      </footer>
    </div>
  `;
}

function toggleMobileSidebar() {
  const sidebar = document.getElementById('sidebar');
  if (!sidebar) return;
  const toggle = document.querySelector('.header__mobile-toggle');
  if (sidebar.classList.contains('sidebar--mobile')) {
    sidebar.classList.remove('sidebar--mobile', 'open');
    document.querySelector('.sidebar-backdrop')?.remove();
    document.body.classList.remove('mobile-nav-open');
    toggle?.setAttribute('aria-expanded', 'false');
    toggle?.setAttribute('aria-label', 'Abrir menu');
  } else {
    sidebar.classList.add('sidebar--mobile', 'open');
    const backdrop = document.createElement('div');
    backdrop.className = 'sidebar-backdrop';
    backdrop.onclick = toggleMobileSidebar;
    document.body.appendChild(backdrop);
    document.body.classList.add('mobile-nav-open');
    toggle?.setAttribute('aria-expanded', 'true');
    toggle?.setAttribute('aria-label', 'Fechar menu');
  }
}

/* ---------- Badges ---------- */
function statusBadge(status) {
  return `<span class="badge ${statusBadgeClass(status)}">${STATUS_LABELS[status] || status}</span>`;
}
function priorityBadge(priority) {
  return `<span class="badge ${priorityBadgeClass(priority)}">${PRIORITY_LABELS[priority] || priority}</span>`;
}
function sessionStatusBadge(status) {
  return `<span class="badge ${sessionStatusBadgeClass(status)}">${SESSION_STATUS_LABELS[status] || status}</span>`;
}

/* ---------- Stat Card ---------- */
function statCard({ label, value, hint, icon, accent = 'teal' }) {
  return `
    <div class="stat-card">
      <div class="stat-card__icon stat-card__icon--${accent}">${ICONS[icon] || ICONS.dashboard}</div>
      <div class="stat-card__label">${escapeHtml(label)}</div>
      <div class="stat-card__value">${escapeHtml(String(value))}</div>
      ${hint ? `<div class="stat-card__hint">${escapeHtml(hint)}</div>` : ''}
    </div>
  `;
}

/* ---------- Password Ticket ---------- */
function passwordTicket({ password, patientName, queueName, sessionName, position, estimatedWaitMinutes, priority = 'comum', priorityReason, status, priorityValidation, size = 'md' }) {
  const isPriority = priority === 'prioritario';
  const sizeStyle = size === 'lg' ? 'padding:32px;' : '';
  return `
    <div class="password-ticket ${isPriority ? 'password-ticket--priority' : ''}" style="${sizeStyle}">
      <div class="password-ticket__label">
        ${ICONS.ticket}
        Senha de Atendimento
        ${isPriority ? '<span class="badge badge--amber" style="margin-left:auto">Prioritário</span>' : ''}
      </div>
      <div class="password-ticket__password">${escapeHtml(password)}</div>
      ${queueName ? `<div class="password-ticket__queue">${escapeHtml(queueName)}</div>` : ''}
      ${patientName ? `<div class="password-ticket__patient">${escapeHtml(patientName)}</div>` : ''}
      ${sessionName ? `<div class="password-ticket__patient" style="display:flex;align-items:center;gap:4px">${ICONS.mapPin}${escapeHtml(sessionName)}</div>` : ''}
      ${priorityReason ? `<div style="font-size:12px;color:var(--amber-700);margin-top:4px">Motivo: ${escapeHtml(PRIORITY_REASON_LABELS[priorityReason] || priorityReason)}</div>` : ''}
      ${(position !== undefined || estimatedWaitMinutes !== undefined) ? `
        <div class="password-ticket__meta">
          ${position !== undefined && position > 0 ? `
            <div class="password-ticket__meta-item">
              ${ICONS.users}
              <span style="color:var(--text-muted)">Posição:</span>
              <strong>${position}ª</strong>
            </div>
          ` : ''}
          ${estimatedWaitMinutes !== undefined ? `
            <div class="password-ticket__meta-item">
              ${ICONS.clock}
              <span style="color:var(--text-muted)">Espera:</span>
              <strong>${formatMinutes(estimatedWaitMinutes)}</strong>
            </div>
          ` : ''}
        </div>
      ` : ''}
      ${(status || priorityValidation === 'pendente') ? `
        <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-top:12px">
          ${status ? statusBadge(status) : ''}
          ${priorityValidation === 'pendente'
            ? `<a href="solicitar-prioridade.jsp" class="btn btn--outline btn--sm" style="gap:6px">${ICONS.clock}<span>Prioridade pendente</span></a>`
            : ''}
        </div>
      ` : ''}
    </div>
  `;
}

/* ---------- Queue Row ---------- */
function queueRow({ item, actions = '' }) {
  return `
    <div class="queue-row">
      <div class="queue-row__password">${escapeHtml(item.password)}</div>
      <div>
        <div class="queue-row__patient-name">${escapeHtml(item.patientName || '—')}</div>
        ${item.patientAge !== undefined ? `<div class="queue-row__patient-meta">${item.patientAge} anos</div>` : ''}
      </div>
      <div>${priorityBadge(item.priority)}</div>
      <div>${statusBadge(item.status)}</div>
      <div>${item.status === 'aguardando' && item.position ? `<strong>${item.position}ª</strong>` : '—'}</div>
      <div class="queue-row__actions">${actions}</div>
    </div>
  `;
}
function queueHeader() {
  return `
    <div class="queue-header">
      <div>Senha</div>
      <div>Paciente</div>
      <div>Prioridade</div>
      <div>Status</div>
      <div>Pos.</div>
      <div>Ações</div>
    </div>
  `;
}

/* ---------- Empty State ---------- */
function emptyState({ icon = 'inbox', title, message, action = '' }) {
  return `
    <div class="card">
      <div class="empty-state">
        <div class="empty-state__icon">${ICONS[icon] || ICONS.info}</div>
        <div class="empty-state__title">${escapeHtml(title)}</div>
        <div class="empty-state__message">${escapeHtml(message)}</div>
        ${action}
      </div>
    </div>
  `;
}

/* ---------- Skeleton ---------- */
function skeletonGrid(n = 3, h = '120px') {
  return `<div class="grid grid-3">${Array.from({ length: n }, () => `<div class="skeleton" style="height:${h}"></div>`).join('')}</div>`;
}

/* ---------- Dialog (modal) ---------- */
function showDialog({ title, body, footer, size = '' }) {
  closeDialog();
  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.id = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog ${size === 'lg' ? 'dialog--lg' : ''}" role="dialog" aria-modal="true">
      <div class="dialog__header">
        <div class="dialog__title">${escapeHtml(title)}</div>
        <button class="dialog__close" onclick="closeDialog()" aria-label="Fechar">${ICONS.x}</button>
      </div>
      <div class="dialog__body">${body}</div>
      ${footer ? `<div class="dialog__footer">${footer}</div>` : ''}
    </div>
  `;
  overlay.addEventListener('click', e => { if (e.target === overlay) closeDialog(); });
  document.body.appendChild(overlay);
  return overlay;
}
function closeDialog() {
  document.getElementById('dialog-overlay')?.remove();
}

/* ---------- Confirm Dialog (Promise-based) ---------- */
function confirmDialog({ title, message, confirmText = 'Confirmar', cancelText = 'Cancelar', danger = false }) {
  return new Promise(resolve => {
    showDialog({
      title,
      body: `<p style="font-size:14px;color:var(--text-muted);line-height:1.5">${escapeHtml(message)}</p>`,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog(); window.__confirmResolve(false)">${escapeHtml(cancelText)}</button>
        <button class="btn ${danger ? 'btn--danger' : 'btn--primary'}" onclick="closeDialog(); window.__confirmResolve(true)">${escapeHtml(confirmText)}</button>
      `,
    });
    window.__confirmResolve = resolve;
  });
}

/* ---------- Page header ---------- */
function pageHeader({ title, subtitle, actions = '' }) {
  return `
    <div class="page-heading mb-6">
      <div class="page-heading__copy">
        <h1 class="page-heading__title">${escapeHtml(title)}</h1>
        ${subtitle ? `<p class="page-heading__subtitle">${escapeHtml(subtitle)}</p>` : ''}
      </div>
      ${actions ? `<div class="page-heading__actions">${actions}</div>` : ''}
    </div>
  `;
}
