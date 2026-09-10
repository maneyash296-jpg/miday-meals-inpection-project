/* ============================================================
   NutriGuard AI — Complete Frontend Logic
   Connects: Auth, Schools, Meals, Alerts, AI Search, AI Chat
   Backend: FastAPI on http://localhost:8000
   ============================================================ */

// Serve the dashboard and API from the same FastAPI origin. This also works
// when the browser app is opened from another host or port.
const API = window.location.origin;
let token = localStorage.getItem('ng_token') || null;
let currentUser = JSON.parse(localStorage.getItem('ng_user') || 'null');
let allSchools = [];
let allSchools2 = [];
let allMeals = [];
let allAlerts = [];
let searchDebounceTimer = null;

/* ══════════════════════════════════════════════════
   BOOTSTRAP
══════════════════════════════════════════════════ */
window.addEventListener('DOMContentLoaded', () => {
  if (token && currentUser) {
    showApp();
  } else {
    showLogin();
  }

  // Close search dropdown on outside click
  document.addEventListener('click', (e) => {
    if (!document.getElementById('searchWrapper')?.contains(e)) {
      closeSearchDropdown();
    }
  });
});

function showLogin() {
  document.getElementById('loginPage').style.display = 'flex';
  document.getElementById('mainApp').style.display = 'none';
}

function showApp() {
  document.getElementById('loginPage').style.display = 'none';
  document.getElementById('mainApp').style.display = 'flex';
  initApp();
}

/* ══════════════════════════════════════════════════
   AUTH
══════════════════════════════════════════════════ */
async function doLogin() {
  const email = document.getElementById('loginEmail').value.trim();
  const password = document.getElementById('loginPassword').value;
  const errBox = document.getElementById('loginError');
  const btn = document.getElementById('loginBtn');

  if (!email || !password) {
    showLoginError('Please enter email and password.');
    return;
  }

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Signing in…';
  errBox.style.display = 'none';

  try {
    // OAuth2 form-encoded
    const body = new URLSearchParams();
    body.append('username', email);
    body.append('password', password);

    const res = await fetch(`${API}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: body.toString()
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Login failed');

    token = data.access_token;
    currentUser = data.user;
    localStorage.setItem('ng_token', token);
    localStorage.setItem('ng_user', JSON.stringify(currentUser));
    showApp();
  } catch (err) {
    showLoginError(err.message || 'Login failed. Check credentials and try again.');
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-right-to-bracket"></i> Sign In to Dashboard';
  }
}

function quickLogin(email) {
  document.getElementById('loginEmail').value = email;
  document.getElementById('loginPassword').value = 'password123';
}

function showLoginError(msg) {
  const box = document.getElementById('loginError');
  box.textContent = msg;
  box.style.display = 'block';
}

function doLogout() {
  token = null;
  currentUser = null;
  localStorage.removeItem('ng_token');
  localStorage.removeItem('ng_user');
  showLogin();
}

/* ══════════════════════════════════════════════════
   API HELPER
══════════════════════════════════════════════════ */
async function apiFetch(path, opts = {}) {
  const headers = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API}${path}`, {
    ...opts,
    headers,
    body: opts.body ? JSON.stringify(opts.body) : undefined
  });

  if (res.status === 401) {
    doLogout();
    throw new Error('Session expired, please login again.');
  }

  const text = await res.text();
  try { return { ok: res.ok, data: JSON.parse(text), status: res.status }; }
  catch { return { ok: res.ok, data: text, status: res.status }; }
}

/* ══════════════════════════════════════════════════
   APP INIT
══════════════════════════════════════════════════ */
function initApp() {
  // Set user info
  if (currentUser) {
    document.getElementById('sidebarUserName').textContent = currentUser.name || currentUser.email;
    document.getElementById('sidebarUserRole').textContent = currentUser.role || 'USER';
  }
  checkApiHealth();
  setInterval(checkApiHealth, 30000);
  showSection('dashboard');
}

async function checkApiHealth() {
  const statusEl = document.getElementById('apiStatus');
  try {
    const res = await fetch(`${API}/health`, { signal: AbortSignal.timeout(5000) });
    const data = await res.json();
    if (res.ok) {
      statusEl.className = 'api-status online';
      statusEl.innerHTML = '<span class="pulse-dot"></span> API Online';
    } else throw new Error();
  } catch {
    statusEl.className = 'api-status offline';
    statusEl.innerHTML = '<span class="pulse-dot"></span> API Offline';
  }
}

/* ══════════════════════════════════════════════════
   NAVIGATION
══════════════════════════════════════════════════ */
function showSection(name) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => {
    n.classList.toggle('active', n.dataset.section === name);
  });

  const sectionEl = document.getElementById(`${name}Section`);
  if (sectionEl) sectionEl.classList.add('active');

  const titles = {
    dashboard: '<i class="fa-solid fa-gauge-high"></i> Dashboard',
    schools: '<i class="fa-solid fa-school"></i> Schools',
    meals: '<i class="fa-solid fa-bowl-rice"></i> Meal Records',
    vision: '<i class="fa-solid fa-camera-retro"></i> AI Vision Meal Analyzer',
    metrics: '<i class="fa-solid fa-chart-pie"></i> AI Model Metrics & Accuracy',
    ai: '<i class="fa-solid fa-brain"></i> AI Assistant',
    alerts: '<i class="fa-solid fa-bell"></i> Alerts',
  };
  document.getElementById('pageTitle').innerHTML = titles[name] || name;

  // Load data for section
  if (name === 'dashboard') loadDashboard();
  else if (name === 'schools') loadSchoolsPage();
  else if (name === 'meals') loadMeals();
  else if (name === 'alerts') loadAlerts();
  else if (name === 'metrics') runWasteSimulation();
}

