<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Cadastrar Paciente</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .stepper-card {
      display: flex;
      align-items: flex-start;
      padding: 20px 24px 16px;
      margin-bottom: 16px;
    }
    .step {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      flex: 1;
      min-width: 100px;
      text-align: center;
    }
    .step__circle {
      width: 32px; height: 32px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 14px;
      background: var(--slate-100);
      color: var(--slate-500);
      border: 2px solid transparent;
      transition: background-color 0.2s, border-color 0.2s, color 0.2s;
      flex-shrink: 0;
    }
    .step--active .step__circle {
      background: var(--teal-600);
      color: #fff;
    }
    .step--done .step__circle {
      background: var(--emerald-100);
      color: var(--emerald-700);
    }
    .step__label {
      font-size: 13px;
      font-weight: 500;
      color: var(--text-muted);
    }
    .step--active .step__label { color: var(--text); font-weight: 600; }
    .step--done .step__label { color: var(--text); }
    .step__bar {
      flex: 1;
      height: 2px;
      background: var(--border);
      margin-top: 15px;
      min-width: 24px;
    }
    .step__bar--done { background: var(--emerald-500); }

    .patient-search-result {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px;
      border-radius: var(--radius);
      border: 1px solid var(--border);
      background: var(--surface);
      transition: border-color 0.15s, background 0.15s;
      cursor: pointer;
    }
    .patient-search-result:hover {
      border-color: var(--teal-400);
      background: var(--teal-50);
    }
    .patient-search-result__avatar {
      width: 40px; height: 40px;
      border-radius: 50%;
      background: var(--teal-100);
      color: var(--teal-800);
      display: flex; align-items: center; justify-content: center;
      font-weight: 700;
      flex-shrink: 0;
    }
    .patient-search-result__name {
      font-size: 14px; font-weight: 600;
    }
    .patient-search-result__meta {
      font-size: 12px; color: var(--text-muted); margin-top: 2px;
    }

    .queue-radio-card {
      display: block;
      padding: 14px;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      cursor: pointer;
      transition: background-color 0.15s, border-color 0.15s, box-shadow 0.15s;
      background: var(--surface);
    }
    .queue-radio-card:hover { border-color: var(--teal-400); background: var(--teal-50); }
    .queue-radio-card--selected {
      border-color: var(--teal-600);
      background: var(--teal-50);
      box-shadow: 0 0 0 2px var(--teal-200);
    }
    .queue-radio-card input { position: absolute; opacity: 0; pointer-events: none; }
    .queue-radio-card__title {
      font-size: 14px; font-weight: 600;
      display: flex; align-items: center; justify-content: space-between; gap: 8px;
    }
    .queue-radio-card__meta {
      font-size: 12px; color: var(--text-muted); margin-top: 4px;
    }

    .toggle {
      position: relative;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      cursor: pointer;
      user-select: none;
    }
    .toggle input { position: absolute; opacity: 0; pointer-events: none; }
    .toggle__track {
      width: 40px; height: 22px;
      background: var(--slate-200);
      border-radius: 9999px;
      transition: background 0.2s;
      position: relative;
      flex-shrink: 0;
    }
    .toggle__thumb {
      position: absolute;
      top: 2px; left: 2px;
      width: 18px; height: 18px;
      background: #fff;
      border-radius: 50%;
      box-shadow: 0 1px 3px rgba(0,0,0,0.2);
      transition: transform 0.2s;
    }
    .toggle input:checked + .toggle__track { background: var(--amber-500); }
    .toggle input:checked + .toggle__track .toggle__thumb { transform: translateX(18px); }
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

    /* Estado do wizard */
    const wizard = {
      step: 1,
      session: null,
      queues: [],
      // Step 1
      mode: 'search', /* 'search' | 'new' */
      searchQuery: '',
      searchResults: [],
      searching: false,
      searched: false,
      selectedPatient: null,
      newPatient: { name: '', cpf: '', cns: '', birthDate: '', phone: '' },
      newPatientError: null,
      creatingPatient: false,
      // Step 2
      selectedQueueId: null,
      priority: 'comum', /* 'comum' | 'prioritario' */
      // Step 3
      ticket: null,
      submitting: false,
    };

    function buildNavGroups() {
      return [{
        label: 'Operação',
        items: [
          { key: 'dashboard', label: 'Painel', icon: 'dashboard', href: 'dashboard.jsp' },
          { key: 'cadastrar', label: 'Cadastrar Paciente', icon: 'userPlus', href: 'cadastrar-paciente.jsp', active: true },
          { key: 'fila', label: 'Gerenciar Fila', icon: 'list', href: 'gerenciar-fila.jsp' },
          { key: 'historico', label: 'Histórico', icon: 'history', href: 'historico.jsp' },
        ],
      }];
    }

    function renderStepper() {
      const steps = ['Paciente', 'Fila & Prioridade', 'Senha Gerada'];
      return `
        <div class="card stepper-card">
          ${steps.map((label, i) => {
            const n = i + 1;
            const isDone = wizard.step > n;
            const isActive = wizard.step === n;
            const cls = isDone ? 'step--done' : isActive ? 'step--active' : '';
            const icon = isDone ? ICONS.check : `<span>${n}</span>`;
            const html = `
              <div class="step ${cls}">
                <div class="step__circle">${icon}</div>
                <div class="step__label">${escapeHtml(label)}</div>
              </div>
            `;
            const bar = i < steps.length - 1
              ? `<div class="step__bar ${isDone ? 'step__bar--done' : ''}"></div>`
              : '';
            return html + bar;
          }).join('')}
        </div>
      `;
    }

    /* ---------------- STEP 1 ---------------- */
    function renderStep1() {
      return `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Identificar Paciente</div>
              <div class="card__description">Busque um paciente existente ou cadastre um novo para inseri-lo na fila.</div>
            </div>
          </div>
          <div class="card__body">
            <div class="flex gap-2 mb-4" style="border-bottom:1px solid var(--border);padding-bottom:8px">
              <button class="btn ${wizard.mode === 'search' ? 'btn--primary' : 'btn--ghost'} btn--sm" onclick="setMode('search')">
                ${ICONS.search}
                Buscar Paciente
              </button>
              <button class="btn ${wizard.mode === 'new' ? 'btn--primary' : 'btn--ghost'} btn--sm" onclick="setMode('new')">
                ${ICONS.userPlus}
                Cadastrar Novo
              </button>
            </div>

            ${wizard.mode === 'search' ? renderSearchBlock() : renderNewPatientBlock()}
          </div>
          ${wizard.selectedPatient ? `
            <div class="card__footer" style="display:flex;justify-content:space-between;align-items:center;gap:8px;flex-wrap:wrap">
              <div style="font-size:13px;color:var(--text-muted)">
                Paciente selecionado: <strong style="color:var(--text)">${escapeHtml(wizard.selectedPatient.name)}</strong>
              </div>
              <button class="btn btn--primary" onclick="goToStep(2)">
                Avançar
                ${ICONS.arrowRight}
              </button>
            </div>
          ` : ''}
        </div>
      `;
    }

    function renderSearchBlock() {
      return `
        <div class="field">
          <label class="field__label">Buscar por nome, CPF ou CNS</label>
          <div class="flex gap-2">
            <input type="text" id="search-input" class="input flex-1" placeholder="Ex.: João, 123.456.789-01, 700 1234 5678 9012" value="${escapeHtml(wizard.searchQuery)}" oninput="onSearchInput(this.value)" onkeydown="if(event.key==='Enter')event.preventDefault()">
            <button class="btn btn--primary" onclick="runSearch()" ${wizard.searching ? 'disabled' : ''}>
              ${wizard.searching ? '<span class="spinner"></span>' : ICONS.search}
              Buscar
            </button>
          </div>
          <div class="field__hint">Digite ao menos 3 caracteres.</div>
        </div>

        ${wizard.searching ? `
          <div class="flex items-center gap-2" style="padding:16px;color:var(--text-muted)">
            <span class="spinner"></span> Buscando pacientes...
          </div>
        ` : wizard.searched ? (
          wizard.searchResults.length ? `
            <div style="display:flex;flex-direction:column;gap:8px;max-height:360px;overflow-y:auto">
              ${wizard.searchResults.map(p => `
                <div class="patient-search-result" onclick="selectPatient('${p.id}')">
                  <div class="patient-search-result__avatar">${escapeHtml((p.name || '?').slice(0,2).toUpperCase())}</div>
                  <div style="flex:1;min-width:0">
                    <div class="patient-search-result__name">${escapeHtml(p.name)}</div>
                    <div class="patient-search-result__meta">
                      CPF: ${escapeHtml(p.cpf || '—')}
                      ${p.cns ? ' · CNS: ' + escapeHtml(p.cns) : ''}
                      ${p.age !== undefined ? ' · ' + p.age + ' anos' : ''}
                    </div>
                  </div>
                  ${ICONS.arrowRight}
                </div>
              `).join('')}
            </div>
          ` : `
            <div class="alert alert--warning" style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
              ${ICONS.info}
              <div>
                <div class="alert__title">Nenhum paciente encontrado</div>
                <div class="alert__message">Cadastre um novo paciente clicando em "Cadastrar Novo" acima.</div>
              </div>
            </div>
          `
        ) : ''}
      `;
    }

    function renderNewPatientBlock() {
      const p = wizard.newPatient;
      const err = wizard.newPatientError;
      return `
        <div class="field-row">
          <div class="field">
            <label class="field__label field__label--required">Nome completo</label>
            <input type="text" class="input" value="${escapeHtml(p.name)}" oninput="updateNewPatient('name', this.value)" placeholder="Ex.: Maria da Silva">
          </div>
          <div class="field">
            <label class="field__label field__label--required">CPF</label>
            <input type="text" class="input" value="${escapeHtml(p.cpf)}" oninput="onCpfInput(this.value)" placeholder="000.000.000-00" inputmode="numeric">
          </div>
        </div>
        <div class="field-row">
          <div class="field">
            <label class="field__label">CNS (Cartão Nacional de Saúde)</label>
            <input type="text" class="input" value="${escapeHtml(p.cns)}" oninput="updateNewPatient('cns', this.value)" placeholder="700 0000 0000 0000" inputmode="numeric">
          </div>
          <div class="field">
            <label class="field__label field__label--required">Data de nascimento</label>
            <input type="date" class="input" value="${escapeHtml(p.birthDate)}" oninput="updateNewPatient('birthDate', this.value)">
          </div>
        </div>
        <div class="field">
          <label class="field__label field__label--required">Telefone</label>
          <input type="text" class="input" value="${escapeHtml(p.phone)}" oninput="onPhoneInput(this.value)" placeholder="(00) 00000-0000" inputmode="numeric">
        </div>

        ${err ? `<div class="alert alert--danger" style="display:flex;align-items:center;gap:8px;margin-top:8px">${ICONS.alert}<div class="alert__message">${escapeHtml(err)}</div></div>` : ''}

        <button class="btn btn--success" onclick="createPatient()" ${wizard.creatingPatient ? 'disabled' : ''}>
          ${wizard.creatingPatient ? '<span class="spinner"></span>' : ICONS.userCheck}
          Cadastrar e Selecionar
        </button>
      `;
    }

    /* ---------------- STEP 2 ---------------- */
    function renderStep2() {
      const p = wizard.selectedPatient;
      return `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Selecionar Fila e Prioridade</div>
              <div class="card__description">Escolha para qual fila o paciente será direcionado.</div>
            </div>
          </div>
          <div class="card__body">
            <div class="alert alert--info" style="display:flex;align-items:center;gap:12px;margin-bottom:20px">
              <div class="patient-search-result__avatar" style="width:36px;height:36px">${escapeHtml((p.name || '?').slice(0,2).toUpperCase())}</div>
              <div>
                <div style="font-weight:600">${escapeHtml(p.name)}</div>
                <div style="font-size:12px;color:var(--text-muted)">
                  CPF: ${escapeHtml(p.cpf || '—')} · ${p.age !== undefined ? p.age + ' anos' : 'idade indisponível'}
                </div>
              </div>
            </div>

            <label class="field__label" style="display:block;margin-bottom:8px">Filas disponíveis</label>
            <div class="grid grid-2" style="margin-bottom:20px">
              ${wizard.queues.map(q => `
                <label class="queue-radio-card ${wizard.selectedQueueId === q.id ? 'queue-radio-card--selected' : ''}">
                  <input type="radio" name="queue" value="${q.id}" ${wizard.selectedQueueId === q.id ? 'checked' : ''} onchange="selectQueue('${q.id}')">
                  <div class="queue-radio-card__title">
                    ${escapeHtml(q.name)}
                    ${wizard.selectedQueueId === q.id ? `<span class="badge badge--teal">${ICONS.check}</span>` : ''}
                  </div>
                  <div class="queue-radio-card__meta">
                    Prefixo <span class="font-mono">${escapeHtml(q.sequencePrefix)}</span> · tempo médio ${q.avgServiceMinutes} min
                  </div>
                </label>
              `).join('')}
            </div>

            <div style="padding:14px;border:1px solid var(--border);border-radius:var(--radius);background:var(--surface-2)">
              <label class="toggle">
                <input type="checkbox" ${wizard.priority === 'prioritario' ? 'checked' : ''} onchange="togglePriority(this.checked)">
                <span class="toggle__track"><span class="toggle__thumb"></span></span>
                <div>
                  <div style="font-size:14px;font-weight:600">Solicitar atendimento prioritário</div>
                  <div style="font-size:12px;color:var(--text-muted)">
                    ${p.age !== undefined && p.age >= 60
                      ? 'Paciente identificado como idoso (≥ 60 anos) — prioridade automática aplicada.'
                      : 'Marque se o paciente se enquadra em algum critério de prioridade.'}
                  </div>
                </div>
              </label>
              ${wizard.priority === 'prioritario' ? `
                <div class="field" style="margin-top:12px;margin-bottom:0">
                  <label class="field__label">Motivo da prioridade</label>
                  <select class="select" id="priority-reason">
                    <option value="idoso">Idoso (≥ 60 anos)</option>
                    <option value="deficiencia">Pessoa com deficiência</option>
                    <option value="doenca_pre_existente">Doença pré-existente</option>
                    <option value="gestante">Gestante</option>
                    <option value="lactante">Lactante</option>
                    <option value="crianca_ate_1_ano">Criança até 1 ano</option>
                  </select>
                </div>
              ` : ''}
            </div>
          </div>
          <div class="card__footer" style="display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap">
            <button class="btn btn--outline" onclick="goToStep(1)">
              ${ICONS.arrowLeft}
              Voltar
            </button>
            <button class="btn btn--primary" onclick="submitToQueue()" ${wizard.submitting || !wizard.selectedQueueId ? 'disabled' : ''}>
              ${wizard.submitting ? '<span class="spinner"></span>' : ICONS.ticket}
              Gerar Senha
            </button>
          </div>
        </div>
      `;
    }

    /* ---------------- STEP 3 ---------------- */
    function renderStep3() {
      const t = wizard.ticket;
      if (!t) {
        return `
          <div class="card">
            <div class="card__body">
              <div class="empty-state">
                <div class="empty-state__icon"><span class="spinner spinner--lg" style="color:var(--teal-600)"></span></div>
                <div class="empty-state__title">Gerando senha...</div>
              </div>
            </div>
          </div>
        `;
      }
      return `
        <div class="card">
          <div class="card__header">
            <div>
              <div class="card__title">Senha Gerada com Sucesso</div>
              <div class="card__description">Orientação ao paciente: dirija-se à sala de espera e acompanhe o painel.</div>
            </div>
          </div>
          <div class="card__body" style="display:flex;justify-content:center">
            <div style="width:100%;max-width:460px">
              ${passwordTicket({
                password: t.password,
                patientName: t.patientName,
                queueName: t.queueName,
                position: t.position,
                estimatedWaitMinutes: t.estimatedWaitMinutes,
                priority: t.priority,
                priorityReason: t.priorityReason,
                size: 'lg',
              })}
            </div>
          </div>
          <div class="card__footer" style="display:flex;justify-content:space-between;gap:8px;flex-wrap:wrap">
            <button class="btn btn--outline" onclick="resetWizard()">
              ${ICONS.userPlus}
              Cadastrar Outro Paciente
            </button>
            <a href="gerenciar-fila.jsp" class="btn btn--primary">
              ${ICONS.list}
              Ver na Fila
            </a>
          </div>
        </div>
      `;
    }

    function renderPage() {
      let stepHtml;
      if (wizard.step === 1) stepHtml = renderStep1();
      else if (wizard.step === 2) stepHtml = renderStep2();
      else stepHtml = renderStep3();

      const childrenHtml = `
        ${pageHeader({ title: 'Cadastrar Paciente', subtitle: wizard.session ? wizard.session.name : 'Carregando mutirão...' })}
        ${renderStepper()}
        ${stepHtml}
      `;
      document.getElementById('root').innerHTML = renderAppShell({
        navGroups: buildNavGroups(),
        title: 'Cadastrar Paciente',
        user,
        childrenHtml,
      });
      /* Atualiza selects e inputs com estado */
      if (wizard.step === 2 && wizard.priority === 'prioritario') {
        const sel = document.getElementById('priority-reason');
        if (sel && wizard.priorityReason) sel.value = wizard.priorityReason;
      }
    }

    /* ---------------- Ações do wizard ---------------- */
    function setMode(mode) {
      wizard.mode = mode;
      renderPage();
    }
    function onSearchInput(v) {
      wizard.searchQuery = v;
    }
    async function runSearch() {
      const q = wizard.searchQuery.trim();
      if (q.length < 3) {
        toast('Digite ao menos 3 caracteres para buscar.', 'warning');
        return;
      }
      wizard.searching = true;
      wizard.searched = false;
      renderPage();
      try {
        const data = await api('/api/patients', { method: 'GET' });
        const lower = q.toLowerCase();
        const digits = q.replace(/\D/g, '');
        wizard.searchResults = (data.patients || []).filter(p =>
          p.name.toLowerCase().includes(lower) ||
          (digits.length > 0 && p.cpf.replace(/\D/g, '').includes(digits)) ||
          (p.cns || '').toLowerCase().includes(lower)
        );
        wizard.searched = true;
      } catch (err) {
        toast(err.message || 'Erro ao buscar pacientes.', 'error');
      } finally {
        wizard.searching = false;
        renderPage();
      }
    }
    function selectPatient(id) {
      wizard.selectedPatient = wizard.searchResults.find(p => p.id === id) || null;
      if (wizard.selectedPatient && wizard.selectedPatient.age >= 60) {
        wizard.priority = 'prioritario';
        wizard.priorityReason = 'idoso';
      }
      toast(`Paciente ${wizard.selectedPatient.name} selecionado.`, 'success');
      renderPage();
    }
    function updateNewPatient(field, value) {
      wizard.newPatient[field] = value;
      wizard.newPatientError = null;
    }
    function onCpfInput(value) {
      wizard.newPatient.cpf = maskCpf(value);
      const el = document.querySelector('input[placeholder="000.000.000-00"]');
      if (el) el.value = wizard.newPatient.cpf;
    }
    function onPhoneInput(value) {
      wizard.newPatient.phone = maskPhone(value);
      const el = document.querySelector('input[placeholder="(00) 00000-0000"]');
      if (el) el.value = wizard.newPatient.phone;
    }
    async function createPatient() {
      const p = wizard.newPatient;
      if (!p.name.trim()) { wizard.newPatientError = 'Informe o nome completo.'; renderPage(); return; }
      if (p.cpf.replace(/\D/g, '').length !== 11) { wizard.newPatientError = 'CPF inválido (11 dígitos).'; renderPage(); return; }
      if (!p.birthDate) { wizard.newPatientError = 'Informe a data de nascimento.'; renderPage(); return; }
      if (p.phone.replace(/\D/g, '').length < 10) { wizard.newPatientError = 'Telefone inválido.'; renderPage(); return; }
      wizard.creatingPatient = true;
      renderPage();
      try {
        const data = await api('/api/patients', { method: 'POST', body: { ...p } });
        wizard.selectedPatient = data.patient;
        if (data.patient.age >= 60) {
          wizard.priority = 'prioritario';
          wizard.priorityReason = 'idoso';
        }
        toast(`Paciente ${data.patient.name} cadastrado.`, 'success', 'Cadastro concluído');
        goToStep(2);
      } catch (err) {
        wizard.newPatientError = err.message || 'Erro ao cadastrar paciente.';
        renderPage();
      } finally {
        wizard.creatingPatient = false;
      }
    }
    function selectQueue(id) {
      wizard.selectedQueueId = id;
      renderPage();
    }
    function togglePriority(checked) {
      wizard.priority = checked ? 'prioritario' : 'comum';
      if (checked && !wizard.priorityReason) {
        wizard.priorityReason = wizard.selectedPatient?.age >= 60 ? 'idoso' : 'doenca_pre_existente';
      }
      renderPage();
    }
    function goToStep(step) {
      wizard.step = step;
      renderPage();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
    async function submitToQueue() {
      if (!wizard.selectedQueueId) { toast('Selecione uma fila.', 'warning'); return; }
      if (!wizard.session) { toast('Nenhum mutirão aberto.', 'error'); return; }
      wizard.submitting = true;
      const reason = wizard.priority === 'prioritario'
        ? (document.getElementById('priority-reason')?.value || 'doenca_pre_existente')
        : undefined;
      try {
        const data = await api('/api/queue', {
          method: 'POST',
          body: {
            sessionId: wizard.session.id,
            queueId: wizard.selectedQueueId,
            patientId: wizard.selectedPatient.id,
            priority: wizard.priority,
            priorityReason: reason,
          },
        });
        const q = wizard.queues.find(qq => qq.id === wizard.selectedQueueId);
        wizard.ticket = { ...data.item, queueName: q?.name };
        wizard.submitting = false;
        goToStep(3);
        toast(`Senha ${data.item.password} gerada!`, 'success', 'Paciente na fila');
      } catch (err) {
        wizard.submitting = false;
        toast(err.message || 'Erro ao gerar senha.', 'error');
        renderPage();
      }
    }
    function resetWizard() {
      wizard.step = 1;
      wizard.mode = 'search';
      wizard.searchQuery = '';
      wizard.searchResults = [];
      wizard.searched = false;
      wizard.selectedPatient = null;
      wizard.newPatient = { name: '', cpf: '', cns: '', birthDate: '', phone: '' };
      wizard.selectedQueueId = null;
      wizard.priority = 'comum';
      wizard.priorityReason = undefined;
      wizard.ticket = null;
      renderPage();
    }

    async function init() {
      renderPage();
      try {
        const sessionRes = await api('/api/sessions/active');
        wizard.session = sessionRes.session;
        if (!wizard.session) {
          toast('Nenhum mutirão aberto. Não é possível cadastrar paciente.', 'warning');
        } else {
          wizard.queues = wizard.session.queues || [];
        }
        renderPage();
      } catch (err) {
        toast(err.message || 'Erro ao carregar mutirão.', 'error');
      }
    }

    init();
</script>
</body>
</html>
