/* ghi-chu-viec.js — khối Ghi chú (Comment) + Việc (ToDo) gắn vào Workspace của bàn. Dùng kèm ghi-chu-viec.html/.css.
   Đây là khối DUY NHẤT có ghi: chỉ ghi Comment/ToDo do người dùng gõ, qua API chuẩn Frappe, theo quyền phiên đăng nhập. */
(function () {
  const R = root_element;
  const $ = (s) => R.querySelector(s);
  const REF = { doctype: 'Workspace', name: 'TEN_WORKSPACE' }; // ĐỔI: name của Workspace bàn này (ghi chú/việc gắn vào đây)
  const state = { notes: [], todos: [], users: {}, userList: [], showDone: false };
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const strip = (html) => { const d = document.createElement('div'); d.innerHTML = html || ''; return (d.textContent || '').trim(); };
  const H = () => ({ 'Content-Type': 'application/json', 'X-Frappe-CSRF-Token': (window.frappe && frappe.csrf_token) || '', 'X-Requested-With': 'XMLHttpRequest' });
  async function api(url, opt) {
    const r = await fetch(url, Object.assign({ headers: H() }, opt || {}));
    const j = await r.json().catch(() => ({}));
    if (!r.ok) { let m = j.exception || ''; try { m = JSON.parse(JSON.parse(j._server_messages || '[]')[0] || '{}').message || m; } catch (e) { /* bỏ */ } throw new Error(strip(m) || ('HTTP ' + r.status)); }
    return j.message !== undefined ? j.message : j.data;
  }
  const list = (dt, fields, filters, o = {}) => api('/api/resource/' + encodeURIComponent(dt) + '?' + new URLSearchParams({ fields: JSON.stringify(fields), filters: JSON.stringify(filters), limit_page_length: o.limit || 100, order_by: o.order_by || 'creation desc' }));
  const me = () => (window.frappe && frappe.session && frappe.session.user) || '';
  const myName = () => (window.frappe && frappe.session && frappe.session.user_fullname) || me();
  const nameOf = (u) => (state.users[u] && state.users[u].full_name) || (u || '').split('@')[0] || '—';
  const initials = (n) => { const p = (n || '').trim().split(/\s+/); return (p.length > 1 ? p[p.length - 2][0] + p[p.length - 1][0] : (p[0] || '?')[0]).toUpperCase(); };
  const hue = (s) => { let h = 0; for (const c of s || '') h = (h * 31 + c.charCodeAt(0)) % 360; return h; };
  const when = (s) => { if (!s) return ''; const d = new Date(s.replace(' ', 'T')); const dd = String(d.getDate()).padStart(2, '0'), mm = String(d.getMonth() + 1).padStart(2, '0'); return dd + '/' + mm + ' ' + String(d.getHours()).padStart(2, '0') + 'h' + String(d.getMinutes()).padStart(2, '0'); };
  const dmy = (s) => (s ? s.slice(8, 10) + '/' + s.slice(5, 7) : '');

  async function load() {
    const [notes, todos, users] = await Promise.all([
      list('Comment', ['name', 'content', 'comment_by', 'comment_email', 'owner', 'creation'], [['reference_doctype', '=', REF.doctype], ['reference_name', '=', REF.name], ['comment_type', '=', 'Comment']], { limit: 50 }),
      list('ToDo', ['name', 'description', 'status', 'allocated_to', 'date', 'owner', 'creation', 'modified'], [['reference_type', '=', REF.doctype], ['reference_name', '=', REF.name], ['status', 'in', ['Open', 'Closed']]], { limit: 100, order_by: 'status desc, creation desc' }),
      list('User', ['name', 'full_name'], [['enabled', '=', 1], ['user_type', '=', 'System User']], { limit: 500, order_by: 'full_name asc' }).catch(() => []),
    ]);
    state.notes = notes; state.todos = todos; state.userList = users; state.users = {}; users.forEach((u) => (state.users[u.name] = u));
  }

  function avatar(name) { return '<span class="gcv-av" style="--h:' + hue(name) + '">' + esc(initials(name)) + '</span>'; }
  function render() {
    const open = state.todos.filter((t) => t.status === 'Open'), done = state.todos.filter((t) => t.status === 'Closed');
    $('#gcv-sum').textContent = state.notes.length + ' ghi chú · ' + state.todos.length + ' việc' + (state.todos.length ? ' · ' + (open.length ? open.length + ' đang mở' : 'xong hết') : '');
    $('#gcv-notes-count').textContent = state.notes.length;
    $('#gcv-todos-count').textContent = open.length;
    $('#gcv-notes').innerHTML = state.notes.length ? state.notes.map((n) => { const who = n.comment_by || nameOf(n.comment_email || n.owner); return '<div class="gcv-note">' + avatar(who) + '<div><div class="gcv-meta"><b>' + esc(who) + '</b> <span>' + when(n.creation) + '</span></div><div class="gcv-text">' + esc(strip(n.content)) + '</div></div></div>'; }).join('') : '<div class="gcv-empty">Chưa có ghi chú. Ai thấy số lạ thì ghi một dòng ở dưới.</div>';
    const row = (t) => '<div class="gcv-todo' + (t.status === 'Closed' ? ' done' : '') + '"><label class="gcv-chk"><input type="checkbox" data-id="' + esc(t.name) + '"' + (t.status === 'Closed' ? ' checked' : '') + '><span></span></label><div><div class="gcv-text">' + esc(strip(t.description)) + '</div><div class="gcv-meta">' + (t.allocated_to ? esc(nameOf(t.allocated_to)) : 'chưa giao') + (t.date ? ' · hạn ' + dmy(t.date) : '') + (t.status === 'Closed' ? ' · xong ' + dmy(t.modified) + ' <i class="kd-pill ok">xong</i>' : '') + '</div></div></div>';
    $('#gcv-todos').innerHTML = (open.length ? open.map(row).join('') : '<div class="gcv-empty">Chưa có việc đang mở.</div>') + (done.length ? '<button type="button" class="kd-more" data-act="toggle-done">' + (state.showDone ? 'Ẩn' : 'Xem') + ' ' + done.length + ' việc đã xong</button>' + (state.showDone ? done.map(row).join('') : '') : '');
    const sel = $('#gcv-who'); const cur = sel.value;
    sel.innerHTML = '<option value="">Giao cho…</option>' + state.userList.map((u) => '<option value="' + esc(u.name) + '"' + (u.name === cur ? ' selected' : '') + '>' + esc(u.full_name || u.name) + '</option>').join('');
  }
  function toast(msg, bad) { const t = $('#gcv-toast'); t.textContent = msg; t.className = 'gcv-toast' + (bad ? ' bad' : '') + ' show'; setTimeout(() => t.classList.remove('show'), 2200); }

  async function addNote() {
    const inp = $('#gcv-note-input'); const txt = inp.value.trim(); if (!txt) return;
    inp.disabled = true;
    try {
      await api('/api/method/frappe.desk.form.utils.add_comment', { method: 'POST', body: JSON.stringify({ reference_doctype: REF.doctype, reference_name: REF.name, content: esc(txt).replace(/\n/g, '<br>'), comment_email: me(), comment_by: myName() }) });
      inp.value = ''; await load(); render(); toast('Đã ghi');
    } catch (e) { toast('Không ghi được: ' + e.message, true); }
    finally { inp.disabled = false; inp.focus(); }
  }
  async function addTodo() {
    const inp = $('#gcv-todo-input'); const txt = inp.value.trim(); if (!txt) return;
    const who = $('#gcv-who').value, date = $('#gcv-date').value;
    inp.disabled = true;
    try {
      const body = { doctype: 'ToDo', description: esc(txt), status: 'Open', priority: 'Medium', reference_type: REF.doctype, reference_name: REF.name };
      if (who) body.allocated_to = who; if (date) body.date = date;
      await api('/api/resource/ToDo', { method: 'POST', body: JSON.stringify(body) });
      inp.value = ''; $('#gcv-date').value = ''; await load(); render(); toast(who ? 'Đã giao việc' : 'Đã thêm việc');
    } catch (e) { toast('Không thêm được: ' + e.message, true); }
    finally { inp.disabled = false; }
  }
  async function toggleTodo(name, done) {
    try { await api('/api/resource/ToDo/' + encodeURIComponent(name), { method: 'PUT', body: JSON.stringify({ status: done ? 'Closed' : 'Open' }) }); await load(); render(); }
    catch (e) { toast('Không đổi được: ' + e.message, true); await load(); render(); }
  }

  R.addEventListener('click', (e) => {
    const b = e.target.closest('[data-act]'); if (!b) return;
    if (b.dataset.act === 'add-note') addNote();
    if (b.dataset.act === 'add-todo') addTodo();
    if (b.dataset.act === 'reload') load().then(render);
    if (b.dataset.act === 'toggle-done') { state.showDone = !state.showDone; render(); }
    if (b.dataset.act === 'focus-note') $('#gcv-note-input').focus();
    if (b.dataset.act === 'focus-todo') $('#gcv-todo-input').focus();
  });
  R.addEventListener('change', (e) => { const c = e.target.closest('input[type=checkbox][data-id]'); if (c) toggleTodo(c.dataset.id, c.checked); });
  $('#gcv-note-input').addEventListener('keydown', (e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); addNote(); } });
  $('#gcv-todo-input').addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); addTodo(); } });
  load().then(render).catch((e) => { $('#gcv-notes').innerHTML = '<div class="kd-err">Không tải được: ' + esc(e.message) + '</div>'; $('#gcv-todos').innerHTML = ''; });
})();