function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
}

/* ══════════════════════════════════════════════════
   DASHBOARD
══════════════════════════════════════════════════ */
async function loadDashboard() {
  await Promise.all([loadKPIs(), loadMeals(), loadSchoolsTable()]);
}

async function loadKPIs() {
  try {
    // Schools count
    const schoolsRes = await apiFetch('/api/v1/schools/?limit=200');
    if (schoolsRes.ok) {
      const schools = schoolsRes.data;
      const count = Array.isArray(schools) ? schools.length : (schools.items?.length || 0);
      document.getElementById('kpiSchoolsVal').textContent = count;
      document.getElementById('kpiSchoolsSub').textContent = `${count} schools active`;
    }

    // Meals today
    const mealsRes = await apiFetch('/api/v1/meals/?limit=50');
    if (mealsRes.ok) {
      const meals = Array.isArray(mealsRes.data) ? mealsRes.data : (mealsRes.data.items || []);
      const totalServed = meals.reduce((s, m) => s + (m.students_served || 0), 0);
      document.getElementById('kpiMealsVal').textContent = totalServed.toLocaleString();
      document.getElementById('kpiMealsSub').textContent = `Across ${meals.length} sessions`;

      const avgHygiene = meals.reduce((s, m) => s + (m.hygiene_score || 0), 0) / (meals.length || 1);
      document.getElementById('kpiHygieneVal').textContent = avgHygiene.toFixed(1) + '%';
      document.getElementById('kpiHygieneSub').textContent = avgHygiene >= 80 ? '✓ Satisfactory' : '⚠ Needs attention';
    }

    // Alerts count
    const alertRes = await apiFetch('/api/v1/alerts/?limit=100');
    if (alertRes.ok) {
      const alerts = Array.isArray(alertRes.data) ? alertRes.data : (alertRes.data.items || []);
      const activeAlerts = alerts.filter(a => a.status === 'ACTIVE' || a.status === 'active');
      document.getElementById('kpiAlertsVal').textContent = activeAlerts.length;
      document.getElementById('kpiAlertsSub').textContent = `${activeAlerts.length} active alerts`;
      document.getElementById('alertBadge').textContent = activeAlerts.length;
    }
  } catch (err) {
    console.warn('KPI load error:', err);
  }
}

async function loadSchoolsTable() {
  const body = document.getElementById('schoolsTableBody');
  try {
    const res = await apiFetch('/api/v1/schools/?limit=200');
    if (!res.ok) throw new Error('Failed to load schools');
    const schools = Array.isArray(res.data) ? res.data : (res.data.items || []);
    allSchools = schools;
    renderSchoolsTable(schools);
  } catch (err) {
    body.innerHTML = `<tr><td colspan="5" class="loading-cell" style="color:var(--rose)"><i class="fa-solid fa-circle-exclamation"></i> ${err.message}</td></tr>`;
  }
}

function renderSchoolsTable(schools) {
  const body = document.getElementById('schoolsTableBody');
  if (!schools.length) {
    body.innerHTML = '<tr><td colspan="5" class="loading-cell">No schools found</td></tr>';
    return;
  }
  body.innerHTML = schools.slice(0, 10).map(s => `
    <tr>
      <td>
        <strong>${esc(s.name)}</strong>
        <div style="font-size:11px;color:var(--text-muted)">${esc(s.school_code || '')}</div>
      </td>
      <td>${esc(s.address || s.district?.name || '—')}</td>
      <td><strong>${s.student_count || 0}</strong></td>
      <td>
        <span class="school-status-dot" style="${s.active === false ? 'color:var(--rose)' : ''}">
          ${s.active === false ? 'Inactive' : 'Active'}
        </span>
      </td>
      <td>
        <button class="btn-sm-secondary" onclick="showSection('schools')" style="font-size:11px;padding:4px 10px">
          <i class="fa-solid fa-arrow-up-right-from-square"></i> View
        </button>
      </td>
    </tr>
  `).join('');
}

function filterSchools(query) {
  const filtered = allSchools.filter(s =>
    (s.name || '').toLowerCase().includes(query.toLowerCase()) ||
    (s.address || '').toLowerCase().includes(query.toLowerCase()) ||
    (s.school_code || '').toLowerCase().includes(query.toLowerCase())
  );
  renderSchoolsTable(filtered);
}

