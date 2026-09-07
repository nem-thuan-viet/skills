# Frappe 16 trên platform.nguoithuanviet.com — 4 bản ghi làm nên một "bàn"

Kiểm trực tiếp 03/09/2026 (Frappe 16.33, ERPNext 16.34). Mọi thao tác dưới đây làm bằng REST từ tab desk đã
đăng nhập (header `X-Frappe-CSRF-Token: frappe.csrf_token`), không cần API key, không cần deploy.

## 1. Workspace — nội dung trang

- URL: `/desk/<slug(name)>`. **name = label** (autoname `field:label`), `title` là trường riêng nhưng tiêu đề trang
  và tab trình duyệt lấy theo **name đã dịch** — đặt name "Marketing" thì hiện "Tiếp thị". Muốn URL ngắn thì name
  ngắn tiếng Anh; muốn tiêu đề tiếng Việt không bị dịch thì name tiếng Việt (URL dài có dấu). Không có cách tách.
- `public=1` + `for_user=""` = mọi user đăng nhập thấy. Private: `public=0`, `for_user=<email>`, URL `/desk/private/<slug>`.
- `content` là **chuỗi JSON** mảng block Editor.js: `{id, type, data}`; type hay dùng: `header`
  (`data.text` = `<span class="h4"><b>…</b></span>`, `col:12`), `custom_block` (`data.custom_block_name`, `col:12`),
  `shortcut` (`data.shortcut_name`), `paragraph`, `spacer`.
- Child tables phải gửi đủ mảng khi PUT: `custom_blocks[{custom_block_name,label}]`, `shortcuts[…]`, `links[…]`,
  `charts[…]`, `number_cards[…]`. Gửi thiếu = mất dòng.
- Đổi tên hiển thị: PUT `title`. Đổi URL: `frappe.client.rename_doc` (label = name). ❌ Đừng dùng
  `frappe.desk.doctype.workspace.workspace.update_page` để đổi tên — nó rename cả label/URL.
- Chuyển private → public: `update_page(name, title, icon, indicator_color, parent='', public=1)` (cần role
  Workspace Manager) hoặc PUT `public=1, for_user=''`.

```js
// đọc
const ws = (await fetch('/api/resource/Workspace/' + encodeURIComponent(NAME)).then(r => r.json())).data;
let content = JSON.parse(ws.content);
// thêm khối sau khối X
content.splice(content.findIndex(b => b.type === 'custom_block' && b.data.custom_block_name === 'X') + 1, 0,
  { id: 'cb_' + Date.now().toString(36), type: 'custom_block', data: { custom_block_name: BLOCK, col: 12 } });
const cbs = ws.custom_blocks.map(c => ({ custom_block_name: c.custom_block_name, label: c.label }));
if (!cbs.some(c => c.custom_block_name === BLOCK)) cbs.push({ custom_block_name: BLOCK, label: BLOCK });
await fetch('/api/resource/Workspace/' + encodeURIComponent(NAME), { method: 'PUT', headers: H,
  body: JSON.stringify({ content: JSON.stringify(content), custom_blocks: cbs }) });
```

## 2. Custom HTML Block — cái ruột

- Fields: `html` (Code HTML), `style` (Code CSS), `script` (Code JS), `private` (Check), `roles` (Has Role —
  để trống = ai thấy workspace là thấy khối; khai role để giới hạn).
- Chạy trong **shadow DOM**: script nhận biến `root_element`; `root_element.querySelector(...)` để lấy phần tử
  trong khối; `document.*` là trang ngoài. CSS trong `style` chỉ áp trong khối. Biến CSS của Frappe
  (`--text-color`, `--border-color`, `--fg-color`…) kế thừa vào được.
- `@font-face` **phải chèn vào `document.head`** (tạo `<style id=...>` một lần, kiểm `getElementById` trước) —
  khai trong shadow DOM trình duyệt bỏ qua.
- Muốn đổi style trang ngoài (thanh trên, thanh trái, font cả trang) chỉ khi khối hiện: chèn style vào head với
  selector `body:has([custom_block_name='<tên khối>']) …` — phần tử bọc khối có attribute này. Theme của site
  (`ntv/css/ntv_brand_ui.css`, font Quicksand) có `!important`, nên cần specificity cao:
  `html body:has(...) .page-container .page-head .page-head-content{background:… !important}`.
- Nới trang rộng: `[data-page-route='Workspaces'] .layout-main:has([custom_block_name='X']){max-width:100% !important}`.
- **Chuỗi CSS chèn nằm trong nháy đơn JS** → không dùng `'Segoe UI'` bên trong; viết `Segoe UI` không nháy.
- Đưa JS lên bản ghi mà không phải escape: viết `function __blk(root_element){ …code… }` rồi
  `__blk.toString().replace(/^function __blk\(root_element\)\s*\{\n?/, '').replace(/\}\s*$/, '')`.
