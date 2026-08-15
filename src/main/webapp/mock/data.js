/* =========================================================================
 * FilaSUS — Mock API
 * Simula as respostas dos Servlets Java para demonstração do frontend.
 * Quando o backend estiver pronto, basta mudar USE_MOCK para false em utils.js.
 * ========================================================================= */

const MOCK_DB = {
  users: [
    { id: 'u_admin', name: 'Administrador do Sistema', email: 'admin@filasus.gov.br', role: 'admin', active: true },
    { id: 'u_atend_1', name: 'Marina Costa', email: 'marina.costa@filasus.gov.br', role: 'atendente', unidade: 'UBS Central', active: true },
    { id: 'u_atend_2', name: 'Pedro Almeida', email: 'pedro.almeida@filasus.gov.br', role: 'atendente', unidade: 'UBS Norte', active: true },
    { id: 'u_med_1', name: 'Dra. Helena Ribeiro', email: 'helena.ribeiro@filasus.gov.br', role: 'medico', specialty: 'Clínica Geral', unidade: 'UBS Central', active: true },
    { id: 'u_med_2', name: 'Dr. Carlos Mendes', email: 'carlos.mendes@filasus.gov.br', role: 'medico', specialty: 'Cardiologia', unidade: 'UBS Central', active: true },
    { id: 'u_med_3', name: 'Dra. Sofia Lima', email: 'sofia.lima@filasus.gov.br', role: 'medico', specialty: 'Pediatria', unidade: 'UBS Sul', active: true },
    { id: 'u_admin_unid_1', name: 'Carlos Eduardo Silva', email: 'carlos.silva@filasus.gov.br', role: 'admin_unidade', unidade: 'UBS Central', active: true },
    { id: 'u_admin_unid_2', name: 'Fernanda Oliveira', email: 'fernanda.oliveira@filasus.gov.br', role: 'admin_unidade', unidade: 'UBS Norte', active: true },
  ],
  patients: [
    { id: 'p_1', name: 'João Pereira da Silva', cpf: '123.456.789-01', cns: '700 1234 5678 9012', birthDate: '1952-03-15', phone: '(11) 98765-4321', age: 74, documents: [{ id: 'd1', fileName: 'rg.pdf', description: 'Documento de identidade', uploadedAt: '2026-06-20T10:00:00Z' }] },
    { id: 'p_2', name: 'Maria Aparecida Santos', cpf: '987.654.321-00', cns: '700 9876 5432 1000', birthDate: '1948-11-22', phone: '(11) 91234-5678', age: 77, documents: [] },
    { id: 'p_3', name: 'Ana Beatriz Oliveira', cpf: '456.789.123-00', birthDate: '1995-07-08', phone: '(11) 95555-4444', age: 30, documents: [] },
    { id: 'p_4', name: 'Carlos Eduardo Ferreira', cpf: '321.654.987-00', birthDate: '1988-01-30', phone: '(11) 93333-2222', age: 38, documents: [] },
    { id: 'p_5', name: 'Beatriz Carvalho Souza', cpf: '654.321.987-00', birthDate: '1965-09-12', phone: '(11) 97777-8888', age: 60, documents: [] },
    { id: 'p_6', name: 'Roberto Gusmão Lima', cpf: '111.222.333-44', birthDate: '1972-05-20', phone: '(11) 96666-5555', age: 54, documents: [] },
    { id: 'p_7', name: 'Fernanda Dias Rocha', cpf: '222.333.444-55', birthDate: '2000-12-03', phone: '(11) 94444-3333', age: 25, documents: [{ id: 'd2', fileName: 'relatorio-medico.pdf', description: 'Relatório de doença pré-existente', uploadedAt: '2026-06-25T14:00:00Z' }] },
    { id: 'p_8', name: 'Antônio Gonçalves Neto', cpf: '333.444.555-66', birthDate: '1945-04-18', phone: '(11) 92222-1111', age: 81, documents: [] },
    { id: 'p_9', name: 'Juliana Marsaro Pinto', cpf: '444.555.666-77', birthDate: '1990-08-25', phone: '(11) 99999-0000', age: 35, documents: [] },
    { id: 'p_10', name: 'Luís Fernando Castro', cpf: '555.666.777-88', birthDate: '1958-06-14', phone: '(11) 88888-7777', age: 67, documents: [] },
  ],
  sessions: [
    {
      id: 's_1', name: 'Mutirão de Atendimento - UBS Central',
      location: 'UBS Central - Rua das Flores, 123 - Centro',
      date: new Date().toISOString().slice(0, 10),
      startTime: '08:00', endTime: '17:00', status: 'aberta',
      queues: [
        { id: 'q_triagem', name: 'Triagem', avgServiceMinutes: 8, sequencePrefix: 'TR' },
        { id: 'q_clinico', name: 'Consulta - Clínico Geral', avgServiceMinutes: 20, sequencePrefix: 'CG' },
        { id: 'q_cardio', name: 'Consulta - Cardiologia', avgServiceMinutes: 25, sequencePrefix: 'CA' },
        { id: 'q_ped', name: 'Consulta - Pediatria', avgServiceMinutes: 22, sequencePrefix: 'PD' },
        { id: 'q_exames', name: 'Coleta de Exames', avgServiceMinutes: 10, sequencePrefix: 'EX' },
      ],
    },
    {
      id: 's_2', name: 'Mutirão de Cardiologia - UBS Norte',
      location: 'UBS Norte - Av. Brasil, 4500 - Norte',
      date: new Date(Date.now() + 2 * 86400000).toISOString().slice(0, 10),
      startTime: '08:00', endTime: '12:00', status: 'agendada',
      queues: [
        { id: 'q_triagem', name: 'Triagem', avgServiceMinutes: 8, sequencePrefix: 'TR' },
        { id: 'q_cardio', name: 'Consulta - Cardiologia', avgServiceMinutes: 25, sequencePrefix: 'CA' },
      ],
    },
    {
      id: 's_3', name: 'Mutirão de Pediatria - UBS Sul',
      location: 'UBS Sul - Rua Verde, 88 - Sul',
      date: new Date(Date.now() - 5 * 86400000).toISOString().slice(0, 10),
      startTime: '09:00', endTime: '16:00', status: 'encerrada',
      queues: [
        { id: 'q_triagem', name: 'Triagem', avgServiceMinutes: 8, sequencePrefix: 'TR' },
        { id: 'q_ped', name: 'Consulta - Pediatria', avgServiceMinutes: 22, sequencePrefix: 'PD' },
      ],
    },
  ],
  queueItems: [
    // Clínico Geral
    { id: 'qi_1', sessionId: 's_1', queueId: 'q_clinico', sequence: 1, password: 'CG-001', patientId: 'p_1', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 90 * 60000).toISOString(), calledAt: new Date(Date.now() - 85 * 60000).toISOString(), attendedAt: new Date(Date.now() - 82 * 60000).toISOString(), finishedAt: new Date(Date.now() - 78 * 60000).toISOString(), status: 'atendido', medicId: 'u_med_1', calledBy: 'u_atend_1' },
    { id: 'qi_2', sessionId: 's_1', queueId: 'q_clinico', sequence: 2, password: 'CG-002', patientId: 'p_2', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 75 * 60000).toISOString(), calledAt: new Date(Date.now() - 70 * 60000).toISOString(), attendedAt: new Date(Date.now() - 67 * 60000).toISOString(), finishedAt: new Date(Date.now() - 60 * 60000).toISOString(), status: 'atendido', medicId: 'u_med_1', calledBy: 'u_atend_1' },
    { id: 'qi_3', sessionId: 's_1', queueId: 'q_clinico', sequence: 3, password: 'CG-003', patientId: 'p_3', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 60 * 60000).toISOString(), calledAt: new Date(Date.now() - 55 * 60000).toISOString(), attendedAt: new Date(Date.now() - 52 * 60000).toISOString(), finishedAt: new Date(Date.now() - 45 * 60000).toISOString(), status: 'atendido', medicId: 'u_med_1', calledBy: 'u_atend_1' },
    { id: 'qi_4', sessionId: 's_1', queueId: 'q_clinico', sequence: 4, password: 'CG-004', patientId: 'p_4', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 40 * 60000).toISOString(), calledAt: new Date(Date.now() - 35 * 60000).toISOString(), attendedAt: new Date(Date.now() - 32 * 60000).toISOString(), status: 'em_atendimento', medicId: 'u_med_1', calledBy: 'u_atend_1' },
    { id: 'qi_5', sessionId: 's_1', queueId: 'q_clinico', sequence: 5, password: 'CG-005', patientId: 'p_5', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 30 * 60000).toISOString(), calledAt: new Date(Date.now() - 25 * 60000).toISOString(), status: 'chamado', calledBy: 'u_atend_1' },
    { id: 'qi_6', sessionId: 's_1', queueId: 'q_clinico', sequence: 6, password: 'CG-006', patientId: 'p_6', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 25 * 60000).toISOString(), status: 'aguardando' },
    { id: 'qi_7', sessionId: 's_1', queueId: 'q_clinico', sequence: 7, password: 'CG-007', patientId: 'p_7', priority: 'prioritario', priorityReason: 'doenca_pre_existente', priorityValidation: 'pendente', enteredAt: new Date(Date.now() - 20 * 60000).toISOString(), status: 'aguardando' },
    { id: 'qi_8', sessionId: 's_1', queueId: 'q_clinico', sequence: 8, password: 'CG-008', patientId: 'p_8', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 15 * 60000).toISOString(), status: 'aguardando' },
    { id: 'qi_9', sessionId: 's_1', queueId: 'q_clinico', sequence: 9, password: 'CG-009', patientId: 'p_9', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 10 * 60000).toISOString(), status: 'aguardando' },
    { id: 'qi_10', sessionId: 's_1', queueId: 'q_clinico', sequence: 10, password: 'CG-010', patientId: 'p_10', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 5 * 60000).toISOString(), status: 'aguardando' },
    // Cardiologia
    { id: 'qi_11', sessionId: 's_1', queueId: 'q_cardio', sequence: 1, password: 'CA-001', patientId: 'p_1', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 80 * 60000).toISOString(), calledAt: new Date(Date.now() - 75 * 60000).toISOString(), attendedAt: new Date(Date.now() - 72 * 60000).toISOString(), finishedAt: new Date(Date.now() - 65 * 60000).toISOString(), status: 'atendido', medicId: 'u_med_2', calledBy: 'u_atend_1' },
    { id: 'qi_12', sessionId: 's_1', queueId: 'q_cardio', sequence: 2, password: 'CA-002', patientId: 'p_8', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 50 * 60000).toISOString(), calledAt: new Date(Date.now() - 45 * 60000).toISOString(), attendedAt: new Date(Date.now() - 42 * 60000).toISOString(), status: 'em_atendimento', medicId: 'u_med_2', calledBy: 'u_atend_2' },
    { id: 'qi_13', sessionId: 's_1', queueId: 'q_cardio', sequence: 3, password: 'CA-003', patientId: 'p_5', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 35 * 60000).toISOString(), status: 'aguardando' },
    { id: 'qi_14', sessionId: 's_1', queueId: 'q_cardio', sequence: 4, password: 'CA-004', patientId: 'p_2', priority: 'prioritario', priorityReason: 'doenca_pre_existente', priorityValidation: 'pendente', enteredAt: new Date(Date.now() - 28 * 60000).toISOString(), status: 'aguardando' },
    // Triagem
    { id: 'qi_15', sessionId: 's_1', queueId: 'q_triagem', sequence: 1, password: 'TR-001', patientId: 'p_3', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 70 * 60000).toISOString(), calledAt: new Date(Date.now() - 65 * 60000).toISOString(), attendedAt: new Date(Date.now() - 62 * 60000).toISOString(), finishedAt: new Date(Date.now() - 58 * 60000).toISOString(), status: 'atendido', calledBy: 'u_atend_2' },
    { id: 'qi_16', sessionId: 's_1', queueId: 'q_triagem', sequence: 2, password: 'TR-002', patientId: 'p_6', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 45 * 60000).toISOString(), calledAt: new Date(Date.now() - 40 * 60000).toISOString(), attendedAt: new Date(Date.now() - 37 * 60000).toISOString(), finishedAt: new Date(Date.now() - 30 * 60000).toISOString(), status: 'atendido', calledBy: 'u_atend_2' },
    { id: 'qi_17', sessionId: 's_1', queueId: 'q_triagem', sequence: 3, password: 'TR-003', patientId: 'p_9', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 20 * 60000).toISOString(), calledAt: new Date(Date.now() - 5 * 60000).toISOString(), status: 'chamado', calledBy: 'u_atend_2' },
    { id: 'qi_18', sessionId: 's_1', queueId: 'q_triagem', sequence: 4, password: 'TR-004', patientId: 'p_10', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 8 * 60000).toISOString(), status: 'aguardando' },
    // Pediatria
    { id: 'qi_19', sessionId: 's_1', queueId: 'q_ped', sequence: 1, password: 'PD-001', patientId: 'p_7', priority: 'prioritario', priorityReason: 'doenca_pre_existente', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 30 * 60000).toISOString(), calledAt: new Date(Date.now() - 10 * 60000).toISOString(), attendedAt: new Date(Date.now() - 8 * 60000).toISOString(), status: 'em_atendimento', medicId: 'u_med_3', calledBy: 'u_atend_1' },
    // Senha ativa para João (p_1) - Triagem
    { id: 'qi_20', sessionId: 's_1', queueId: 'q_triagem', sequence: 5, password: 'TR-005', patientId: 'p_1', priority: 'prioritario', priorityReason: 'idoso', priorityValidation: 'aprovada', enteredAt: new Date(Date.now() - 5 * 60000).toISOString(), status: 'aguardando', calledBy: 'u_atend_1' },
    // Coleta de Exames
    { id: 'qi_21', sessionId: 's_1', queueId: 'q_exames', sequence: 1, password: 'EX-001', patientId: 'p_4', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 35 * 60000).toISOString(), calledAt: new Date(Date.now() - 15 * 60000).toISOString(), attendedAt: new Date(Date.now() - 12 * 60000).toISOString(), status: 'em_atendimento', calledBy: 'u_atend_2' },
    { id: 'qi_22', sessionId: 's_1', queueId: 'q_exames', sequence: 2, password: 'EX-002', patientId: 'p_6', priority: 'comum', priorityValidation: 'nao_solicitada', enteredAt: new Date(Date.now() - 20 * 60000).toISOString(), status: 'aguardando' },
  ],
  settings: {
    clinicName: 'FilaSUS — Mutirão do SUS',
    defaultAvgServiceMinutes: 15,
    enableAutoCall: false,
    absenceThreshold: 3,
    displayPanelTheme: 'light',
  },
  tokens: new Map(), // token -> userId
  tempUsers: new Map(), // tempUserId -> { user, patientId }
};