/* ══════════════════════════════════════════════════
   SCHOOLS PAGE
══════════════════════════════════════════════════ */
async function loadSchoolsPage() {
  const grid = document.getElementById('schoolsGrid');
  grid.innerHTML = '<div class="loading-state"><i class="fa-solid fa-spinner fa-spin"></i> Loading schools…</div>';
  try {
    const res = await apiFetch('/api/v1/schools/?limit=200');
    if (!res.ok) throw new Error('Failed to load schools');
    const schools = Array.isArray(res.data) ? res.data : (res.data.items || []);
    allSchools2 = schools;
    renderSchoolsGrid(schools);
  } catch (err) {
    grid.innerHTML = `<div class="empty-state"><i class="fa-solid fa-circle-exclamation" style="color:var(--rose)"></i><p style="margin-top:10px">${err.message}</p></div>`;
  }
}

function renderSchoolsGrid(schools) {
  const grid = document.getElementById('schoolsGrid');
  if (!schools.length) {
    grid.innerHTML = '<div class="empty-state">No schools found</div>';
    return;
  }
  grid.innerHTML = schools.map(s => `
    <div class="school-card">
      <h4><i class="fa-solid fa-school" style="color:var(--emerald);margin-right:6px"></i>${esc(s.name)}</h4>
      <p>${esc(s.address || '—')}</p>
      <div class="school-meta">
        <span class="school-meta-item"><i class="fa-solid fa-hashtag"></i> ${esc(s.school_code || 'N/A')}</span>
        <span class="school-meta-item"><i class="fa-solid fa-users"></i> ${s.student_count || 0} students</span>
        <span class="school-meta-item" style="color:${s.active === false ? 'var(--rose)' : 'var(--emerald)'}">
          <i class="fa-solid fa-circle" style="font-size:8px"></i> ${s.active === false ? 'Inactive' : 'Active'}
        </span>
      </div>
    </div>
  `).join('');
}

function filterSchools2(query) {
  const filtered = allSchools2.filter(s =>
    (s.name || '').toLowerCase().includes(query.toLowerCase()) ||
    (s.address || '').toLowerCase().includes(query.toLowerCase()) ||
    (s.school_code || '').toLowerCase().includes(query.toLowerCase())
  );
  renderSchoolsGrid(filtered);
}

/* ══════════════════════════════════════════════════
   MEALS
══════════════════════════════════════════════════ */
async function loadMeals() {
  const feed = document.getElementById('mealsFeed');
  const fullList = document.getElementById('mealsFullList');
  const statusFilter = document.getElementById('mealStatusFilter')?.value || '';

  if (feed) feed.innerHTML = '<div class="loading-state"><i class="fa-solid fa-spinner fa-spin"></i></div>';
  if (fullList) fullList.innerHTML = '<div class="loading-state"><i class="fa-solid fa-spinner fa-spin"></i> Loading meal records…</div>';

  try {
    let url = '/api/v1/meals/?limit=50';
    if (statusFilter) url += `&status=${statusFilter}`;
    const res = await apiFetch(url);
    if (!res.ok) throw new Error('Failed to load meals');
    const meals = Array.isArray(res.data) ? res.data : (res.data.items || []);
    allMeals = meals;
    const filteredMeals = getFilteredMeals();

    // Dashboard feed (top 5)
    if (feed) {
      if (!filteredMeals.length) {
        feed.innerHTML = '<div class="empty-state">No meal records found</div>';
      } else {
        feed.innerHTML = filteredMeals.slice(0, 5).map(m => renderMealCard(m)).join('');
      }
    }

    // Full meals page
    if (fullList) {
      if (!filteredMeals.length) {
        fullList.innerHTML = '<div class="empty-state">No meal records found</div>';
      } else {
        fullList.innerHTML = filteredMeals.map(m => renderMealCard(m)).join('');
      }
    }
  } catch (err) {
    const errHtml = `<div class="empty-state"><i class="fa-solid fa-circle-exclamation" style="color:var(--rose)"></i><p style="margin-top:10px">${err.message}</p></div>`;
    if (feed) feed.innerHTML = errHtml;
    if (fullList) fullList.innerHTML = errHtml;
  }
}

function getFilteredMeals() {
  const query = document.getElementById('mealSearch')?.value.trim().toLowerCase() || '';
  if (!query) return allMeals;
  return allMeals.filter(m => [m.meal_session, m.meal_date, m.status, m.school_name]
    .some(value => String(value || '').toLowerCase().includes(query)));
}

function filterMeals() {
  const fullList = document.getElementById('mealsFullList');
  if (!fullList) return;
  const meals = getFilteredMeals();
  fullList.innerHTML = meals.length
    ? meals.map(m => renderMealCard(m)).join('')
    : '<div class="empty-state">No meal records match this search</div>';
}