- Sửa nhỏ: GET bản ghi → `script.replace(chuỗi cũ, chuỗi mới)` → kiểm `new Function('root_element', script)`
  (bắt lỗi cú pháp) → PUT. Áp thử ngay không cần tải lại: tìm host
  `[...document.querySelectorAll('*')].find(e => e.shadowRoot && e.shadowRoot.querySelector('.kd'))`,
  đổi `host.shadowRoot.querySelector('style').textContent`.
- Khối tự chạy lại mỗi lần mở workspace; không có state bền — dùng `state.cache` trong đóng bao (IIFE).
- Hai khối nói chuyện với nhau qua `window.dispatchEvent(new CustomEvent('ten-su-kien', {detail}))`.

## 3. Workspace Sidebar — thanh trái (và là đích của ô Desktop)

- Mỗi workspace public "đàng hoàng" có một `Workspace Sidebar` cùng tên (CEO có sidebar "CEO"). autoname
  `field:title` → **title = name**, cũng bị dịch như trên.
- Fields: `title`, `header_icon`, `for_user`, `module`, `standard`, `app` (Autocomplete tên app),
  `items` (Workspace Sidebar Item): `type` Link | Section Break | Spacer | Sidebar Item Group; `link_type`
  DocType | Page | Report | Workspace | Dashboard | URL; `link_to` / `url`; `label`; `icon` (tên icon Frappe, ví dụ
  `dashboard users chart user file share video flag setting check`; tên lạ → ô trống, không lỗi).
- Người dùng chọn thanh trái ở ô trên cùng bên trái; "Bàn của tôi" = sidebar `My Workspaces-<email>` (1 bản/người,
  chứa các workspace private của họ). Đổi tên workspace thì phải sửa `label`/`link_to` trong đó.
- Sau khi tạo/sửa sidebar: gọi `frappe.sessions.clear` (Settings → Reload) rồi tải lại, thanh trái mới hiện.

## 4. Desktop Icon — ô trên màn Desktop (`/desk/desktop`)

- Fields: `label` (= name), `icon_type` Link | Folder | App, `link_type` **Workspace Sidebar** | External,
  `link_to` = tên sidebar (route = slug tên sidebar → sidebar tên "Marketing & Kinh Doanh" cho URL
  `/desk/marketing-&-kinh-doanh`, còn workspace lại là `/desk/marketing` → lệch!), `app`, `icon`, `logo_url`,
  `standard`, `hidden`, `bg_color` (gray | blue).
- Danh sách ô lấy từ `frappe.boot.desktop_icons`, **cache cấp site**: tạo icon mới xong `frappe.sessions.clear`
  vẫn không hiện; phải chờ hết cache hoặc `bench clear-cache` (anh Bình / lần deploy sau). Báo trước cho người dùng.
- Kết luận thực dụng: **đặt tên Workspace = tên Workspace Sidebar = tên Desktop Icon** ngay từ đầu.

## 5. Quyền & kiểm duyệt

- Tài khoản dựng bàn cần System Manager + Workspace Manager (tài khoản mk.mktnbrands@ có). Người xem chỉ cần
  quyền đọc DocType nguồn; khối REST 403 sẽ hiện "Không tải được" thay vì số.
- Bộ kiểm duyệt của Claude Code có thể chặn ngẫu nhiên các thao tác POST/PUT lên prod, nhất là khi trông giống
  xóa. Cách ứng xử: dừng, nói rõ định làm gì, xin một câu cho phép; hoặc hướng dẫn người dùng bấm Edit trên
  Workspace tự thêm/bỏ khối (1 phút).
- `frappe.sessions.clear` là cách xóa cache phiên an toàn; không đụng System Settings để "clear cache".

## 6. Frappe REST — cú pháp hay dùng

```js
const H = { 'Content-Type': 'application/json', 'X-Frappe-CSRF-Token': frappe.csrf_token, 'X-Requested-With': 'XMLHttpRequest' };
// gộp số: fields dạng dict, KHÔNG viết "sum(x) as y"
'/api/resource/eShop Invoice?fields=' + encodeURIComponent(JSON.stringify(['sale_channel', {COUNT:'name'}, {SUM:'actual_amount'}]))
  + '&group_by=sale_channel&filters=' + encodeURIComponent(JSON.stringify([['report_date','>=',from],['report_date','<=',to]]))
  + '&limit_page_length=500';
// kết quả: row['SUM(`actual_amount`)'], row['COUNT(`name`)'], row['MAX(`day`)']
// group_by nhiều cột: group_by=report_date,sale_staff,cashier (chuỗi, phẩy)
// toán tử: 'is' 'not set' | 'like' '%x%' | 'not like' | 'in' [..] | 'Between' [a,b] | 'Timespan'
// đếm: /api/method/frappe.client.get_count?doctype=X&filters=[...]
// Single: /api/resource/<DocType>/<DocType>
// method GET của app: /api/method/<app>.api.<module>.<fn>?a=1 → kết quả trong .message ; /api/resource → .data
// lấy danh sách field: /api/method/frappe.desk.form.load.getdoctype?doctype=X → docs[0].fields
// Query Report: frappe.desk.query_report.run {report_name, filters} (SQL phải escape % thành %%; prod MariaDB 10.6)
```