/* ---------- Helpers internos ---------- */
function getActiveSession() {
  return MOCK_DB.sessions.find(s => s.status === 'aberta');
}
function findPatient(id) { return MOCK_DB.patients.find(p => p.id === id); }
function findPatientByCpf(cpf) {
  const norm = cpf.replace(/\D/g, '');
  return MOCK_DB.patients.find(p => p.cpf.replace(/\D/g, '') === norm);
}
function findUser(id) {
  return MOCK_DB.users.find(u => u.id === id) || MOCK_DB.tempUsers.get(id)?.user;
}
function nextSeq(sessionId, queueId) {
  return MOCK_DB.queueItems
    .filter(qi => qi.sessionId === sessionId && qi.queueId === queueId)
    .reduce((max, qi) => Math.max(max, qi.sequence), 0) + 1;
}
function avgService(sessionId, queueId) {
  const finished = MOCK_DB.queueItems.filter(qi =>
    qi.status === 'atendido' && qi.attendedAt && qi.finishedAt &&
    qi.sessionId === sessionId && (!queueId || qi.queueId === queueId)
  );
  if (!finished.length) {
    const s = MOCK_DB.sessions.find(s => s.id === sessionId);
    const q = s?.queues.find(q => q.id === queueId);
    return q?.avgServiceMinutes || MOCK_DB.settings.defaultAvgServiceMinutes;
  }
  const total = finished.reduce((sum, qi) =>
    sum + (new Date(qi.finishedAt) - new Date(qi.attendedAt)), 0);
  return Math.round(total / finished.length / 60000);
}
function positionInQueue(item) {
  const waiting = MOCK_DB.queueItems
    .filter(qi => qi.sessionId === item.sessionId && qi.queueId === item.queueId && qi.status === 'aguardando')
    .sort((a, b) => {
      if (a.priority !== b.priority) return a.priority === 'prioritario' ? -1 : 1;
      return a.sequence - b.sequence;
    });
  return waiting.findIndex(qi => qi.id === item.id) + 1;
}
function estimateWait(item) {
  const ahead = MOCK_DB.queueItems.filter(qi =>
    qi.sessionId === item.sessionId && qi.queueId === item.queueId &&
    qi.status === 'aguardando' &&
    (qi.priority === 'prioritario'
      ? item.priority === 'prioritario' ? qi.sequence < item.sequence : true
      : item.priority === 'comum' && qi.sequence < item.sequence)
  ).length;
  return ahead * avgService(item.sessionId, item.queueId);
}
function enrichItem(qi) {
  const patient = findPatient(qi.patientId);
  return {
    ...qi,
    patientName: patient?.name,
    patientAge: patient?.age,
    patientCpf: patient?.cpf,
    position: qi.status === 'aguardando' ? positionInQueue(qi) : 0,
    estimatedWaitMinutes: qi.status === 'aguardando' ? estimateWait(qi) : 0,
  };
}