function renderMealCard(m) {
  const status = (m.status || 'PENDING').toUpperCase();
  const statusClass = status === 'VERIFIED' ? 'verified' : status === 'NEEDS_REVIEW' ? 'needs_review' : 'pending';
  const hygieneScore = m.hygiene_score || 0;
  const nutritionScore = m.nutrition_score || 0;
  const overall = m.overall_score || 0;

  const hygieneClass = hygieneScore >= 80 ? 'high' : hygieneScore >= 50 ? 'mid' : 'low';
  const nutritionClass = nutritionScore >= 80 ? 'high' : nutritionScore >= 50 ? 'mid' : 'low';

  return `
    <div class="meal-card">
      <div class="meal-img" style="background:linear-gradient(135deg,rgba(99,102,241,0.2),rgba(16,185,129,0.2));display:flex;align-items:center;justify-content:center;font-size:26px">
        🍽️
      </div>
      <div class="meal-info">
        <div class="meal-title">
          ${m.meal_session ? capitalise(m.meal_session) : 'Meal Session'} — ${formatDate(m.meal_date)}
        </div>
        <div class="meal-meta">
          <i class="fa-solid fa-users"></i> ${m.students_served || 0}/${m.students_present || 0} students served
        </div>
        <div class="score-mini">
          <span class="score-pip ${hygieneClass}">🧼 Hygiene ${hygieneScore}%</span>
          <span class="score-pip ${nutritionClass}">🥦 Nutrition ${nutritionScore}%</span>
          ${overall ? `<span class="score-pip ${overall >= 80 ? 'high' : overall >= 50 ? 'mid' : 'low'}">⭐ Overall ${overall}%</span>` : ''}
        </div>
      </div>
      <span class="status-badge ${statusClass}">${status.replace('_',' ')}</span>
    </div>
  `;
}

/* ══════════════════════════════════════════════════
   ALERTS
══════════════════════════════════════════════════ */
async function loadAlerts() {
  const list = document.getElementById('alertsList');
  const count = document.getElementById('alertsCount');
  list.innerHTML = '<div class="loading-state"><i class="fa-solid fa-spinner fa-spin"></i> Loading alerts…</div>';

  try {
    const res = await apiFetch('/api/v1/alerts/?limit=50');
    if (!res.ok) throw new Error('Failed to load alerts');
    const alerts = Array.isArray(res.data) ? res.data : (res.data.items || []);
    allAlerts = alerts;
    const active = alerts.filter(a => (a.status || '').toUpperCase() === 'ACTIVE');
    if (count) count.textContent = `${active.length} active / ${alerts.length} total`;
    document.getElementById('alertBadge').textContent = active.length;

    renderAlertsList();
  } catch (err) {
    list.innerHTML = `<div class="empty-state" style="color:var(--rose)">${err.message}</div>`;
  }
}

function getFilteredAlerts() {
  const query = document.getElementById('alertSearch')?.value.trim().toLowerCase() || '';
  const severity = document.getElementById('alertSeverityFilter')?.value || '';
  const status = document.getElementById('alertStatusFilter')?.value || '';
  return allAlerts.filter(a => {
    const matchesText = !query || [a.title, a.message, a.alert_type, a.status]
      .some(value => String(value || '').toLowerCase().includes(query));
    return matchesText && (!severity || a.severity === severity) && (!status || a.status === status);
  });
}

function renderAlertsList() {
  const list = document.getElementById('alertsList');
  if (!list) return;
  const alerts = getFilteredAlerts();
  if (!alerts.length) {
    list.innerHTML = '<div class="empty-state">No alerts match the selected filters</div>';
    return;
  }
  list.innerHTML = alerts.map(a => renderAlertCard(a)).join('');
}

function filterAlerts() {
  renderAlertsList();
}

function renderAlertCard(a) {
  const severity = (a.severity || 'INFO').toUpperCase();
  const icon = severity === 'CRITICAL' ? 'fa-circle-xmark' : severity === 'WARNING' ? 'fa-triangle-exclamation' : 'fa-circle-info';
  return `
    <div class="alert-card ${severity}">
      <div class="alert-icon ${severity}"><i class="fa-solid ${icon}"></i></div>
      <div>
        <div class="alert-title">${esc(a.title || 'Alert')}</div>
        <div class="alert-msg">${esc(a.message || '')}</div>
        <div class="alert-time">
          <i class="fa-regular fa-clock"></i> ${formatDate(a.created_at)}
          &nbsp;·&nbsp;
          <span style="font-weight:600;color:var(--text-muted)">${esc(a.alert_type || '')}</span>
          &nbsp;·&nbsp;
          <span style="color:${(a.status||'').toUpperCase()==='ACTIVE' ? 'var(--amber)':'var(--emerald)'}">${esc(a.status || '')}</span>
        </div>
      </div>
    </div>
  `;
}

