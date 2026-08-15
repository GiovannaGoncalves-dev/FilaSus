<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FilaSUS — Painel de Atendimento</title>
  <link rel="stylesheet" href="../css/styles.css">
  <style>
    body { margin: 0; overflow-x: hidden; }
    .display-panel, .display-main, .display-main > *, .display-card { min-width: 0; }
    .display-main { padding: 24px; display: grid; grid-template-columns: minmax(0, 2fr) minmax(0, 1fr); gap: 24px; }
    @media (max-width: 1024px) { .display-main { grid-template-columns: 1fr; } }
    .display-queues-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; margin-top: 16px; }
    .display-queues-grid .display-card { padding: 24px; }
    .display-queues-grid .display-password { font-size: 56px; line-height: 1.1; }
    .display-list-item { display: flex; align-items: center; gap: 16px; padding: 14px 16px; border-bottom: 1px solid var(--border); }
    .display-list-item:last-child { border-bottom: none; }
    .display-waiting-item { display: flex; align-items: center; gap: 12px; padding: 10px; border-radius: 8px; border: 1px solid var(--border); margin-bottom: 8px; }
    .display-waiting-item--priority { border-color: var(--amber-200); background: var(--amber-50); }
    @media (max-width: 768px) {
      .display-header { flex-wrap: nowrap; padding: 10px 12px; }
      .display-header > * { min-width: 0; }
      .display-header .sidebar__brand-icon { width: 40px; height: 40px; flex-shrink: 0; }
      #clinic-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      #clock { white-space: nowrap; }
      .display-main { grid-template-columns: minmax(0, 1fr); padding: 12px; gap: 12px; }
      .display-queues-grid { grid-template-columns: minmax(0, 1fr); gap: 12px; margin-top: 0; }
      .display-queues-grid .display-card { padding: 18px; }
      .display-queues-grid .display-password { font-size: clamp(40px, 15vw, 52px); overflow-wrap: anywhere; }
      .display-card h2 { white-space: normal !important; text-wrap: balance; }
      .display-footer { padding-inline: 12px; }
    }
    @media (max-width: 420px) {
      .display-header { gap: 8px; }
      .display-header .gap-3 { gap: 6px; }
      #btn-close { display: none; }
    }
  </style>
</head>
<body>
<div class="display-panel">
  <header class="display-header">
    <div class="flex items-center gap-2">
      <div class="sidebar__brand-icon" style="background:linear-gradient(135deg,var(--teal-500),var(--emerald-600))" id="brand-icon"></div>
      <div>
        <div style="font-weight:700" id="clinic-name">FilaSUS</div>
        <div style="font-size:10px;color:var(--text-muted)">Painel de Atendimento</div>
      </div>
    </div>
    <div class="flex items-center gap-3">
      <div class="flex items-center gap-2" style="font-size:14px;font-weight:600">
        <span style="color:var(--teal-600)" id="icon-clock"></span>
        <span class="font-mono" id="clock"></span>
      </div>
      <a href="login.jsp" class="btn btn--ghost btn--icon" style="color:var(--text-muted)" title="Sair do painel" id="btn-close"></a>
    </div>
  </header>

  <main class="display-main" id="main">
    <div class="flex items-center justify-center" style="min-height:400px">
      <div class="spinner spinner--lg" style="color:var(--teal-600)"></div>
    </div>
  </main>

  <footer class="display-footer">
    <div class="flex items-center gap-2">
      <span style="color:var(--teal-600)" id="icon-tv"></span>
      <span>Modo Painel — atualização automática</span>
    </div>
    <span id="session-name"></span>
  </footer>
</div>

<div id="announcement-container"></div>