/* ---------- Mock API router ---------- */
async function mockApi(path, options = {}) {
  await new Promise(r => setTimeout(r, 100)); // simular latência
  const method = (options.method || 'GET').toUpperCase();
  const url = new URL(path, 'http://mock');
  const pathname = url.pathname;
  const body = options.body || {};

  // POST /api/auth (login)
  if (pathname === '/api/auth' && method === 'POST') {
    const email = (body.email || '').trim();
    const role = body.role;
    let user = MOCK_DB.users.find(u => u.email.toLowerCase() === email.toLowerCase() && u.active);
    if (!user && (role === 'paciente' || email.replace(/\D/g, '').length >= 11)) {
      const patient = findPatientByCpf(email);
      if (patient) {
        user = { id: `u_patient_${patient.id}`, name: patient.name, email: patient.cpf, role: 'paciente', active: true };
        MOCK_DB.tempUsers.set(user.id, { user, patientId: patient.id });
        const token = 'tok_' + user.id + '_' + Date.now().toString(36);
        MOCK_DB.tokens.set(token, user.id);
        // Persist patientId in localStorage for page refresh
        localStorage.setItem('filasus_patientId', patient.id);
        return { token, user, patientId: patient.id };
      }
      throw errorResponse(404, 'Paciente não encontrado. Verifique o CPF ou realize o cadastro.');
    }
    if (!user) throw errorResponse(401, 'Credenciais inválidas.');
    if (role && user.role !== role)
      throw errorResponse(403, `Este e-mail não possui perfil "${role}".`);
    const token = 'tok_' + user.id + '_' + Date.now().toString(36);
    MOCK_DB.tokens.set(token, user.id);
    return { token, user };
  }

  // DELETE /api/auth (logout)
  if (pathname === '/api/auth' && method === 'DELETE') return { ok: true };

  // GET /api/me
  if (pathname === '/api/me') {
    const user = currentUser(options);
    if (!user) throw errorResponse(401, 'Não autenticado.');
    const patientId = MOCK_DB.tempUsers.get(user.id)?.patientId;
    return { user, patientId };
  }

  // GET /api/patients
  if (pathname === '/api/patients' && method === 'GET') {
    const search = (url.searchParams.get('search') || '').toLowerCase();
    let list = [...MOCK_DB.patients];
    if (search) {
      list = list.filter(p =>
        p.name.toLowerCase().includes(search) ||
        p.cpf.replace(/\D/g, '').includes(search.replace(/\D/g, '')) ||
        (p.cns || '').toLowerCase().includes(search)
      );
    }
    list.sort((a, b) => a.name.localeCompare(b.name));
    return { patients: list };
  }
  // POST /api/patients
  if (pathname === '/api/patients' && method === 'POST') {
    if (findPatientByCpf(body.cpf)) throw errorResponse(400, 'Já existe um paciente com este CPF.');
    const patient = {
      id: 'p_' + Date.now().toString(36),
      name: body.name.trim(),
      cpf: body.cpf,
      cns: body.cns,
      birthDate: body.birthDate,
      phone: body.phone,
      age: calcAge(body.birthDate),
      documents: [],
      createdAt: new Date().toISOString(),
    };
    MOCK_DB.patients.push(patient);
    return { patient };
  }

  // GET /api/patients/:id
  const patMatch = pathname.match(/^\/api\/patients\/([\w_]+)$/);
  if (patMatch && method === 'GET') {
    const p = findPatient(patMatch[1]);
    if (!p) throw errorResponse(404, 'Paciente não encontrado.');
    return { patient: p };
  }

  // GET /api/sessions
  if (pathname === '/api/sessions' && method === 'GET') {
    const status = url.searchParams.get('status');
    let list = [...MOCK_DB.sessions];
    if (status) list = list.filter(s => s.status === status);
    list.sort((a, b) => (a.date < b.date ? 1 : -1));
    return { sessions: list };
  }
  // POST /api/sessions
  if (pathname === '/api/sessions' && method === 'POST') {
    const allQueues = Array.from(new Map(MOCK_DB.sessions.flatMap(s => s.queues).map(q => [q.id, q])).values());
    const queues = (body.queueIds || []).length
      ? allQueues.filter(q => body.queueIds.includes(q.id))
      : allQueues.slice(0, 3);
    const session = {
      id: 's_' + Date.now().toString(36),
      name: body.name, location: body.location, date: body.date,
      startTime: body.startTime || '08:00', endTime: body.endTime || '17:00',
      status: 'agendada', queues, createdAt: new Date().toISOString(),
    };
    MOCK_DB.sessions.push(session);
    return { session };
  }
  // GET /api/sessions/active
  if (pathname === '/api/sessions/active') return { session: getActiveSession() || null };

  // PATCH /api/sessions/:id
  const sessMatch = pathname.match(/^\/api\/sessions\/([\w_]+)$/);
  if (sessMatch && method === 'PATCH') {
    const s = MOCK_DB.sessions.find(s => s.id === sessMatch[1]);
    if (!s) throw errorResponse(404, 'Multirão não encontrado.');
    s.status = body.status;
    return { session: s };
  }

  // GET /api/queue
  if (pathname === '/api/queue' && method === 'GET') {
    const sessionId = url.searchParams.get('sessionId') || getActiveSession()?.id;
    const queueId = url.searchParams.get('queueId');
    const status = url.searchParams.get('status');
    if (!sessionId) return { items: [], metrics: null };
    let items = MOCK_DB.queueItems.filter(qi => qi.sessionId === sessionId);
    if (queueId) items = items.filter(qi => qi.queueId === queueId);
    if (status) items = items.filter(qi => qi.status === status);
    items.sort((a, b) => {
      if (a.priority !== b.priority) return a.priority === 'prioritario' ? -1 : 1;
      return a.sequence - b.sequence;
    });
    return { items: items.map(enrichItem), metrics: computeMetrics(sessionId, queueId) };
  }
  // POST /api/queue
  if (pathname === '/api/queue' && method === 'POST') {
    const sessionId = body.sessionId || getActiveSession()?.id;
    const session = MOCK_DB.sessions.find(s => s.id === sessionId);
    if (!session || session.status !== 'aberta') throw errorResponse(400, 'Multirão não está aberto.');
    const queue = session.queues.find(q => q.id === body.queueId);
    if (!queue) throw errorResponse(400, 'Fila não encontrada.');
    const patient = findPatient(body.patientId);
    if (!patient) throw errorResponse(400, 'Paciente não encontrado.');
    const exists = MOCK_DB.queueItems.find(qi =>
      qi.sessionId === sessionId && qi.queueId === body.queueId &&
      qi.patientId === body.patientId &&
      ['aguardando', 'chamado', 'em_atendimento'].includes(qi.status));
    if (exists) throw errorResponse(400, 'Paciente já está nesta fila.');
    const seq = nextSeq(sessionId, body.queueId);
    const password = `${queue.sequencePrefix}-${String(seq).padStart(3, '0')}`;
    const isElderly = patient.age >= 60;
    const wantsPriority = body.priority === 'prioritario' || (isElderly && !body.priority);
    const item = {
      id: 'qi_' + Date.now().toString(36),
      sessionId, queueId: body.queueId, sequence: seq, password, patientId: body.patientId,
      priority: wantsPriority ? 'prioritario' : 'comum',
      priorityReason: wantsPriority ? (body.priorityReason || (isElderly ? 'idoso' : 'doenca_pre_existente')) : undefined,
      priorityValidation: wantsPriority ? (isElderly ? 'aprovada' : 'pendente') : 'nao_solicitada',
      enteredAt: new Date().toISOString(), status: 'aguardando',
      calledBy: currentUser(options)?.id,
    };
    MOCK_DB.queueItems.push(item);
    return { item: enrichItem(item), metrics: computeMetrics(sessionId, body.queueId) };
  }

  // POST /api/queue/call-next
  if (pathname === '/api/queue/call-next' && method === 'POST') {
    const sessionId = body.sessionId || getActiveSession()?.id;
    const waiting = MOCK_DB.queueItems
      .filter(qi => qi.sessionId === sessionId && qi.status === 'aguardando' && (!body.queueId || qi.queueId === body.queueId))
      .sort((a, b) => {
        if (a.priority !== b.priority) return a.priority === 'prioritario' ? -1 : 1;
        return a.sequence - b.sequence;
      });
    if (!waiting.length) return { item: null, message: 'Fila vazia.' };
    const next = waiting[0];
    next.status = 'chamado';
    next.calledAt = new Date().toISOString();
    next.calledBy = currentUser(options)?.id;
    return { item: enrichItem(next) };
  }

  // PATCH /api/queue/:id
  const qiMatch = pathname.match(/^\/api\/queue\/([\w_]+)$/);
  if (qiMatch && method === 'PATCH') {
    const item = MOCK_DB.queueItems.find(qi => qi.id === qiMatch[1]);
    if (!item) throw errorResponse(404, 'Item não encontrado.');
    item.status = body.status;
    if (body.status === 'remarcado') {
      const session = MOCK_DB.sessions.find(s => s.id === item.sessionId);
      const queue = session?.queues.find(q => q.id === item.queueId);
      const newSeq = nextSeq(item.sessionId, item.queueId);
      const newItem = { ...item, id: 'qi_' + Date.now().toString(36), sequence: newSeq, password: `${queue.sequencePrefix}-${String(newSeq).padStart(3, '0')}`, enteredAt: new Date().toISOString(), calledAt: undefined, attendedAt: undefined, finishedAt: undefined, status: 'aguardando' };
      MOCK_DB.queueItems.push(newItem);
      return { item, newItem: enrichItem(newItem), message: 'Paciente remarcado e reinserido no final da fila.' };
    }
    return { item };
  }

  // GET /api/my-queue
  if (pathname === '/api/my-queue') {
    const user = currentUser(options);
    if (!user) return { items: [] };
    // Get patientId from tempUsers or localStorage
    let patientId = MOCK_DB.tempUsers.get(user.id)?.patientId;
    if (!patientId) {
      patientId = localStorage.getItem('filasus_patientId');
      // Re-create tempUser if found in localStorage
      if (patientId && user.id) {
        MOCK_DB.tempUsers.set(user.id, { user, patientId });
      }
    }
    if (!patientId) return { items: [] };
    const items = MOCK_DB.queueItems
      .filter(qi => qi.patientId === patientId && ['aguardando', 'chamado', 'em_atendimento'].includes(qi.status))
      .map(qi => {
        const s = MOCK_DB.sessions.find(s => s.id === qi.sessionId);
        const q = s?.queues.find(q => q.id === qi.queueId);
        return { ...enrichItem(qi), sessionName: s?.name, queueName: q?.name };
      })
      .sort((a, b) => new Date(b.enteredAt) - new Date(a.enteredAt));
    return { items };
  }

  // GET /api/history
  if (pathname === '/api/history') {
    const sessionId = url.searchParams.get('sessionId');
    const patientId = url.searchParams.get('patientId');
    let entries = MOCK_DB.queueItems.filter(qi => ['atendido', 'ausente', 'remarcado'].includes(qi.status));
    if (sessionId) entries = entries.filter(qi => qi.sessionId === sessionId);
    if (patientId) entries = entries.filter(qi => qi.patientId === patientId);
    return { history: entries.map(qi => {
      const s = MOCK_DB.sessions.find(s => s.id === qi.sessionId);
      const q = s?.queues.find(q => q.id === qi.queueId);
      const medic = qi.medicId ? findUser(qi.medicId) : null;
      return { ...qi, patientName: findPatient(qi.patientId)?.name, sessionName: s?.name, queueName: q?.name, medicName: medic?.name };
    }).sort((a, b) => new Date(b.finishedAt || b.calledAt || b.enteredAt) - new Date(a.finishedAt || a.calledAt || a.enteredAt)) };
  }

  // GET /api/priority
  if (pathname === '/api/priority' && method === 'GET') {
    const status = url.searchParams.get('status') || 'pendente';
    const sessionId = url.searchParams.get('sessionId') || getActiveSession()?.id;
    const items = MOCK_DB.queueItems
      .filter(qi => qi.priorityValidation === status && (!sessionId || qi.sessionId === sessionId))
      .map(qi => {
        const p = findPatient(qi.patientId);
        const s = MOCK_DB.sessions.find(s => s.id === qi.sessionId);
        const q = s?.queues.find(q => q.id === qi.queueId);
        return { ...qi, patientName: p?.name, patientAge: p?.age, patientCpf: p?.cpf, documents: p?.documents || [], queueName: q?.name, sessionName: s?.name };
      });
    return { items };
  }
  // POST /api/priority
  if (pathname === '/api/priority' && method === 'POST') {
    const item = MOCK_DB.queueItems.find(qi => qi.id === body.itemId);
    if (!item) throw errorResponse(404, 'Item não encontrado.');
    item.priorityValidation = 'pendente';
    item.priorityReason = body.reason;
    item.priority = 'prioritario';
    return { item };
  }
  // PATCH /api/priority/:id
  const prMatch = pathname.match(/^\/api\/priority\/([\w_]+)$/);
  if (prMatch && method === 'PATCH') {
    const item = MOCK_DB.queueItems.find(qi => qi.id === prMatch[1]);
    if (!item) throw errorResponse(404, 'Solicitação não encontrada.');
    if (item.priorityValidation !== 'pendente') throw errorResponse(400, 'Já processada.');
    if (body.action === 'approve') {
      item.priorityValidation = 'aprovada';
      item.priorityValidatedAt = new Date().toISOString();
      item.priority = 'prioritario';
    } else if (body.action === 'reject') {
      item.priorityValidation = 'rejeitada';
      item.priorityValidatedAt = new Date().toISOString();
      item.priority = 'comum';
    }
    return { item };
  }

  // GET /api/attendance
  if (pathname === '/api/attendance' && method === 'GET') {
    const medicId = url.searchParams.get('medicId');
    const sessionId = url.searchParams.get('sessionId') || getActiveSession()?.id;
    const inProgress = MOCK_DB.queueItems.find(qi =>
      qi.status === 'em_atendimento' && qi.medicId === medicId && qi.sessionId === sessionId);
    if (!inProgress) return { attendance: null };
    const p = findPatient(inProgress.patientId);
    return { attendance: { ...inProgress, patientName: p?.name, patientAge: p?.age, patientCpf: p?.cpf } };
  }
  // POST /api/attendance
  if (pathname === '/api/attendance' && method === 'POST') {
    const item = MOCK_DB.queueItems.find(qi => qi.id === body.itemId);
    if (!item) throw errorResponse(404, 'Item não encontrado.');
    item.status = 'em_atendimento';
    item.medicId = currentUser(options)?.id;
    if (!item.attendedAt) item.attendedAt = new Date().toISOString();
    const p = findPatient(item.patientId);
    return { item: { ...item, patientName: p?.name, patientAge: p?.age, patientCpf: p?.cpf } };
  }
  // PATCH /api/attendance/:id
  const attMatch = pathname.match(/^\/api\/attendance\/([\w_]+)$/);
  if (attMatch && method === 'PATCH') {
    const item = MOCK_DB.queueItems.find(qi => qi.id === attMatch[1]);
    if (!item) throw errorResponse(404, 'Item não encontrado.');
    item.status = 'atendido';
    item.finishedAt = new Date().toISOString();
    return { item };
  }

  // GET /api/users
  if (pathname === '/api/users' && method === 'GET') {
    const role = url.searchParams.get('role');
    let list = [...MOCK_DB.users];
    if (role) list = list.filter(u => u.role === role);
    return { users: list.sort((a, b) => a.name.localeCompare(b.name)) };
  }
  // POST /api/users
  if (pathname === '/api/users' && method === 'POST') {
    if (MOCK_DB.users.some(u => u.email.toLowerCase() === body.email.toLowerCase()))
      throw errorResponse(400, 'E-mail já cadastrado.');
    const user = {
      id: 'u_' + Date.now().toString(36),
      name: body.name, email: body.email, role: body.role,
      specialty: body.role === 'medico' ? body.specialty : undefined,
      unidade: body.role !== 'paciente' ? body.unidade : undefined,
      active: true, createdAt: new Date().toISOString(),
    };
    MOCK_DB.users.push(user);
    return { user };
  }
  // PATCH /api/users/:id
  const uMatch = pathname.match(/^\/api\/users\/([\w_]+)$/);
  if (uMatch && method === 'PATCH') {
    const u = MOCK_DB.users.find(u => u.id === uMatch[1]);
    if (!u) throw errorResponse(404, 'Usuário não encontrado.');
    if (typeof body.active === 'boolean') u.active = body.active;
    return { user: u };
  }

  // GET /api/reports
  if (pathname === '/api/reports' && method === 'GET') {
    const sessionId = url.searchParams.get('sessionId') || getActiveSession()?.id;
    const queueId = url.searchParams.get('queueId');
    let items = MOCK_DB.queueItems.filter(qi => qi.sessionId === sessionId);
    if (queueId) items = items.filter(qi => qi.queueId === queueId);
    const attended = items.filter(qi => qi.status === 'atendido');
    const absent = items.filter(qi => qi.status === 'ausente');
    return { report: {
      totalAttendances: attended.length,
      totalAbsent: absent.length,
      avgWaitMinutes: attended.length ? Math.round(attended.reduce((s, qi) => s + (qi.calledAt ? new Date(qi.calledAt) - new Date(qi.enteredAt) : 0), 0) / attended.length / 60000) : 0,
      avgServiceMinutes: attended.length ? Math.round(attended.reduce((s, qi) => s + (qi.attendedAt && qi.finishedAt ? new Date(qi.finishedAt) - new Date(qi.attendedAt) : 0), 0) / attended.length / 60000) : 0,
      byPriority: [
        { priority: 'prioritario', count: items.filter(qi => qi.priority === 'prioritario').length },
        { priority: 'comum', count: items.filter(qi => qi.priority === 'comum').length },
      ],
      byStatus: Object.entries(items.reduce((acc, qi) => { acc[qi.status] = (acc[qi.status] || 0) + 1; return acc; }, {})).map(([status, count]) => ({ status, count, label: STATUS_LABELS[status] })),
      byMedic: Array.from(MOCK_DB.users.filter(u => u.role === 'medico').map(m => {
        const mAttended = attended.filter(qi => qi.medicId === m.id);
        return { medicName: m.name, attendances: mAttended.length, avgMinutes: mAttended.length ? Math.round(mAttended.reduce((s, qi) => s + (qi.attendedAt && qi.finishedAt ? new Date(qi.finishedAt) - new Date(qi.attendedAt) : 0), 0) / mAttended.length / 60000) : 0 };
      })),
    }, metrics: computeMetrics(sessionId, queueId), session: MOCK_DB.sessions.find(s => s.id === sessionId) };
  }

  // GET /api/display
  if (pathname === '/api/display') {
    const session = getActiveSession();
    if (!session) return { session: null, settings: MOCK_DB.settings, lastCalled: [], waiting: [], perQueue: [] };
    const items = MOCK_DB.queueItems.filter(qi => qi.sessionId === session.id);
    const lastCalled = items
      .filter(qi => ['chamado', 'em_atendimento', 'atendido'].includes(qi.status))
      .sort((a, b) => new Date(b.calledAt || b.enteredAt) - new Date(a.calledAt || a.enteredAt))
      .slice(0, 4)
      .map(qi => ({ ...qi, patientName: findPatient(qi.patientId)?.name, queueName: session.queues.find(q => q.id === qi.queueId)?.name }));
    const waiting = items.filter(qi => qi.status === 'aguardando').map(qi => ({
      ...qi, patientName: findPatient(qi.patientId)?.name, queueName: session.queues.find(q => q.id === qi.queueId)?.name,
      position: positionInQueue(qi), estimatedWaitMinutes: estimateWait(qi),
    }));
    const perQueue = session.queues.map(q => {
      const qItems = items.filter(qi => qi.queueId === q.id);
      let current = qItems.find(qi => qi.status === 'chamado' || qi.status === 'em_atendimento');
      if (!current) {
        current = qItems
          .filter(qi => qi.calledAt || ['atendido', 'chamado', 'em_atendimento'].includes(qi.status))
          .sort((a, b) => new Date(b.calledAt || b.enteredAt) - new Date(a.calledAt || a.enteredAt))[0];
      }
      if (!current) {
        current = qItems.find(qi => qi.status === 'aguardando');
      }
      return { queue: q, waitingCount: qItems.filter(qi => qi.status === 'aguardando' && qi.id !== current?.id).length, current: current ? { ...current, patientName: findPatient(current.patientId)?.name } : null };
    });
    return { session, settings: MOCK_DB.settings, lastCalled, waiting, perQueue };
  }

  // GET /api/settings
  if (pathname === '/api/settings') return { settings: MOCK_DB.settings };
  // PATCH /api/settings
  if (pathname === '/api/settings' && method === 'PATCH') {
    Object.assign(MOCK_DB.settings, body);
    return { settings: MOCK_DB.settings };
  }

  // GET /api/queues - List all queues
  if (pathname === '/api/queues' && method === 'GET') {
    const queueMap = new Map();
    MOCK_DB.sessions.forEach(s => (s.queues || []).forEach(q => queueMap.set(q.id, q)));
    const queues = Array.from(queueMap.values());
    return { queues };
  }

  // POST /api/queues - Create a new queue
  if (pathname === '/api/queues' && method === 'POST') {
    const name = (body.name || '').trim();
    const sequencePrefix = (body.sequencePrefix || '').trim().toUpperCase();
    const avgServiceMinutes = parseInt(body.avgServiceMinutes, 10) || 15;

    if (!name) throw errorResponse(400, 'Nome da fila é obrigatório.');
    if (!sequencePrefix || sequencePrefix.length < 2) throw errorResponse(400, 'Prefixo deve ter pelo menos 2 caracteres.');

    // Check if prefix already exists
    const queueMap = new Map();
    MOCK_DB.sessions.forEach(s => (s.queues || []).forEach(q => queueMap.set(q.id, q)));
    const existing = Array.from(queueMap.values());
    if (existing.some(q => q.sequencePrefix === sequencePrefix)) {
      throw errorResponse(400, 'Já existe uma fila com este prefixo.');
    }

    const queue = {
      id: 'q_' + Date.now().toString(36),
      name,
      sequencePrefix,
      avgServiceMinutes,
    };

    // Add queue to all existing sessions
    MOCK_DB.sessions.forEach(s => {
      if (!s.queues) s.queues = [];
      s.queues.push({ ...queue });
    });

    return { queue };
  }

  // PATCH /api/queues/:id - Update a queue
  // DELETE /api/queues/:id - Delete a queue
  const queueMatch = pathname.match(/^\/api\/queues\/([\w_]+)$/);
  if (queueMatch && method === 'PATCH') {
    const queueId = queueMatch[1];
    const name = (body.name || '').trim();
    const sequencePrefix = (body.sequencePrefix || '').trim().toUpperCase();
    const avgServiceMinutes = parseInt(body.avgServiceMinutes, 10);

    // Find and update queue in all sessions
    let found = false;
    MOCK_DB.sessions.forEach(s => {
      const q = (s.queues || []).find(q => q.id === queueId);
      if (q) {
        found = true;
        if (name) q.name = name;
        if (sequencePrefix) q.sequencePrefix = sequencePrefix;
        if (avgServiceMinutes) q.avgServiceMinutes = avgServiceMinutes;
      }
    });

    if (!found) throw errorResponse(404, 'Fila não encontrada.');
    return { queue: { id: queueId, name, sequencePrefix, avgServiceMinutes } };
  }

  // DELETE /api/queues/:id - Delete a queue
  if (queueMatch && method === 'DELETE') {
    const queueId = queueMatch[1];

    // Remove queue from all sessions
    MOCK_DB.sessions.forEach(s => {
      if (s.queues) {
        s.queues = s.queues.filter(q => q.id !== queueId);
      }
    });

    return { ok: true };
  }

  throw errorResponse(404, `Endpoint não encontrado: ${method} ${pathname}`);
}

