<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Usuários</title>
  <link rel="stylesheet" href="../../css/styles.css">
  <style>
    .search-wrapper {
      position: relative;
      flex: 1;
      max-width: 420px;
    }
    .search-wrapper .input {
      padding-left: 38px;
    }
    .search-wrapper__icon {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-subtle);
      pointer-events: none;
    }
    .toggle-switch {
      display: inline-flex;
      align-items: center;
      width: 38px;
      height: 22px;
      border-radius: 9999px;
      background: var(--slate-300);
      padding: 2px;
      transition: background 0.15s;
      cursor: pointer;
      border: none;
      flex-shrink: 0;
    }
    .toggle-switch--on { background: var(--emerald-500); }
    .toggle-switch__thumb {
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: #fff;
      transition: transform 0.15s;
      box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
    }
    .toggle-switch--on .toggle-switch__thumb { transform: translateX(16px); }
    .toggle-switch:focus-visible {
      outline: 2px solid var(--teal-500);
      outline-offset: 2px;
    }
    .user-name-cell {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .user-name-cell .avatar {
      width: 32px;
      height: 32px;
      font-size: 11px;
    }
    .custom-select {
      position: relative;
      width: 100%;
    }
    .custom-select__trigger {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      padding: 10px 12px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      cursor: pointer;
      font-size: 14px;
      color: var(--text);
    }
    .custom-select__trigger:hover {
      border-color: var(--teal-400);
    }
    .custom-select__arrow {
      font-size: 12px;
      color: var(--text-muted);
      transition: transform 0.2s;
    }
    .custom-select--open .custom-select__arrow {
      transform: rotate(180deg);
    }
    .custom-select__dropdown {
      display: none;
      position: absolute;
      top: 100%;
      left: 0;
      right: 0;
      margin-top: 4px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow-lg);
      max-height: 180px;
      overflow-y: auto;
      z-index: 1000;
    }
    .custom-select--open .custom-select__dropdown {
      display: block;
    }
    .custom-select__option {
      padding: 10px 12px;
      cursor: pointer;
      font-size: 14px;
      color: var(--text);
    }
    .custom-select__option:hover {
      background: var(--teal-50);
      color: var(--teal-700);
    }
    .custom-select__option--placeholder {
      color: var(--text-muted);
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

  const navGroups = [{
    label: 'Administração',
    items: [
      { key: 'dashboard', label: 'Painel Geral', icon: 'dashboard', href: 'dashboard.jsp' },
      { key: 'multiroes', label: 'Multirões', icon: 'calendar', href: 'multiroes.jsp' },
      { key: 'filas', label: 'Filas', icon: 'list', href: 'filas.jsp' },
      { key: 'usuarios', label: 'Usuários', icon: 'users', href: 'usuarios.jsp', active: true },
      { key: 'relatorios', label: 'Relatórios', icon: 'chart', href: 'relatorios.jsp' },
    ],
  }];

  let allUsers = [];
  let units = [];
  let currentRole = 'atendente';
  let searchQuery = '';

  if (!isAuthenticated() || getCurrentUser()?.role !== 'admin') {
    window.location.href = '../login.jsp';
  } else {
    init();
  }


  function init() {
    const user = getCurrentUser();
    document.getElementById('root').innerHTML = renderAppShell({
      navGroups,
      title: 'Usuários',
      user,
      childrenHtml: `
        ${pageHeader({
          title: 'Usuários',
          subtitle: 'Gerencie atendentes, médicos, admins de unidade e pacientes',
          actions: `<button class="btn btn--primary" onclick="openNewUserDialog()">${ICONS.userPlus} Novo Usuário</button>`
        })}
        <div id="content">
          <div class="flex items-center justify-center" style="min-height:320px">
            <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
          </div>
        </div>
      `,
    });
    const painelLink = document.querySelector('a[href="painel.jsp"]');
    if (painelLink) painelLink.href = '../painel.jsp';

    load();
  }

  async function load() {
    try {
      const [atendRes, medRes, adminUnidRes, pacRes, unitsRes] = await Promise.all([
        api('/api/users?role=atendente'),
        api('/api/users?role=medico'),
        api('/api/users?role=admin_unidade'),
        api('/api/users?role=paciente'),
        api('/api/units'),
      ]);
      allUsers = [...atendRes.users, ...medRes.users, ...adminUnidRes.users, ...pacRes.users];
      units = unitsRes.units || [];
      render();
    } catch (err) {
      console.error(err);
      toast(err.message || 'Erro ao carregar.', 'error');
    }
  }

  function render() {
    const atendentesCount = allUsers.filter(u => u.role === 'atendente').length;
    const medicosCount = allUsers.filter(u => u.role === 'medico').length;
    const adminUnidCount = allUsers.filter(u => u.role === 'admin_unidade').length;
    const pacientesCount = allUsers.filter(u => u.role === 'paciente').length;

    const tabs = `
      <div class="tabs">
        <button class="tab ${currentRole === 'atendente' ? 'tab--active' : ''}" onclick="setRole('atendente')">
          Atendentes <span class="tab__count">${atendentesCount}</span>
        </button>
        <button class="tab ${currentRole === 'medico' ? 'tab--active' : ''}" onclick="setRole('medico')">
          Médicos <span class="tab__count">${medicosCount}</span>
        </button>
        <button class="tab ${currentRole === 'admin_unidade' ? 'tab--active' : ''}" onclick="setRole('admin_unidade')">
          Admin Unidade <span class="tab__count">${adminUnidCount}</span>
        </button>
        <button class="tab ${currentRole === 'paciente' ? 'tab--active' : ''}" onclick="setRole('paciente')">
          Pacientes <span class="tab__count">${pacientesCount}</span>
        </button>
      </div>
    `;

    const search = `
      <div class="flex items-center gap-2 mb-4">
        <div class="search-wrapper">
          <span class="search-wrapper__icon">${ICONS.search}</span>
          <input class="input" id="user-search" type="text" placeholder="Buscar por nome ou e-mail..." value="${escapeHtml(searchQuery)}" oninput="setSearch(this.value)">
        </div>
      </div>
    `;

    let users = allUsers.filter(u => u.role === currentRole);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      users = users.filter(u =>
        u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)
      );
    }

    const table = users.length === 0
      ? emptyState({
          icon: 'users',
          title: 'Nenhum usuário',
          message: searchQuery
            ? 'Nenhum usuário encontrado para a busca.'
            : 'Não há usuários deste perfil cadastrados.',
        })
      : `
        <div class="card">
          <div class="card__body--p0" style="overflow:auto;max-height:520px">
            <table class="table">
              <thead style="position:sticky;top:0;background:var(--surface);z-index:1">
                <tr>
                  <th>Nome</th>
                  <th>E-mail</th>
                  <th>Perfil</th>
                  <th>${currentRole === 'medico' ? 'Especialidade' : currentRole === 'paciente' ? 'CPF' : 'Unidade'}</th>
                  <th>Ativo</th>
                  <th>Criado em</th>
                </tr>
              </thead>
              <tbody>
                ${users.map(userRow).join('')}
              </tbody>
            </table>
          </div>
        </div>
      `;

    document.getElementById('content').innerHTML = tabs + search + table;
  }

  function userRow(u) {
    const initials = (u.name || '?')
      .split(' ').slice(0, 2).map(w => w[0] || '').join('').toUpperCase();
    const detail = u.role === 'medico' ? u.specialty : u.role === 'paciente' ? u.cpf : u.unitName;
    return `
      <tr>
        <td>
          <div class="user-name-cell">
            <div class="avatar avatar--${u.role}">${escapeHtml(initials)}</div>
            <span style="font-weight:500">${escapeHtml(u.name)}</span>
          </div>
        </td>
        <td style="color:var(--text-muted)">${escapeHtml(u.email)}</td>
        <td>${escapeHtml(ROLE_LABELS[u.role] || u.role)}</td>
        <td>${escapeHtml(detail || '—')}</td>
        <td>
          <button class="toggle-switch ${u.active ? 'toggle-switch--on' : ''}"
                  onclick="toggleActive('${u.id}', ${!u.active})"
                  role="switch"
                  aria-checked="${u.active}"
                  aria-label="${u.active ? 'Desativar' : 'Ativar'} usuário"
                  title="${u.active ? 'Desativar' : 'Ativar'}">
            <span class="toggle-switch__thumb"></span>
          </button>
        </td>
        <td style="color:var(--text-muted)">${u.createdAt ? formatDate(u.createdAt) : '—'}</td>
      </tr>
    `;
  }

  async function toggleActive(id, active) {
    try {
      await api('/api/users/' + id, { method: 'PATCH', body: { active } });
      const u = allUsers.find(x => x.id === id);
      if (u) u.active = active;
      toast(`Usuário ${active ? 'ativado' : 'desativado'} com sucesso.`, 'success');
      render();
      // Restore focus into search input
      const searchInput = document.getElementById('user-search');
      if (searchInput) {
        searchInput.focus();
        const len = searchInput.value.length;
        searchInput.setSelectionRange(len, len);
      }
    } catch (err) {
      toast(err.message || 'Erro ao atualizar.', 'error');
    }
  }

  function setRole(r) {
    currentRole = r;
    render();
  }

  function setSearch(q) {
    searchQuery = q;
    render();
    const searchInput = document.getElementById('user-search');
    if (searchInput) {
      searchInput.focus();
      const len = searchInput.value.length;
      searchInput.setSelectionRange(len, len);
    }
  }

  function openNewUserDialog() {
    showDialog({
      title: 'Novo Usuário',
      size: 'lg',
      body: `
        <form id="new-user-form" autocomplete="off">
          <div class="field">
            <label class="field__label field__label--required" for="nu-name">Nome completo</label>
            <input class="input" id="nu-name" name="name" type="text" placeholder="Ex.: Dra. Marina Costa" required>
          </div>
          <div class="field">
            <label class="field__label field__label--required" for="nu-email">E-mail</label>
            <input class="input" id="nu-email" name="email" type="email" placeholder="nome@filasus.gov.br" required>
          </div>
          <div class="field">
            <label class="field__label field__label--required" for="nu-password">Senha inicial</label>
            <input class="input" id="nu-password" name="password" type="password" minlength="8" placeholder="Mínimo de 8 caracteres" required>
          </div>
          <div class="field">
            <label class="field__label field__label--required" for="nu-role">Perfil</label>
            <select class="select" id="nu-role" name="role" onchange="toggleRoleFields(this.value)">
              <option value="atendente">Atendente</option>
              <option value="medico">Médico</option>
              <option value="admin_unidade">Admin Unidade</option>
              <option value="paciente">Paciente</option>
            </select>
          </div>
          <div class="field" id="nu-specialty-field">
            <label class="field__label field__label--required" for="nu-specialty">Especialidade</label>
            <input class="input" id="nu-specialty" name="specialty" type="text" placeholder="Ex.: Clínica Geral, Cardiologia, Pediatria">
          </div>
          <div class="field" id="nu-station-field">
            <label class="field__label field__label--required" for="nu-station">Posto</label>
            <input class="input" id="nu-station" name="station" type="text" placeholder="Ex.: Recepção A">
          </div>
          <div class="field" id="nu-unidade-field" style="display:none">
            <label class="field__label field__label--required" for="nu-unidade">Unidade</label>
            <div class="custom-select" id="nu-unidade-wrapper">
              <input type="hidden" id="nu-unidade" name="unidade" value="">
              <div class="custom-select__trigger" onclick="toggleUnidadeDropdown()">
                <span id="nu-unidade-text">Selecione a unidade...</span>
                <span class="custom-select__arrow">▾</span>
              </div>
              <div class="custom-select__dropdown" id="nu-unidade-dropdown">
                <div class="custom-select__option" onclick="selectUnidade('')">Selecione a unidade...</div>
              </div>
            </div>
          </div>
          <div class="field" id="nu-cpf-field">
            <label class="field__label field__label--required" for="nu-cpf">CPF</label>
            <input class="input" id="nu-cpf" name="cpf" type="text" placeholder="Ex.: 000.000.000-00">
          </div>
        </form>
      `,
      footer: `
        <button class="btn btn--outline" onclick="closeDialog()">Cancelar</button>
        <button class="btn btn--primary" onclick="submitNewUser()" id="nu-submit">Criar Usuário</button>
      `,
    });
    // Populate unidade dropdown
    const dropdown = document.getElementById('nu-unidade-dropdown');
    if (dropdown) {
      units.forEach(u => {
        const opt = document.createElement('div');
        opt.className = 'custom-select__option';
        opt.textContent = u.name;
        opt.onclick = function() { selectUnidade(String(u.id), u.name); };
        dropdown.appendChild(opt);
      });
    }
    toggleRoleFields('atendente');
  }

  function toggleUnidadeDropdown() {
    const wrapper = document.getElementById('nu-unidade-wrapper');
    if (wrapper) {
      wrapper.classList.toggle('custom-select--open');
    }
  }

  function selectUnidade(value, label) {
    const hidden = document.getElementById('nu-unidade');
    const text = document.getElementById('nu-unidade-text');
    const wrapper = document.getElementById('nu-unidade-wrapper');
    if (hidden) hidden.value = value;
    if (text) text.textContent = label || 'Selecione a unidade...';
    if (wrapper) wrapper.classList.remove('custom-select--open');
  }

  // Close dropdown when clicking outside
  document.addEventListener('click', function(e) {
    const wrapper = document.getElementById('nu-unidade-wrapper');
    if (wrapper && !wrapper.contains(e.target)) {
      wrapper.classList.remove('custom-select--open');
    }
  });

  function toggleRoleFields(role) {
    const specField = document.getElementById('nu-specialty-field');
    const statField = document.getElementById('nu-station-field');
    const unidField = document.getElementById('nu-unidade-field');
    const cpfField = document.getElementById('nu-cpf-field');
    if (!specField || !statField || !unidField || !cpfField) return;

    // Hide all optional fields first
    specField.style.display = 'none';
    statField.style.display = 'none';
    unidField.style.display = 'none';
    cpfField.style.display = '';

    // Show Unidade for all roles except paciente
    if (role !== 'paciente') {
      unidField.style.display = '';
    }

    // Show role-specific fields
    if (role === 'medico') {
      specField.style.display = '';
    }
    // paciente doesn't need extra fields
  }

  async function submitNewUser() {
    const form = document.getElementById('new-user-form');
    const name = form.name.value.trim();
    const email = form.email.value.trim();
    const cpf = form.cpf.value.replace(/\D/g, '');
    const password = form.password.value;
    const role = form.role.value;
    const specialty = form.specialty.value.trim();
    const station = form.station.value.trim();
    const unitId = parseInt(form.unidade.value, 10) || 0;

    if (!name || !email || cpf.length !== 11 || password.length < 8) {
      toast('Preencha nome, CPF, e-mail e uma senha de pelo menos 8 caracteres.', 'error');
      return;
    }
    if (role === 'medico' && !specialty) {
      toast('Informe a especialidade do médico.', 'error');
      return;
    }
    if (role !== 'paciente' && !unitId) {
      toast('Selecione a unidade.', 'error');
      return;
    }

    const btn = document.getElementById('nu-submit');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Criando...';
    try {
      const body = { name, email, cpf, password, role };
      if (role === 'medico') body.specialty = specialty;
      if (role !== 'paciente') body.unitId = unitId;
      await api('/api/users', { method: 'POST', body });
      closeDialog();
      toast('Usuário criado com sucesso.', 'success');
      currentRole = role;
      await load();
    } catch (err) {
      toast(err.message || 'Erro ao criar usuário.', 'error');
      btn.disabled = false;
      btn.innerHTML = 'Criar Usuário';
    }
  }
</script>
</body>
</html>