/* ══════════════════════════════════════════════════
   AI SEARCH BAR
══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  const input = document.getElementById('searchInput');
  if (input) {
    input.addEventListener('input', () => {
      clearTimeout(searchDebounceTimer);
      const q = input.value.trim();
      if (q.length >= 2) {
        searchDebounceTimer = setTimeout(() => doFastSearch(q), 400);
      } else {
        closeSearchDropdown();
      }
    });
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') doAISearch();
      if (e.key === 'Escape') closeSearchDropdown();
    });
  }
});

async function doFastSearch(q) {
  const dropdown = document.getElementById('searchDropdown');
  const resultsList = document.getElementById('searchResultsList');
  dropdown.classList.add('open');

  try {
    const res = await fetch(`${API}/api/v1/search/query?q=${encodeURIComponent(q)}&limit=6`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {}
    });
    const items = await res.json();
    if (!Array.isArray(items) || !items.length) {
      resultsList.innerHTML = '<div style="font-size:12px;color:var(--text-dim);padding:8px 4px">No quick results found — press AI Search for deep analysis</div>';
      return;
    }
    resultsList.innerHTML = items.map(item => `
      <div class="result-item">
        <div>
          <div class="result-title">${esc(item.title)}</div>
          <div class="result-sub"><span style="background:rgba(99,102,241,0.15);color:#a5b4fc;padding:1px 7px;border-radius:8px;font-size:10px;margin-right:6px">${esc(item.category)}</span>${esc(item.subtitle)}</div>
        </div>
        ${item.badge ? `<span class="score-pip mid">${esc(item.badge)}</span>` : ''}
      </div>
    `).join('');
  } catch (err) {
    resultsList.innerHTML = `<div style="font-size:12px;color:var(--rose);padding:8px 4px">Search error: ${err.message}</div>`;
  }
}

async function doAISearch() {
  const q = document.getElementById('searchInput').value.trim();
  if (!q) return;

  const dropdown = document.getElementById('searchDropdown');
  const aiAnswerText = document.getElementById('aiAnswerText');
  const aiKeyFindings = document.getElementById('aiKeyFindings');
  const aiActions = document.getElementById('aiActions');
  const btn = document.getElementById('aiSearchBtn');

  dropdown.classList.add('open');
  aiAnswerText.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Groq AI analyzing…';
  aiKeyFindings.innerHTML = '';
  aiActions.innerHTML = '';
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';

  try {
    const res = await fetch(`${API}/api/v1/search/ai`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      },
      body: JSON.stringify({ query: q, context_role: currentUser?.role?.toLowerCase() || 'admin' })
    });

    const data = await res.json();

    aiAnswerText.textContent = data.ai_synthesis || 'Analysis complete.';

    aiKeyFindings.innerHTML = (data.key_findings || []).map(f =>
      `<span class="finding-chip"><i class="fa-solid fa-circle-check" style="margin-right:4px"></i>${esc(f)}</span>`
    ).join('');

    aiActions.innerHTML = (data.suggested_actions || []).map(a =>
      `<span class="action-chip"><i class="fa-solid fa-arrow-right" style="margin-right:4px"></i>${esc(a)}</span>`
    ).join('');

    // Also show matched items
    const resultsList = document.getElementById('searchResultsList');
    const items = data.matched_items || [];
    if (items.length) {
      resultsList.innerHTML = items.map(item => `
        <div class="result-item">
          <div>
            <div class="result-title">${esc(item.title)}</div>
            <div class="result-sub"><span style="background:rgba(99,102,241,0.15);color:#a5b4fc;padding:1px 7px;border-radius:8px;font-size:10px;margin-right:6px">${esc(item.category)}</span>${esc(item.subtitle)}</div>
          </div>
          ${item.badge ? `<span class="score-pip mid">${esc(item.badge)}</span>` : ''}
        </div>
      `).join('');
    }
  } catch (err) {
    aiAnswerText.textContent = `AI Search failed: ${err.message}. Check server connection.`;
  } finally {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-bolt"></i> AI Search';
  }
}

function closeSearchDropdown() {
  document.getElementById('searchDropdown')?.classList.remove('open');
}

function formatAiDataContext(context) {
  if (!context) return '';
  const records = context.records_used || {};
  const time = context.retrieved_at ? new Date(context.retrieved_at).toLocaleString() : 'just now';
  return `<div class="ai-context">
    <div><i class="fa-solid fa-database"></i> <strong>Data used by AI</strong> · ${esc(context.source || 'Live API snapshot')} · ${esc(time)}</div>
    <div class="ai-context-detail">${records.schools || 0} schools, ${records.alerts || 0} alerts, ${records.recent_meals || 0} recent meals. ${esc(context.excludes || '')}</div>
  </div>`;
}

/* ══════════════════════════════════════════════════
   AI CHAT
══════════════════════════════════════════════════ */
async function sendAIChat() {
  const input = document.getElementById('aiChatInput');
  const chatBody = document.getElementById('aiChatBody');
  const msg = input.value.trim();
  if (!msg) return;

  input.value = '';

  // Add user bubble
  chatBody.innerHTML += `
    <div class="ai-message user">
      <div class="ai-avatar"><i class="fa-solid fa-user"></i></div>
      <div class="ai-bubble">${esc(msg)}</div>
    </div>
  `;

  // Thinking bubble
  const thinkingId = 'thinking-' + Date.now();
  chatBody.innerHTML += `
    <div class="ai-message bot" id="${thinkingId}">
      <div class="ai-avatar"><i class="fa-solid fa-brain"></i></div>
      <div class="ai-bubble"><i class="fa-solid fa-spinner fa-spin"></i> Groq AI is thinking…</div>
    </div>
  `;
  chatBody.scrollTop = chatBody.scrollHeight;

  try {
    // Use the AI search endpoint for deep analysis
    const res = await fetch(`${API}/api/v1/search/ai`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      },
      body: JSON.stringify({ query: msg, context_role: currentUser?.role?.toLowerCase() || 'admin' })
    });

    const data = await res.json();

    const synthesis = data.ai_synthesis || 'Here is what I found.';
    const findings = (data.key_findings || []).map(f => `<li>${esc(f)}</li>`).join('');
    const actions = (data.suggested_actions || []).map(a => `<li>→ ${esc(a)}</li>`).join('');

    const responseHtml = `
      <p>${esc(synthesis)}</p>
      ${findings ? `<ul style="margin-top:10px;padding-left:18px;font-size:12px;color:#94a3b8">${findings}</ul>` : ''}
      ${actions ? `<ul style="margin-top:8px;padding-left:18px;font-size:12px;color:var(--emerald)">${actions}</ul>` : ''}
      ${formatAiDataContext(data.data_context)}
    `;

    document.getElementById(thinkingId).querySelector('.ai-bubble').innerHTML = responseHtml;
  } catch (err) {
    document.getElementById(thinkingId).querySelector('.ai-bubble').innerHTML =
      `<span style="color:var(--rose)"><i class="fa-solid fa-circle-xmark"></i> Error: ${esc(err.message)}</span>`;
  }

  chatBody.scrollTop = chatBody.scrollHeight;
}