function currentUser(options) {
  const token = options.headers?.Authorization?.replace(/^Bearer\s+/i, '');
  if (!token) return null;
  let userId = MOCK_DB.tokens.get(token);
  if (!userId) {
    // MOCK_DB é recriado a cada navegação de página; recupera a sessão persistida
    // em localStorage (gravada por setSession em auth.js) para não perder o login.
    try {
      const session = JSON.parse(localStorage.getItem('filasus-auth') || 'null');
      if (session?.token === token && session.user) {
        userId = session.user.id;
        MOCK_DB.tokens.set(token, userId);
        if (session.patientId) MOCK_DB.tempUsers.set(userId, { user: session.user, patientId: session.patientId });
      }
    } catch { /* localStorage indisponível ou sessão corrompida */ }
  }
  return findUser(userId);
}
function computeMetrics(sessionId, queueId) {
  const items = MOCK_DB.queueItems.filter(qi => qi.sessionId === sessionId && (!queueId || qi.queueId === queueId));
  const waiting = items.filter(qi => qi.status === 'aguardando');
  const attended = items.filter(qi => qi.status === 'atendido');
  return {
    totalWaiting: waiting.length,
    totalPriority: waiting.filter(qi => qi.priority === 'prioritario').length,
    totalCommon: waiting.filter(qi => qi.priority === 'comum').length,
    totalCalled: items.filter(qi => qi.status === 'chamado' || qi.status === 'em_atendimento').length,
    totalAttended: attended.length,
    totalAbsent: items.filter(qi => qi.status === 'ausente').length,
    avgWaitMinutes: attended.length ? Math.round(attended.reduce((s, qi) => s + (qi.calledAt ? new Date(qi.calledAt) - new Date(qi.enteredAt) : 0), 0) / attended.length / 60000) : 0,
    avgServiceMinutes: avgService(sessionId, queueId),
  };
}
function errorResponse(status, message) {
  const err = new Error(message);
  err.status = status;
  return err;
}
