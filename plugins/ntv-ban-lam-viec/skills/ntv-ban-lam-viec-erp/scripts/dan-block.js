/* dan-block.js — tạo/sửa Custom HTML Block và gắn vào Workspace bằng REST, chạy trong Console (F12) của
   một tab desk đã đăng nhập (cần frappe.csrf_token). Claude cũng chạy được qua công cụ trình duyệt.
   Không deploy, không sửa code app. Mỗi lần chạy = 1 khối. Xin người dùng đồng ý trước khi chạy trên prod.

   CÁCH DÙNG: dán 3 hằng HTML/CSS/JS bên dưới (JS viết trong function __blk để khỏi escape), đổi TEN_KHOI /
   TEN_WORKSPACE / SAU_KHOI, rồi dán cả file vào console. */

(async () => {
  const TEN_KHOI = 'TEN Khối';            // tên bản ghi Custom HTML Block, tiền tố theo phòng: 'CEO Tiền', 'KHO Tồn kho'
  const TEN_WORKSPACE = 'Marketing';       // name của Workspace (= label, không phải title)
  const SAU_KHOI = null;                   // tên khối đứng trước; null = chèn ngay dưới header đầu tiên
  const CHI_THU = false;                   // true = chỉ chèn tạm vào trang để xem, KHÔNG lưu gì lên ERP

  const HTML = `<!-- dán nội dung block-khung.html -->`;
  const CSS = `/* dán nội dung block-khung.css */`;
  function __blk(root_element) {
    /* dán nội dung block-khung.js vào đây (giữ nguyên IIFE bên trong) */
  }
  const JS = __blk.toString().replace(/^function __blk\(root_element\)\s*\{\n?/, '').replace(/\}\s*$/, '');

  // kiểm cú pháp trước khi gửi
  try { new Function('root_element', JS); } catch (e) { console.error('Lỗi cú pháp JS:', e.message); return; }

  if (CHI_THU) { // chèn tạm: shadow DOM giả giống Frappe
    document.getElementById('kd-thu')?.remove();
    const host = document.createElement('div'); host.id = 'kd-thu'; host.setAttribute('custom_block_name', TEN_KHOI);
    (document.querySelector('.layout-main-section') || document.body).prepend(host);
    const sh = host.attachShadow({ mode: 'open' });
    const st = document.createElement('style'); st.textContent = CSS; sh.appendChild(st);
    const root = document.createElement('div'); root.innerHTML = HTML; sh.appendChild(root);
    new Function('root_element', JS)(root);
    console.log('Đã chèn tạm, tải lại trang là mất.'); return;
  }

  const H = { 'Content-Type': 'application/json', 'X-Frappe-CSRF-Token': frappe.csrf_token, 'X-Requested-With': 'XMLHttpRequest' };
  const enc = encodeURIComponent;

  // 1) tạo hoặc cập nhật khối
  const exists = (await fetch('/api/resource/Custom%20HTML%20Block/' + enc(TEN_KHOI))).status === 200;
  const r1 = exists
    ? await fetch('/api/resource/Custom%20HTML%20Block/' + enc(TEN_KHOI), { method: 'PUT', headers: H, body: JSON.stringify({ html: HTML, style: CSS, script: JS, private: 0 }) })
    : await fetch('/api/resource/Custom%20HTML%20Block', { method: 'POST', headers: H, body: JSON.stringify({ doctype: 'Custom HTML Block', __newname: TEN_KHOI, name: TEN_KHOI, private: 0, html: HTML, style: CSS, script: JS, roles: [] }) });
  const j1 = await r1.json().catch(() => ({}));
  if (r1.status !== 200) { console.error('Lỗi lưu khối', r1.status, j1.exception || j1._server_messages); return; }
  console.log((exists ? 'Đã cập nhật' : 'Đã tạo') + ' khối', TEN_KHOI);

  // 2) gắn vào workspace (giữ nguyên các khối/shortcut đang có)
  const ws = (await fetch('/api/resource/Workspace/' + enc(TEN_WORKSPACE)).then((r) => r.json())).data;
  if (!ws) { console.error('Không thấy Workspace', TEN_WORKSPACE); return; }
  let content = JSON.parse(ws.content || '[]');
  if (!content.some((b) => b.type === 'custom_block' && b.data.custom_block_name === TEN_KHOI)) {
    const block = { id: 'cb_' + Date.now().toString(36), type: 'custom_block', data: { custom_block_name: TEN_KHOI, col: 12 } };
    let i = SAU_KHOI ? content.findIndex((b) => b.type === 'custom_block' && b.data.custom_block_name === SAU_KHOI) : content.findIndex((b) => b.type === 'header');
    content.splice(i + 1, 0, block);
  }
  const cbs = (ws.custom_blocks || []).map((c) => ({ custom_block_name: c.custom_block_name, label: c.label }));
  if (!cbs.some((c) => c.custom_block_name === TEN_KHOI)) cbs.push({ custom_block_name: TEN_KHOI, label: TEN_KHOI });
  const r2 = await fetch('/api/resource/Workspace/' + enc(TEN_WORKSPACE), { method: 'PUT', headers: H, body: JSON.stringify({ content: JSON.stringify(content), custom_blocks: cbs }) });
  const j2 = await r2.json().catch(() => ({}));
  if (r2.status !== 200) { console.error('Lỗi gắn vào workspace', r2.status, j2.exception); return; }
  console.log('Thứ tự khối:', JSON.parse(j2.data.content).map((b) => b.data.custom_block_name || b.type).join(' | '));
  console.log('Tải lại trang để xem. Sửa nhỏ về sau: GET bản ghi → replace chuỗi → PUT (xem references/frappe16-workspace.md).');
})();