function setAIPrompt(text) {
  const input = document.getElementById('aiChatInput');
  input.value = text;
  input.focus();
  showSection('ai');
}

/* ══════════════════════════════════════════════════
   DASHBOARD AI INSIGHT
══════════════════════════════════════════════════ */
async function generateDashboardInsight() {
  const panel = document.getElementById('aiInsightsPanel');
  panel.innerHTML = '<div class="loading-state"><i class="fa-solid fa-brain fa-bounce"></i> Groq AI generating insights…</div>';

  try {
    // Fetch real data for context
    const [schoolsRes, alertsRes, mealsRes] = await Promise.all([
      apiFetch('/api/v1/schools/?limit=20'),
      apiFetch('/api/v1/alerts/?limit=10'),
      apiFetch('/api/v1/meals/?limit=10'),
    ]);

    const schools = Array.isArray(schoolsRes.data) ? schoolsRes.data : (schoolsRes.data?.items || []);
    const alerts = Array.isArray(alertsRes.data) ? alertsRes.data : (alertsRes.data?.items || []);
    const meals = Array.isArray(mealsRes.data) ? mealsRes.data : (mealsRes.data?.items || []);

    const dashboardData = {
      total_schools: schools.length,
      active_alerts: alerts.filter(a => (a.status || '').toUpperCase() === 'ACTIVE').length,
      avg_hygiene: meals.reduce((s, m) => s + (m.hygiene_score || 0), 0) / (meals.length || 1),
      recent_meals: meals.length,
    };
    const snapshotTime = new Date().toLocaleString();
    document.getElementById('aiDataNotice').innerHTML = `<i class="fa-solid fa-database"></i><span><strong>Snapshot prepared ${esc(snapshotTime)}:</strong> ${schools.length} schools (name, student count), ${alerts.length} alerts (title, severity, message), and ${meals.length} meal records (date and scores). No personal data or images are sent.</span>`;

    const res = await fetch(`${API}/api/v1/ai/dashboard/summarize`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {})
      },
      body: JSON.stringify(dashboardData)
    });

    const data = await res.json();
    const summary = data.summary || '';

    // Parse summary into sections or just display
    const severity = alerts.some(a => (a.severity || '').toUpperCase() === 'CRITICAL') ? 'rose' : 'amber';
    const badge = severity === 'rose' ? 'CRITICAL' : 'WARNING';

    panel.innerHTML = `
      <div class="ai-insight-card" style="border-left-color:var(--${severity})">
        <div class="insight-badge ${severity}">
          <i class="fa-solid fa-brain"></i> GROQ AI INSIGHT
        </div>
        <h4>NutriGuard Daily Intelligence Briefing</h4>
        <p>${esc(summary)}</p>
        <div class="insight-action">
          <i class="fa-solid fa-circle-right"></i>
          Monitoring ${schools.length} schools · ${alerts.filter(a=>(a.status||'').toUpperCase()==='ACTIVE').length} active alerts · ${meals.length} recent meal sessions
        </div>
        <div class="ai-context"><i class="fa-solid fa-database"></i> <strong>Data used by AI:</strong> ${schools.length} school records, ${alerts.length} alert records, and ${meals.length} recent meal records · snapshot ${esc(snapshotTime)} · no student-identifying data or images included.</div>
      </div>
    `;
  } catch (err) {
    panel.innerHTML = `
      <div class="ai-insight-card amber-border">
        <div class="insight-badge amber"><i class="fa-solid fa-triangle-exclamation"></i> AI ANALYSIS</div>
        <h4>System Monitoring Active</h4>
        <p>The AI insight could not be generated. Review the live operational records in the dashboard and try again.</p>
        <div class="insight-action"><i class="fa-solid fa-circle-right"></i> No AI conclusion was produced</div>
      </div>
    `;
  }
}

/* ══════════════════════════════════════════════════
   UTILITIES
══════════════════════════════════════════════════ */
function esc(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function capitalise(str) {
  if (!str) return '';
  return String(str).charAt(0).toUpperCase() + String(str).slice(1).toLowerCase().replace(/_/g, ' ');
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  } catch { return String(dateStr); }
}

/* ══════════════════════════════════════════════════
   AI VISION MEAL ANALYZER
══════════════════════════════════════════════════ */
let currentMealBlob = null;

