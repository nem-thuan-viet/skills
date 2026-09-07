/* Khung JS khối bàn làm việc · dán vào ô Script của Custom HTML Block.
   CHỈ ĐỌC. Chạy trong shadow DOM với biến root_element.
   Việc của người dựng: (1) đổi TEN_KHOI, (2) viết loadMonth() lấy số từ nguồn thật, (3) viết render*() cho từng section.
   Helper bên dưới đã dùng thật trên bàn Marketing & Kinh Doanh (03/09/2026). */
(function () {
  const R = root_element;
  const $ = (s) => R.querySelector(s);
  const TEN_KHOI = 'TEN Khối';          // = tên bản ghi Custom HTML Block (dùng cho CSS cấp trang)
  const DESK = '/desk';
  const today = new Date();
  const ymOf = (d) => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0');
  const state = { ym: ymOf(today), cache: {} };

  // ---- style cấp trang: font brand + nới trang, chỉ khi khối này hiện (xem references/nhan-dien.md để thêm thanh trên/thanh trái) ----
  try {
    const ID = 'kd-page-style-' + TEN_KHOI.replace(/\W+/g, '-');
    if (!document.getElementById(ID)) {
      const F = '/assets/ntv_eshop/eshop-ui/fonts/';
      const B = "body:has([custom_block_name='" + TEN_KHOI + "'])";
      const st = document.createElement('style'); st.id = ID;
      st.textContent =
        '@font-face{font-family:SVN-Gilroy;src:url(' + F + 'SVN-GILROY_REGULAR.OTF);font-weight:400;font-display:swap}' +
        '@font-face{font-family:SVN-Gilroy;src:url(' + F + 'SVN-GILROY_MEDIUM.OTF);font-weight:500;font-display:swap}' +
        '@font-face{font-family:SVN-Gilroy;src:url(' + F + 'SVN-GILROY_SEMIBOLD_1.TTF);font-weight:600;font-display:swap}' +
        '@font-face{font-family:SVN-Gilroy;src:url(' + F + 'SVN-GILROY_BOLD.OTF);font-weight:700;font-display:swap}' +
        "[data-page-route='Workspaces'] .layout-main:has([custom_block_name='" + TEN_KHOI + "']){max-width:100% !important}" +
        "[data-page-route='Workspaces'] .layout-main:has([custom_block_name='" + TEN_KHOI + "']) .layout-main-section{max-width:1400px;margin:0 auto}" +
        B + ' .codex-editor .h4,' + B + ' .ce-header{color:#590F22 !important;font-weight:700 !important}';
      document.head.appendChild(st);
    }
  } catch (e) { /* không chặn khối */ }

  // ---- tiện ích định dạng ----
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const vn = (n, d = 0) => Number(n || 0).toLocaleString('vi-VN', { maximumFractionDigits: d, minimumFractionDigits: d });
  const tien = (v) => '<b>' + vn(Math.round(Number(v || 0)), 0) + '</b>';                 // thẻ: đủ số đồng
  const tienText = (v) => (Math.abs(v) >= 1e9 ? vn(v / 1e9, 2) + ' tỷ' : vn(v / 1e6, 0) + ' tr'); // bảng: gọn
  const pct = (a, b) => (b ? (a / b) * 100 : null);
  const pctText = (p) => (p == null ? '—' : vn(p, 1) + '%');
  const dmy = (s) => (s ? s.slice(8, 10) + '/' + s.slice(5, 7) : '—');
  const daysAgo = (s) => (s ? Math.floor((today - new Date(s + 'T00:00:00')) / 864e5) : null);
  const monthRange = (ym) => { const [y, m] = ym.split('-').map(Number); const last = new Date(y, m, 0).getDate(); return { from: ym + '-01', to: ym + '-' + String(last).padStart(2, '0'), y, m, last }; };

  // ---- gọi ERP (chỉ GET, dùng phiên đăng nhập của người xem) ----
  async function GET(url) {
    const r = await fetch(url, { headers: { 'X-Requested-With': 'XMLHttpRequest' } });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(j.exception || j._error_message || ('HTTP ' + r.status));
    return j.message !== undefined ? j.message : j.data;
  }
  // list('eShop Invoice', ['sale_channel', {SUM:'actual_amount'}], [['report_date','>=',from]], {group_by:'sale_channel'})
  const list = (dt, fields, filters, o = {}) => {
    const q = { fields: JSON.stringify(fields), filters: JSON.stringify(filters || []), limit_page_length: o.limit || 500 };
    if (o.group_by) q.group_by = o.group_by;
    if (o.order_by) q.order_by = o.order_by;
    return GET('/api/resource/' + encodeURIComponent(dt) + '?' + new URLSearchParams(q));
  };
  const count = (dt, filters) => GET('/api/method/frappe.client.get_count?' + new URLSearchParams({ doctype: dt, filters: JSON.stringify(filters) }));
  const method = (path, params) => GET('/api/method/' + path + '?' + new URLSearchParams(params || {})); // API app: 'ntv_eshop.api.bridge.staff'
  const agg = (row, fn, f) => Number(row[fn + '(`' + f + '`)'] || 0);                        // đọc SUM/COUNT/MAX

  // ---- mảnh giao diện ----
  const dot = (lastDay, expectDays) => { const d = daysAgo(lastDay); if (d == null) return '<i class="kd-dot r"></i>'; return '<i class="kd-dot ' + (d <= expectDays ? 'g' : d <= expectDays + 3 ? 'a' : 'r') + '"></i>'; };
  const tile = (o) => { // {l, v(html), s, cls: ok|warn, href, dot}
    const cls = 'kd-tile' + (o.cls ? ' ' + o.cls : '');
    const inner = '<div class="l">' + esc(o.l) + (o.dot || '') + '</div><div class="v' + (o.dim ? ' dim' : '') + '">' + o.v + '</div><div class="s" title="' + esc(o.s || '') + '">' + esc(o.s || '') + '</div>';
    return o.href ? '<a class="' + cls + '" href="' + o.href + '">' + inner + '</a>' : '<div class="' + cls + '">' + inner + '</div>';
  };
  const bar = (p, low) => '<span class="kd-prog"><i class="' + (low ? 'low' : '') + '" style="--p:' + Math.max(0, Math.min(100, p || 0)) + '%"></i>' + pctText(p) + '</span>';
  const pill = (txt, cls) => '<span class="kd-pill ' + cls + '">' + esc(txt) + '</span>';
  const chip = (l, n, cls, href, title) => '<a class="kd-chip" href="' + href + '" title="' + esc(title || '') + '"><span>' + esc(l) + '</span><span class="n ' + (n ? cls : 'ok') + '">' + vn(n) + '</span></a>';
  const table = (heads, rows, sumRow) => '<table><thead><tr>' + heads.map((h) => '<th>' + esc(h) + '</th>').join('') + '</tr></thead><tbody>' + rows.map((r) => '<tr>' + r.map((c) => '<td>' + c + '</td>').join('') + '</tr>').join('') + (sumRow ? '<tr class="sum">' + sumRow.map((c) => '<td>' + c + '</td>').join('') + '</tr>' : '') + '</tbody></table>';

  // ---- 1) LẤY SỐ: viết lại cho bàn của mình. Mỗi nguồn là một promise, allSettled để 1 nguồn hỏng không kéo cả khối ----
  async function loadMonth(ym) {
    const rg = monthRange(ym);
    const mk = {
      // vi_du_doanh_thu: () => method('ntv_eshop.api.bridge.staff', { from: rg.from, to: rg.to }),
      // vi_du_theo_kenh: () => list('eShop Invoice', ['sale_channel', { COUNT: 'name' }, { SUM: 'actual_amount' }], [['report_date', '>=', rg.from], ['report_date', '<=', rg.to]], { group_by: 'sale_channel' }),
      // vi_du_dem: () => count('Workflow Action', [['status', '=', 'Open'], ['user', '=', frappe.session.user]]),
    };
    const keys = Object.keys(mk);
    const res = await Promise.allSettled(keys.map((k) => mk[k]()));
    const out = { rg, err: {} };
    keys.forEach((k, i) => { if (res[i].status === 'fulfilled') out[k] = res[i].value; else out.err[k] = res[i].reason && res[i].reason.message; });
    return out;
  }

  // ---- 2) VẼ: một hàm cho mỗi section trong HTML ----
  function renderThang(D) {
    $('#tiles-thang').innerHTML = [
      tile({ l: 'Chỉ số 1', v: tien(0), s: 'nguồn · ghi chú', dot: '<i class="kd-dot g"></i>' }),
      tile({ l: 'Chỉ số 2', v: tien(0), s: '' }),
      tile({ l: 'Chỉ số 3', v: '<b>' + vn(0, 1) + '</b><small>%</small>', s: 'ngưỡng …', cls: 'ok' }),
      tile({ l: 'Chỉ số 4', v: tien(0), s: '' }),
      tile({ l: 'Cần chú ý', v: tien(0), s: '', cls: 'warn' }),
    ].join('');
    $('#kd-sub').textContent = 'Tháng ' + Number(state.ym.slice(5)) + '/' + state.ym.slice(0, 4) + ' · số cập nhật ' + today.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  }
  function renderBang(D) {
    $('#tbl-bang').innerHTML = table(['Đơn vị', 'Thực hiện', 'Kế hoạch', 'Tiến độ', 'Trạng thái'],
      [['Ví dụ A', tienText(0), tienText(0), bar(0), pill('—', 'mute')]],
      ['Tổng', tienText(0), tienText(0), bar(0), '']);
  }
  function renderChips(D) {
    $('#chips').innerHTML = [
      chip('Việc cần xử lý 1', 0, 'red', DESK + '/todo'),
      chip('Việc cần xử lý 2', 0, 'amber', DESK + '/workflow-action'),
      chip('Chờ tôi duyệt', 0, 'amber', DESK + '/workflow-action'),
    ].join('');
  }

  // ---- 3) ĐIỀU KHIỂN (giữ nguyên) ----
  function fillMonths() {
    const sel = $('#kd-month'); sel.innerHTML = '';
    const start = new Date(today.getFullYear(), 0, 1);
    for (let d = new Date(today.getFullYear(), today.getMonth(), 1); d >= start; d.setMonth(d.getMonth() - 1)) {
      const ym = ymOf(d); const o = document.createElement('option'); o.value = ym; o.textContent = 'Tháng ' + (d.getMonth() + 1) + '/' + d.getFullYear(); if (ym === state.ym) o.selected = true; sel.appendChild(o);
    }
  }
  async function run(force) {
    R.querySelectorAll('.kd-tiles, .kd-tblwrap, .kd-chips').forEach((el) => { if (!el.querySelector('.kd-skel')) el.style.opacity = '.55'; });
    try {
      const D = (!force && state.cache[state.ym]) || (state.cache[state.ym] = await loadMonth(state.ym));
      if ($('#tiles-thang')) renderThang(D);
      if ($('#tbl-bang')) renderBang(D);
      if ($('#chips')) renderChips(D);
      const errs = Object.entries(D.err || {});
      $('#kd-foot').innerHTML = 'Ghi định nghĩa số ở đây: công thức · trạng thái lọc · ngày đếm · nguồn từng cột'
        + (errs.length ? '<br><span class="kd-err" style="display:inline-block;margin-top:6px">Không tải được: ' + errs.map(([k, v]) => esc(k) + ' (' + esc(v) + ')').join(' · ') + '</span>' : '');
    } catch (e) {
      $('#kd-foot').innerHTML = '<div class="kd-err">Lỗi tải số: ' + esc(e.message) + '</div>';
    } finally {
      R.querySelectorAll('.kd-tiles, .kd-tblwrap, .kd-chips').forEach((el) => (el.style.opacity = ''));
    }
  }
  fillMonths();
  $('#kd-month').addEventListener('change', (e) => { state.ym = e.target.value; window.dispatchEvent(new CustomEvent('kd-month', { detail: state.ym })); run(false); });
  window.addEventListener('kd-month', (e) => { if (e.detail && e.detail !== state.ym) { state.ym = e.detail; $('#kd-month').value = state.ym; run(false); } }); // đồng bộ tháng giữa các khối
  $('#kd-reload').addEventListener('click', () => run(true));
  run(false);
})();