<script src="../js/utils.js?v=5"></script>
<script src="../js/components.js?v=5"></script>
<script src="../mock/data.js?v=5"></script>
<script>
  document.getElementById('brand-icon').innerHTML = ICONS.heart;
  document.getElementById('icon-clock').innerHTML = ICONS.clock;
  document.getElementById('btn-close').innerHTML = ICONS.x;
  document.getElementById('icon-tv').innerHTML = ICONS.tv;

  // Relógio
  function tick() {
    document.getElementById('clock').textContent = new Date().toLocaleTimeString('pt-BR');
  }
  tick();
  setInterval(tick, 1000);

  let lastAnnouncedId = null;
  let dismissedId = null;

  async function refresh() {
    try {
      const data = await api('/api/display');
      document.getElementById('clinic-name').textContent = data.settings.clinicName;
      document.getElementById('session-name').textContent = data.session?.name || '';

      if (!data.session) {
        document.getElementById('main').innerHTML = `
          <div style="grid-column:1/-1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:12px;padding:48px;text-align:center">
            <div style="width:64px;height:64px;border-radius:50%;background:var(--amber-100);display:flex;align-items:center;justify-content:center;color:var(--amber-600)">${ICONS.alert}</div>
            <h2 style="font-size:20px;font-weight:600">Nenhum mutirão aberto na sua unidade</h2>
            <p style="color:var(--text-muted);font-size:14px;max-width:420px">
              O painel mostra apenas os mutirões da unidade a que você está vinculado.
              Volte mais tarde ou consulte a recepção.
            </p>
          </div>
        `;
        return;
      }

      const s = data.session;
      const recentCalled = data.lastCalled.slice(0, 4);
      const defaultPatients = {
        'TR': 'Juliana Marsaro Pinto',
        'CG': 'Carlos Eduardo Ferreira',
        'CA': 'Antônio Gonçalves Neto',
        'PD': 'Fernanda Dias Rocha',
        'EX': 'Ana Beatriz Oliveira'
      };

      document.getElementById('main').innerHTML = `
        <section style="display:flex;flex-direction:column;gap:16px;min-height:0">
          <div class="display-card">
            <div class="flex items-center justify-between" style="gap:8px;flex-wrap:wrap">
              <div style="min-width:0">
                <div style="font-size:11px;text-transform:uppercase;letter-spacing:0.05em;color:var(--teal-700);font-weight:600">Multirão em andamento</div>
                <h2 style="font-size:20px;font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(s.name)}</h2>
                <div style="font-size:12px;color:var(--text-muted);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(s.location)}</div>
              </div>
              <div style="text-align:right;font-size:12px;color:var(--text-muted)">
                <div style="font-weight:500;color:var(--slate-700)">${new Date(s.date + 'T12:00:00').toLocaleDateString('pt-BR',{day:'2-digit',month:'long'})}</div>
                <div>${s.startTime} — ${s.endTime}</div>
              </div>
            </div>
          </div>

          <div class="display-queues-grid">
            ${data.perQueue.slice(0, 4).map(pq => {
              const current = pq.current;
              const patientName = current?.patientName || 'Nenhum paciente em atendimento';
              const password = current?.password || '—';
              const isPriority = current?.priority === 'prioritario';
              const statusLabel = !current ? 'Fila aguardando chamada' : current.status === 'chamado' ? 'Senha chamada' : (current.status === 'aguardando' ? 'Próxima chamada' : 'Em atendimento');

              return `
                <div class="display-card ${current ? 'display-card--active' : ''}">
                  <div class="flex items-center justify-between" style="margin-bottom:12px">
                    <div style="font-size:13px;text-transform:uppercase;color:var(--slate-600);font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(pq.queue.name)}</div>
                    <span class="badge badge--teal" style="font-size:12px;padding:4px 10px">${ICONS.users} ${pq.waitingCount}</span>
                  </div>
                  <div style="font-size:11px;text-transform:uppercase;color:var(--teal-700);font-weight:700;letter-spacing:0.05em">${statusLabel}</div>
                  <div class="display-password ${isPriority ? 'display-password--priority' : ''}">${escapeHtml(password)}</div>
                  <div style="font-size:15px;color:var(--slate-700);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-top:6px;font-weight:600">${escapeHtml(patientName)}</div>
                </div>
              `;
            }).join('')}
          </div>
        </section>

        <section style="min-height:0">
          <div class="display-card" style="padding:0">
            <div style="padding:16px 20px;border-bottom:1px solid var(--border);font-size:13px;text-transform:uppercase;color:var(--text-muted);font-weight:700;letter-spacing:0.05em">Últimas senhas</div>
            <div style="padding:8px;max-height:70vh;overflow-y:auto" class="custom-scroll">
              ${recentCalled.length === 0 ? `
                <p style="text-align:center;font-size:15px;color:var(--text-subtle);padding:32px">Nenhuma chamada realizada ainda.</p>
              ` : recentCalled.map(c => `
                <div class="display-list-item">
                  <span class="font-mono font-bold" style="width:90px;font-size:20px;color:${c.priority === 'prioritario' ? 'var(--amber-600)' : 'var(--teal-700)'}">${escapeHtml(c.password)}</span>
                  <div style="flex:1;min-width:0">
                    <div style="font-size:15px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;font-weight:600">${escapeHtml(c.patientName || '')}</div>
                    <div style="font-size:12px;color:var(--text-subtle);overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escapeHtml(c.queueName || '')} · ${relativeTime(c.calledAt)}</div>
                  </div>
                  ${c.status === 'atendido' ? `<span style="color:var(--emerald-600)">${ICONS.check}</span>` : `<span class="badge badge--amber" style="font-size:11px;padding:3px 8px">Em andamento</span>`}
                </div>
              `).join('')}
            </div>
          </div>
        </section>
      `;

      // Anúncio de nova chamada
      const latest = data.lastCalled[0];
      if (latest && latest.id !== lastAnnouncedId && lastAnnouncedId !== null && latest.id !== dismissedId) {
        showAnnouncement(latest);
      }
      lastAnnouncedId = latest?.id || null;
    } catch (err) {
      console.error(err);
    }
  }

  function showAnnouncement(call) {
    const container = document.getElementById('announcement-container');
    container.innerHTML = `
      <div class="announcement ${call.priority === 'prioritario' ? 'announcement--priority' : ''}">
        ${ICONS.volume}
        <div>
          <div class="announcement__label">Senha chamada</div>
          <div class="announcement__password">${escapeHtml(call.password)}</div>
          <div style="font-size:14px;font-weight:500">${escapeHtml(call.patientName || '')} · ${escapeHtml(call.queueName || '')}</div>
        </div>
      </div>
    `;
    setTimeout(() => {
      container.innerHTML = '';
      dismissedId = call.id;
    }, 6000);
  }

  refresh();
  setInterval(refresh, 3000);
</script>
</body>
</html>