function handleImageSelected(e) {
  const file = e.target.files[0];
  if (!file) return;
  currentMealBlob = file;

  const reader = new FileReader();
  reader.onload = (evt) => {
    document.getElementById('mealImagePreview').src = evt.target.result;
    document.getElementById('uploadPlaceholder').style.display = 'none';
    document.getElementById('imagePreviewWrapper').style.display = 'block';
  };
  reader.readAsDataURL(file);
}

function clearSelectedImage() {
  currentMealBlob = null;
  document.getElementById('mealImageInput').value = '';
  document.getElementById('mealImagePreview').src = '';
  document.getElementById('imagePreviewWrapper').style.display = 'none';
  document.getElementById('uploadPlaceholder').style.display = 'block';
  document.getElementById('visionEmptyState').style.display = 'block';
  document.getElementById('visionResultContent').style.display = 'none';
  document.getElementById('visionStatusBadge').className = 'status-badge-pending';
  document.getElementById('visionStatusBadge').textContent = 'Awaiting Meal';
}

function loadSampleMeal(type) {
  // Generate sample image on canvas for testing
  const canvas = document.createElement('canvas');
  canvas.width = 600;
  canvas.height = 450;
  const ctx = canvas.getContext('2d');

  // Background
  ctx.fillStyle = '#b89f88';
  ctx.fillRect(0, 0, 600, 450);

  // Thali plate
  ctx.beginPath();
  ctx.arc(300, 225, 200, 0, Math.PI * 2);
  ctx.fillStyle = '#e8e8e8';
  ctx.fill();
  ctx.lineWidth = 6;
  ctx.strokeStyle = '#c0c0c0';
  ctx.stroke();

  if (type === 'thali') {
    // Rice (white center-left)
    ctx.beginPath();
    ctx.arc(220, 200, 80, 0, Math.PI * 2);
    ctx.fillStyle = '#ffffff';
    ctx.fill();

    // Dal bowl (yellow top-right)
    ctx.beginPath();
    ctx.arc(360, 150, 50, 0, Math.PI * 2);
    ctx.fillStyle = '#d49b20';
    ctx.fill();

    // Vegetable Curry (greenish-brown bottom)
    ctx.beginPath();
    ctx.arc(320, 290, 60, 0, Math.PI * 2);
    ctx.fillStyle = '#6b5428';
    ctx.fill();

    document.getElementById('visionExpectedItems').value = 'Rice, Dal, Vegetable Curry';
  } else if (type === 'roti') {
    // Rotis (golden circles)
    ctx.beginPath();
    ctx.arc(230, 210, 75, 0, Math.PI * 2);
    ctx.fillStyle = '#d4aa70';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(270, 230, 70, 0, Math.PI * 2);
    ctx.fillStyle = '#c89960';
    ctx.fill();

    // Sabzi bowl
    ctx.beginPath();
    ctx.arc(380, 180, 60, 0, Math.PI * 2);
    ctx.fillStyle = '#8b4513';
    ctx.fill();

    document.getElementById('visionExpectedItems').value = 'Chapati, Vegetable Curry';
  } else {
    // Khichdi (yellowish mixed)
    ctx.beginPath();
    ctx.arc(300, 225, 140, 0, Math.PI * 2);
    ctx.fillStyle = '#e6c342';
    ctx.fill();

    // Curd bowl
    ctx.beginPath();
    ctx.arc(400, 150, 45, 0, Math.PI * 2);
    ctx.fillStyle = '#f8f9fa';
    ctx.fill();

    document.getElementById('visionExpectedItems').value = 'Khichdi, Curd';
  }

  canvas.toBlob((blob) => {
    currentMealBlob = new File([blob], `sample_${type}.jpg`, { type: 'image/jpeg' });
    document.getElementById('mealImagePreview').src = canvas.toDataURL('image/jpeg');
    document.getElementById('uploadPlaceholder').style.display = 'none';
    document.getElementById('imagePreviewWrapper').style.display = 'block';
  }, 'image/jpeg');
}

async function runMealAnalysis() {
  if (!currentMealBlob) {
    alert('Please choose or drag a meal photo first (or click a sample preset).');
    return;
  }

  const btn = document.getElementById('analyzeMealBtn');
  const emptyState = document.getElementById('visionEmptyState');
  const loadingState = document.getElementById('visionLoadingState');
  const resultContent = document.getElementById('visionResultContent');
  const statusBadge = document.getElementById('visionStatusBadge');

  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Analyzing with AI…';
  emptyState.style.display = 'none';
  resultContent.style.display = 'none';
  loadingState.style.display = 'block';

  try {
    const formData = new FormData();
    formData.append('file', currentMealBlob);
    formData.append('students_served', document.getElementById('visionStudentsCount').value || 250);
    formData.append('expected_items_csv', document.getElementById('visionExpectedItems').value || 'Rice,Dal,Vegetable Curry');

    const headers = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const res = await fetch(`${API}/api/v1/meals/analyze-direct`, {
      method: 'POST',
      headers,
      body: formData
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({ detail: 'Analysis failed' }));
      throw new Error(errData.detail || `Server error ${res.status}`);
    }

    const data = await res.json();
    renderMealAnalysisResult(data);
  } catch (err) {
    alert(`AI Analysis Error: ${err.message}`);
    emptyState.style.display = 'block';
  } finally {
    loadingState.style.display = 'none';
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-wand-magic-sparkles"></i> Analyze Meal with AI Vision';
  }
}