Insights (workbook/query/chart) và Query Report là đường khác cho người không muốn viết JS; bàn Hưng chọn
Custom HTML Block vì cần bố cục tự do và số ghép từ nhiều nguồn.

## 7. Thanh trái theo khối + trượt tới khối (bổ sung 05/09/2026)

Anh Hưng chốt: thanh trái = danh sách các khối trên bàn (mục URL `/desk/<bàn>#<id>`), báo cáo chi tiết xếp
xuống một Section Break bên dưới. Bấm mục nào trang trượt tới khối đó, cuộn tới đâu ô đó sáng.
Mã sẵn: `assets/templates/dieu-huong-thanh-trai.js` (dán vào cuối script khối đầu). Bẫy đã cắn:
- **Phần cuộn là `.main-section`**, không phải `window` (`window.scrollTo` không nhúc nhích).
- `scrollTo({behavior:'smooth'})` **không chạy** trên `.main-section` → tự viết bằng `requestAnimationFrame` + easeOutCubic
  (350–900ms theo quãng đường). Tab đang ẩn thì rAF không chạy → nhảy thẳng.
- `.page-head` (thanh đỏ) **không dính**: `bottom` âm khi cuộn, chỉ dùng `height` (49px) làm khoảng trừ.
- Muốn không tải lại trang phải chặn click ở capture phase kèm `stopImmediatePropagation()` → Frappe **không tô ô đang
  chọn nữa**, phải tự toggle `.standard-sidebar-item.active-sidebar`.
- Đích trong shadow DOM: tìm qua `hosts.find(e => e.shadowRoot.querySelector(id))`. Khối khác thì đặt `id` lên div gốc.
- Khối cuối trang không bao giờ lên tới vạch → chạm đáy thì sáng mục cuối.
- Sửa script rồi `location.href = cùng URL` **không tải lại** (chỉ đổi hash) → dùng `location.reload()`.

## 8. Ô Desktop trỏ sai — bài học name = title (05/09/2026)

`frappe.utils.get_route_for_icon` dựng link ô "Bàn của tôi" từ `frappe.workspaces[slug(link_to)]`: public → `slug(name)`,
còn lại → `slug(title)`. Title "Marketing & Kinh Doanh" trong khi name "Marketing" → link `/desk/marketing-&-kinh-doanh` 404.
Luật: **Workspace name = title = tên Workspace Sidebar = label Desktop Icon.** Đổi tên hiển thị thì chấp nhận bị dịch,
không tách title.

## 9. Đường ghi khi Chrome mất kết nối: MCP fac-prod (07/09/2026)

Server MCP `fac-prod` (tài khoản mk.mktnbrands) có `get_document / create_document / update_document / list_documents`.
- Tạo khối: `create_document('Custom HTML Block', {__newname, name, private:0, html, style, script, roles:[]})`.
- Sửa Workspace: `update_document('Workspace', name, {content: <chuỗi JSON>, custom_blocks: [...]})` — child table ở
  **chế độ patch**: dòng có `name` được cập nhật, dòng không `name` được thêm, dòng không nhắc tới giữ nguyên.
- Đổi thứ tự items của Workspace Sidebar: gửi **toàn bộ** mảng không kèm `name` (chế độ thay).
- Sau đó vẫn phải Settings → Reload hoặc tải lại trang để thấy.
Không có screenshot khi đi đường này → nhờ người dùng tải lại và mô tả, hoặc chờ Chrome nối lại.

## 10. Khối có ghi: Ghi chú & Việc (07/09/2026)

Ngoại lệ duy nhất của luật "khối chỉ đọc", theo mẫu bàn CEO của anh Bình. Không tạo DocType mới:
- **Ghi chú** = `Comment` (`comment_type: Comment`, `reference_doctype: Workspace`, `reference_name: <bàn>`), ghi qua
  `frappe.desk.form.utils.add_comment` (POST, cần `X-Frappe-CSRF-Token`).
- **Việc** = `ToDo` (`reference_type: Workspace`, `reference_name: <bàn>`, `allocated_to`, `date`, `status Open|Closed`),
  tạo bằng POST `/api/resource/ToDo`, tick xong = PUT `status: Closed`. Người được giao thấy trong "Việc của tôi" và nhận
  thông báo ERP sẵn có.
- Danh sách người để giao: `User` với `enabled=1, user_type=System User`.
- Mã sẵn: `assets/templates/ghi-chu-viec.{html,css,js}` (đổi `REF.name`). ⚠️ Chưa kiểm quyền bình luận lên Workspace
  của tài khoản không phải System Manager — nếu 403 thì đổi nơi gắn (ví dụ ToDo không reference, hoặc một Note).
