/* =========================================================================
 * FilaSUS — Auth
 * Gerencia a sessão do usuário no frontend (compatível com Servlets reais).
 * ========================================================================= */

const AUTH_KEY = 'filasus-auth';

/* ---------- Sessão ---------- */
function getSession() {
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
}
function setSession(session) {
  localStorage.setItem(AUTH_KEY, JSON.stringify(session));
}
function clearSession() {
  localStorage.removeItem(AUTH_KEY);
}
function getToken() {
  return getSession()?.token || null;
}
function getCurrentUser() {
  return getSession()?.user || null;
}
function getCurrentPatientId() {
  return getSession()?.patientId || null;
}
function isAuthenticated() {
  return !!getToken();
}

/* ---------- Interceptor de auth ---------- */
// Adiciona o token automaticamente em todas as chamadas api()
function authHeaders() {
  const token = getToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

/* ---------- Guards de página ---------- */
function requireAuth() {
  if (!isAuthenticated()) {
    redirectTo('login.jsp');
    return false;
  }
  return true;
}
function requireRole(...roles) {
  if (!requireAuth()) return false;
  const user = getCurrentUser();
  if (!roles.includes(user.role)) {
    toast('Você não tem permissão para acessar esta página.', 'error');
    redirectTo('login.jsp');
    return false;
  }
  return true;
}

/* ---------- Login / Logout ---------- */
async function login(email, password, role) {
  const session = await api('/api/auth', { method: 'POST', body: { email, password, role } });
  if (session.user) setSession(session);
  return session;
}
async function logout() {
  try { await api('/api/auth', { method: 'DELETE' }); } catch {}
  clearSession();
  localStorage.removeItem('filasus_patientId');
  // Sobe um nível para chegar em /jsp/login.jsp (páginas internas estão em /jsp/{role}/)
  const basePath = window.__JSP_BASE_PATH__ || '../';
  redirectTo(`${basePath}login.jsp`);
}

/* ---------- Override do api() para incluir token ---------- */
// Reescreve api() de utils.js para incluir o header Authorization
const _originalApi = api;
api = async function(path, options = {}) {
  const opts = { ...options, headers: { ...authHeaders(), ...(options.headers || {}) } };
  return _originalApi(path, opts);
};