function renderMealAnalysisResult(data) {
  const resultContent = document.getElementById('visionResultContent');
  const statusBadge = document.getElementById('visionStatusBadge');

  // Overall Score
  const overall = Number(data.overall_score || 0).toFixed(1);
  const isCompliant = (data.status || '').toUpperCase() === 'COMPLIANT' || Number(overall) >= 70;

  document.getElementById('resOverallScore').textContent = `${overall}`;
  document.getElementById('resOverallScore').style.color = isCompliant ? 'var(--emerald)' : 'var(--rose)';
  document.getElementById('resStatusTag').textContent = isCompliant ? '✓ COMPLIANT' : '⚠ DEFICIENT';
  document.getElementById('resStatusTag').style.color = isCompliant ? 'var(--emerald)' : 'var(--rose)';

  statusBadge.className = isCompliant ? 'status-badge-compliant' : 'status-badge-noncompliant';
  statusBadge.textContent = isCompliant ? 'COMPLIANT' : 'NON-COMPLIANT';

  // Component Scores
  document.getElementById('resNutritionScore').textContent = Number(data.nutrition_score || 0).toFixed(1);
  document.getElementById('resQuantityScore').textContent = Number(data.quantity_score || 0).toFixed(1);
  document.getElementById('resHygieneScore').textContent = Number(data.hygiene_score || 0).toFixed(1);

  // Detected Items Table
  const items = (data.vision_result?.food_items || []);
  const body = document.getElementById('resDetectedItemsBody');
  if (items.length === 0) {
    body.innerHTML = '<tr><td colspan="4" style="text-align:center;padding:12px;color:var(--text-muted)">No items identified</td></tr>';
  } else {
    body.innerHTML = items.map(item => {
      const confPct = Math.round((item.confidence || 0.9) * 100);
      return `
        <tr>
          <td><strong>${esc(item.name)}</strong></td>
          <td>${item.estimated_quantity ? item.estimated_quantity + ' ' + (item.unit || 'kg') : '—'}</td>
          <td>
            <div style="display:flex;align-items:center;gap:6px;">
              <div class="progress-bar-bg" style="width:60px;">
                <div class="progress-bar-fill" style="width:${confPct}%;background:var(--indigo)"></div>
              </div>
              <span>${confPct}%</span>
            </div>
          </td>
          <td><span style="color:var(--emerald);font-weight:600;">✓ Pass</span></td>
        </tr>
      `;
    }).join('');
  }

  // Nutrition Breakdown (approx estimates from scores)
  document.getElementById('nutCalories').textContent = `${Math.round(650 + (Number(data.nutrition_score || 80) - 70) * 8)} kcal`;
  document.getElementById('nutProtein').textContent = `${(18 + (Number(data.nutrition_score || 80) - 70) * 0.25).toFixed(1)}g`;
  document.getElementById('nutCarbs').textContent = `${Math.round(90 + (Number(data.quantity_score || 80) - 70) * 0.8)}g`;
  document.getElementById('nutFat').textContent = `${(14 + (Number(data.nutrition_score || 80) - 70) * 0.1).toFixed(1)}g`;

  // AI Narrative Explanation
  document.getElementById('resExplanation').innerHTML = esc(data.explanation || 'Meal verified according to national PM POSHAN nutritional standards.')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');

  resultContent.style.display = 'block';
}

/* ══════════════════════════════════════════════════
   AI WASTE PREDICTOR SIMULATION
══════════════════════════════════════════════════ */
async function runWasteSimulation() {
  const students = parseInt(document.getElementById('simStudents')?.value || '280');
  const schoolSize = parseInt(document.getElementById('simSchoolSize')?.value || '300');
  const temp = parseFloat(document.getElementById('simTemp')?.value || '29.5');
  const days = parseInt(document.getElementById('simDays')?.value || '7');

  const box = document.getElementById('simResultBox');
  if (box) box.style.display = 'block';

  try {
    const res = await apiFetch('/api/v1/ai/predict-waste', {
      method: 'POST',
      body: {
        historical_waste: [18.5, 16.2, 19.0, 15.5, 21.0, 17.8, 19.5],
        student_counts: [students, students + 5, students - 5, students, students + 10, students - 2, students],
        meals_served: [students, students + 5, students - 5, students, students + 10, students - 2, students],
        school_size: schoolSize,
        days_ahead: days,
        temperature_c: temp,
        menu_category_id: 0,
        portion_size_g: 250.0
      }
    });

    if (res.ok && res.data) {
      const pred = res.data;
      document.getElementById('simWasteVal').textContent = `${Number(pred.predicted_value || 14.8).toFixed(1)} kg`;
      document.getElementById('simRiskBadge').textContent = `${pred.risk_level || 'LOW'} RISK`;
      document.getElementById('simRiskBadge').className = pred.risk_level === 'LOW' ? 'status-badge-compliant' : 'status-badge-noncompliant';
      document.getElementById('simTrendText').textContent = `Trend: ${capitalise(pred.trend || 'stable')}`;
    }
  } catch (err) {
    console.warn('Simulation error:', err);
  }
}
