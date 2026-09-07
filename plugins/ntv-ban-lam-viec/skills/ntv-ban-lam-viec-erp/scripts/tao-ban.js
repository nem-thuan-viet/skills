/* tao-ban.js — tạo bộ 3 bản ghi cho một bàn mới: Workspace (public) + Workspace Sidebar + Desktop Icon,
   cùng MỘT tên để URL/desktop/thanh trái khớp nhau. Chạy trong Console tab desk (cần System Manager +
   Workspace Manager). Xin người dùng chốt TÊN trước: tên = URL, và bị dịch nếu là từ tiếng Anh thông dụng
   ("Marketing" → "Tiếp thị"). Sau khi chạy: Settings → Reload (frappe.sessions.clear) rồi tải lại. */
(async () => {
  const TEN = 'Kho vận';                 // = name Workspace = name Sidebar = label Desktop Icon
  const APP = 'ntv';                      // app "chủ" để xếp nhóm (Autocomplete Installed Applications)
  const ICON = 'tool';                    // icon Frappe cho workspace / header_icon sidebar
  const MUC_THANH_TRAI = [                // các mục thanh trái (link_type: Workspace|DocType|Report|Page|URL|Dashboard)
    // Mẫu thanh trái "theo khối": mỗi mục là URL '/desk/<slug bàn>#<id section>' (xem assets/templates/dieu-huong-thanh-trai.js)
    { label: 'Tổng quan', link_type: 'URL', url: '/desk/' + TEN.toLowerCase().replace(/\s+/g, '-') + '#top', icon: 'dashboard' },
    { type: 'Section Break', label: 'Báo cáo' },
    // { label: 'Tồn kho', link_type: 'Report', link_to: 'Stock Balance', icon: 'chart' },
    // { label: 'Phiếu giao', link_type: 'DocType', link_to: 'Delivery Note', icon: 'file' },
    // { label: 'Insights', link_type: 'URL', url: '/insights/dashboards/xxxx', icon: 'share' },
    { type: 'Section Break', label: 'Việc của tôi' },
    { label: 'Chờ tôi duyệt', link_type: 'DocType', link_to: 'Workflow Action', icon: 'check' },
  ];

  const H = { 'Content-Type': 'application/json', 'X-Frappe-CSRF-Token': frappe.csrf_token, 'X-Requested-With': 'XMLHttpRequest' };
  const enc = encodeURIComponent;
  const post = (dt, body) => fetch('/api/resource/' + enc(dt), { method: 'POST', headers: H, body: JSON.stringify(Object.assign({ doctype: dt }, body)) }).then(async (r) => ({ status: r.status, j: await r.json().catch(() => ({})) }));
  const exists = async (dt, name) => (await fetch('/api/resource/' + enc(dt) + '/' + enc(name))).status === 200;

  // 1) Workspace public, nội dung mở đầu = 1 header (khối thêm sau bằng dan-block.js)
  if (!(await exists('Workspace', TEN))) {
    const content = JSON.stringify([{ id: 'h0', type: 'header', data: { text: '<span class="h4"><b>' + TEN + '</b></span>', col: 12 } }]);
    const r = await post('Workspace', { __newname: TEN, label: TEN, title: TEN, public: 1, for_user: '', icon: ICON, content, sequence_id: 99 });
    console.log('Workspace', r.status, r.j.exception || 'ok');
  } else console.log('Workspace đã có');

  // 2) Workspace Sidebar cùng tên
  if (!(await exists('Workspace Sidebar', TEN))) {
    const items = MUC_THANH_TRAI.map((m) => Object.assign({ type: 'Link', collapsible: 1, indent: 0, child: 0, keep_closed: 0, show_arrow: 0, link_to: null, url: null, icon: null }, m));
    const r = await post('Workspace Sidebar', { __newname: TEN, title: TEN, header_icon: ICON, app: APP, standard: 0, items });
    console.log('Workspace Sidebar', r.status, r.j.exception || 'ok');
  } else console.log('Sidebar đã có');

  // 3) Desktop Icon trỏ tới sidebar (ô có thể hiện chậm vì cache cấp site — báo trước cho người dùng)
  if (!(await exists('Desktop Icon', TEN))) {
    const r = await post('Desktop Icon', { __newname: TEN, label: TEN, icon_type: 'Link', link_type: 'Workspace Sidebar', link_to: TEN, standard: 1, app: APP, icon: ICON, hidden: 0 });
    console.log('Desktop Icon', r.status, r.j.exception || 'ok');
  } else console.log('Desktop Icon đã có');

  await new Promise((res) => frappe.call({ method: 'frappe.sessions.clear', callback: () => res(), error: () => res() }));
  console.log('Xong. Mở /desk/' + frappe.router.slug(TEN) + ' rồi chạy dan-block.js để thêm khối.');
})();
