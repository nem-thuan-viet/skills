---
name: so-tay-erpnext-ntv
description: Sổ tay Frappe/ERPNext THỰC CHIẾN của Nệm Thuần Việt — kiến trúc 5 tầng, cheatsheet ORM/REST/Client JS đã kiểm chứng trên hệ nhà, Workspace v16, cách ship app lên prod Frappe Cloud, và ~40 bẫy đã trả giá thật (đánh số). Dùng BẤT CỨ KHI NÀO code / sửa / debug / viết script đụng ERPNext của NTV — viết Python chạy trong site, gọi REST API prod, tạo DocType / Workspace / Number Card / Dashboard Chart, deploy app, hay gặp lỗi lạ trên desk. Đọc TRƯỚC khi viết dòng code Frappe đầu tiên của phiên, và tra lại khi đụng đúng mảng.
---

# HƯỚNG DẪN FRAPPE / ERPNEXT — sổ tay làm việc nhanh (NTV)

> Đúc từ **mã nguồn thật đang chạy** (frappe 16.26.3 · erpnext 16.26.2 trong container local)
> + kinh nghiệm thực chiến dự án (app `ntv_cockpit`, app nền `ntv`, 13 bẫy đã gặp).
> Người đọc: mọi người trong org `nem-thuan-viet` + Claude của mỗi người. Cập nhật: 16/07/2026 · mục 7 Workspace viết lại 30/08/2026 (workflow học 10 agent, có phản biện).

---

## 1. BỨC TRANH LỚN — 5 tầng

```
bench  (công cụ CLI + thư mục cài đặt: apps/ + sites/ + env/)
 └─ site  (1 database riêng, vd "ntv" local · platform.nemvietnhat.net prod)
     └─ app  (gói code Python+JS: frappe, erpnext, hrms, ntv, ntv_cockpit…)
         └─ module  (ngăn kéo trong app: Manufacturing, Buying, NTV Cockpit…)
             └─ doctype  (1 "bảng + form + API" — đơn vị nhỏ nhất, quan trọng nhất)
```

- **frappe** = framework (ORM, REST, phân quyền, desk UI, scheduler, email). **erpnext** = app nghiệp vụ xây trên frappe.
- 1 site cài nhiều app; user vào 1 địa chỉ thấy tất cả. Local mình: site `ntv`, 13 app (xem `sites/apps.txt`).
- ERPNext v16 có 21 module; liên quan NTV nhất: **Manufacturing** (50 doctype), **Buying** (22), **Stock** (79), **Selling** (20), **Accounts** (193).

## 2. DOCTYPE — trái tim của mọi thứ

Tạo 1 DocType là được NGAY: bảng DB (`tab<Tên>`), form nhập liệu, list view, REST API, phân quyền. Cấu trúc file (xem mẫu thật `erpnext/manufacturing/doctype/work_order/`):

```
work_order.json   ← định nghĩa fields, quyền, autoname (nguồn chân lý)
work_order.py     ← controller: class WorkOrder(Document) + hook nghiệp vụ
work_order.js     ← form script (UI động phía client)
work_order_list.js / _dashboard.py / test_work_order.py  ← tùy chọn
```

**Field types hay dùng:** Data, Small Text, Text/Long Text, Int, Float, **Currency**, Percent, **Date**, Datetime, Check (0/1), Select (options xuống dòng), **Link** (khóa ngoại → DocType khác), Dynamic Link, **Table** (child table → 1 DocType `istable=1`), Attach, JSON.

**Autoname:** `hash` (mã ngẫu nhiên — 11 doctype NTV dùng cái này), `field:<fieldname>` (vd Dashboard Chart = `field:chart_name`), `naming_series` (SX-.####), `prompt` (user tự đặt), format `PUR-.YYYY.-.####`.

**Lifecycle hooks trong controller** (thứ tự thật từ `frappe/model/document.py`):
```
before_validate → validate → before_save → [ghi DB] → on_update → after_insert (lần đầu)
docstatus:  0=Draft → 1=Submitted (on_submit) → 2=Cancelled (on_cancel)
```
Mẫu thật Work Order: `validate()` gọi lần lượt validate_dates/validate_operations_sequence/validate_sales_order… — mỗi rule 1 hàm nhỏ, dễ đọc. Học theo pattern này.

**Custom DocType** (cách NTV đang dùng cho SX Gia Thanh, Mua Chi Tiet…): tạo bằng script `frappe.get_doc({"doctype":"DocType", "custom":1, ...}).insert()` — nằm trong DB, không cần file app. Nhanh, nhưng muốn version-control thì chuyển thành DocType trong app (file .json).

## 3. ORM PYTHON — cheatsheet (dùng hằng ngày)

```python
import frappe

# ĐỌC
doc  = frappe.get_doc("Work Order", "MFG-WO-0001")     # cả doc + child tables
rows = frappe.get_all("SX Gia Thanh",                   # list nhanh (bỏ qua quyền)
        filters={"ky": "2026-05-01", "nhom_chinh": ["like", "Nệm%"]},
        fields=["ma_sp", "sum(tong_gia_thanh) as tg"],
        group_by="ma_sp", order_by="tg desc", limit=10)
val  = frappe.db.get_value("Item", "SKU-001", "item_name")
n    = frappe.db.count("Mua Chi Tiet", {"nhom": "Quảng cáo"})
raw  = frappe.db.sql("SELECT ... FROM `tabSX Gia Thanh` WHERE ky=%(ky)s",
                     {"ky": ky}, as_dict=True)          # SQL thô khi cần group phức tạp

# GHI
doc = frappe.get_doc({"doctype": "SX Gia Thanh", "ky": "2026-06-01", ...})
doc.insert(ignore_permissions=True)
frappe.db.set_value("SX Gia Thanh", name, "nhom_chinh", "Nệm mút")  # nhanh, KHÔNG chạy validate
doc.save() / doc.submit() / doc.cancel()
frappe.delete_doc("DocType", name, force=True)
frappe.db.commit()        # script ngoài request PHẢI tự commit

# API cho client gọi
@frappe.whitelist()        # mặc định cần đăng nhập; allow_guest=True nếu public
def sx_dashboard(ky=None): ...
```

**⚠ BẪY `%` trong db.sql** (đã đổ máu): KHÔNG truyền values → viết `%` đơn (`DATE_FORMAT(ky,'%Y-%m')`); CÓ truyền values dict → phải `%%`. Truyền dict RỖNG cũng tính là "có" → lỗi.

**Script chạy trong container** (pattern chuẩn dự án):
```python
import frappe
frappe.init(site="ntv", sites_path="."); frappe.connect(); frappe.set_user("Administrator")
# ... làm việc ... rồi frappe.db.commit()
```
```bash
docker cp script.py "$B":/tmp/ && docker exec -u root "$B" chmod a+r /tmp/script.py
docker exec -w /home/frappe/frappe-bench/sites "$B" ../env/bin/python /tmp/script.py
```

## 4. REST API — làm việc với PROD (token cá nhân CỦA BẠN)

⚠️ **PROD = `https://platform.nguoithuanviet.com` — GÕ THẲNG URL này.** ĐỪNG dùng biến môi trường
kiểu `NTV_PROD_URL` chưa kiểm: nhiều máy biến này còn trỏ **máy chủ CŨ** `platform.nemvietnhat.net` —
máy cũ VẪN SỐNG, VẪN NHẬN TOKEN prod, đọc/ghi nhầm mà không báo lỗi nào.

Token: **mỗi người tự sinh token của mình** (desk → My Settings → API Access → Generate Keys),
cất vào file env riêng ngoài git, `chmod 600`. CẤM dùng chung token người khác, cấm dán token vào code/chat.

```bash
PROD=https://platform.nguoithuanviet.com
AUTH="Authorization: token $API_KEY:$API_SECRET"   # nạp 2 biến này từ file env riêng của bạn

# 1) /api/resource — CRUD trực tiếp DocType
curl -s "$PROD/api/resource/Item?filters=[[\"brand\",\"=\",\"Nệm Thuần Việt\"]]&fields=[\"name\",\"item_name\"]&limit_page_length=20" -H "$AUTH"
curl -s "$PROD/api/resource/Item/SKU-001" -H "$AUTH"                    # 1 doc
curl -s -X POST "$PROD/api/resource/ToDo" -H "$AUTH" -H "Content-Type: application/json" -d '{"description":"..."}'   # tạo (cẩn thận prod!)

# 2) /api/method — gọi hàm whitelist
curl -s "$PROD/api/method/frappe.client.get_count?doctype=User" -H "$AUTH"
curl -s "$PROD/api/method/frappe.client.get_value?doctype=Item&fieldname=item_name&filters={\"name\":\"SKU-001\"}" -H "$AUTH"
```
Các hàm sẵn trong `frappe.client`: `get_list, get_count, get, get_value, get_single_value, set_value, insert, insert_many, save, rename_doc…`
**Nguyên tắc dự án: prod mặc định CHỈ ĐỌC** — ghi/sửa chỉ khi được giao rõ, và tuân nội quy repo (việc đụng sổ sách/tiền đi qua anh Bình). Bẫy đo thật: URL có khoảng trắng phải encode `%20` (không encode là trả RỖNG im lặng); filters có `[]` thì curl phải thêm `-g`.

## 5. CLIENT JS + DESK PAGE (pattern đã thực chiến ở `ntv_cockpit`)

```javascript
// gọi API từ desk
frappe.call({ method: "ntv_cockpit.api.sx_dashboard", args: { ky: "" } })
      .then(r => r.message);

// desk Page tối thiểu: page/<ten_page>/<ten_page>.{json,js}
frappe.pages['ntv-sx-cockpit'].on_page_load = function (wrapper) {
  const page = frappe.ui.make_app_page({ parent: wrapper, title: '...', single_column: true });
  $(page.body).append('...html...');
};
```
**⚠ BẪY tên Page (bẫy 10):** thư mục/file dùng **gạch dưới** (`page/ntv_sx_cockpit/ntv_sx_cockpit.js`), còn `name` trong json + `frappe.pages['...']` dùng **gạch ngang** (`ntv-sx-cockpit`). Route: `/desk/ntv-sx-cockpit` (v16 dùng `/desk`, `/app` redirect sang).

Form script (khi cần custom form DocType chuẩn): `frappe.ui.form.on("Work Order", { refresh(frm) {...}, ten_field(frm) {...} })`.

## 6. MODULE ERPNEXT LIÊN QUAN NTV (để tận dụng thay vì tự chế)

| Nhu cầu NTV | DocType chuẩn ERPNext | Ghi chú |
|---|---|---|
| Lệnh sản xuất | **Work Order** (+ Job Card, Workstation, Operation) | ta đang có `SX Lenh San Xuat` custom — về sau map được |
| Định mức | **BOM** (BOM Item con) | `SX Dinh Muc NVL` custom tương ứng |
| Mặt hàng/SKU | **Item** (+ Item Group, Brand, UOM) | app nền `ntv` của Bình quản SKU |
| Nhà cung cấp | **Supplier**, Supplier Quotation, **Purchase Order/Receipt/Invoice** | `Mua Bao Gia`/`Mua Gia Lich Su` mô phỏng Supplier Quotation + Item Price |
| Giá | **Item Price** (valid_from/valid_upto, price_list) | mô hình mà `mua_gia_lichsu` bắt chước |
| Kho | Warehouse, Stock Entry, Stock Ledger Entry | |
| Chất lượng/lỗi | Quality Inspection | tương lai cho tab Bảo hành |

Đường tiến hóa: dữ liệu custom (nạp nhanh, phân tích) → dần chuyển vào DocType chuẩn để hưởng nghiệp vụ có sẵn (tồn kho, công nợ, submit/cancel).

## 7. WORKSPACE (Frappe v16) — trang điều hướng desk

> Đúc từ mã nguồn thật trong container `erpnext-demo-backend-1` (frappe 16.26.3 · erpnext 16.26.2, `bench version` 30/08/2026), thực hành tạo–sửa–xóa workspace `NTV Hoc Thu` trên site `ntv`, và diff với tag GitHub v16.29.0/v16.30.0 (prod).

### Khái niệm

Workspace = trang đầu tiên khi vào desk, mỗi trang là 1 bản ghi DocType `Workspace` gồm nội dung (`content` JSON block) + các bảng con widget. **Public** (mọi user desk thấy, chỉ role *Workspace Manager* sửa được) hoặc **private** (`for_user` = 1 user, chỉ chủ nhân thấy — kể cả Administrator không thấy của người khác, đã test). Site LAB `ntv` đang có 58 workspace, trong đó 2 cái của mình: `ntv-san-xuat`, `ntv-mua-hang`. **Đổi lớn v16:** thanh bên trái KHÔNG dựng từ cây `parent_page` nữa mà từ DocType riêng `Workspace Sidebar` + `Workspace Sidebar Item` (module chưa có sidebar DB thì boot tự sinh bản in-memory từ Module Def — `workspace_sidebar.py:237-251`). Route desk là `/desk`, `/app` chỉ redirect 301 (đã curl, không vỡ link cũ).

### Cấu trúc DocType Workspace

File: `apps/frappe/frappe/desk/doctype/workspace/workspace.json` + `workspace.py`.

- **Autoname `field:label`** → name = label. Field chính: `title` (reqd), `sequence_id` (Float — thứ tự sidebar), `for_user` (**Data**, không phải Link User), `parent_page` (Link Workspace — chỉ dialog dùng, UI cho tối đa 2 cấp), `module` + `app` (app TỰ SUY từ module trong `validate()`), `public` (Check, **read_only trên form**), `is_hidden`, `hide_custom` (=0 thì tự đắp card "Custom Documents/Reports" của module), `icon`, `indicator_color`, `content` (chuỗi JSON list). v16 thêm `type` (Workspace/Link/URL) + `link_type`/`link_to`/`external_link` — 1 dòng Workspace có thể chỉ là cái link (cây điều hướng tiếng Việt 10 folder của NTV đang dùng kiểu này).
- **6 child table widget + roles:** `links` (Workspace Link — 2 kiểu dòng: `Card Break` mở thẻ + `Link` trỏ DocType/Page/Report), `shortcuts`, `charts`, `number_cards`, `quick_lists`, `custom_blocks`, và `roles` (Has Role — giới hạn theo role).
- **content** = JSON list block kiểu editorjs, 10 type có thật (`public/js/frappe/views/workspace/blocks/`): header, paragraph, card, chart, number_card, shortcut, quick_list, custom_block, spacer, onboarding. `col` = độ rộng lưới 12 cột. Block chỉ là CON TRỎ theo tên:

```json
{"id":"WeKMsoeisv","type":"number_card","data":{"number_card_name":"Open Work Orders","col":4}}
```

- **Luật đồng bộ content ↔ child table:** client khớp block với dòng child theo **LABEL đã qua hàm dịch `__()`** (`blocks/block.js:9`). Bấm Save trên desk chạy `clean_up()` (`desktop.py:539-559`): mọi dòng child có label KHÔNG xuất hiện trong content bị XÓA; ngược lại block trỏ label không có dòng child → render div rỗng im lặng (`chart.js:34-37`). Không validation nào chặn — LAB đang có sẵn 3 ca desync thật (Payroll nhân đôi 14 Card Break, CRM card "Masters" tàng hình, Home shortcut "Leaderboard" mồ côi).

### Hai con đường tạo workspace

**(a) Trên desk / script — để THỬ NHANH trên LAB.** Nút Edit → Builder, hoặc script ORM. Bản ghi tạo kiểu này sống trong DB site, `module=''`/`app=''` → deploy KHÔNG mang đi. 2 workspace `ntv-san-xuat`/`ntv-mua-hang` hiện đi đường này (script `erpnext-setup/ntv-data/build_ws.py`, cố ý `module=""` để né orphan-removal — xem B27).

**(b) File JSON trong module của app — đường CHUẨN lên prod Frappe Cloud.** Đặt tại `<app>/<module>/workspace/<tên_scrub>/<tên_scrub>.json` (mẫu thật: `apps/erpnext/erpnext/manufacturing/workspace/manufacturing/manufacturing.json`). `bench migrate` (= mỗi lần bấm Deploy) tự sync — Workspace nằm trong `IMPORTABLE_DOCTYPES` (`model/sync.py:35-36`), **force=0**: chỉ đè khi `modified` trong file MỚI HƠN trong DB (`modules/import_file.py:122-142`). File tồn tại = miễn nhiễm orphan-removal + có version control. **CẤM ship qua fixtures** (B28).

**Chuyển (a) → (b)** — trình tự an toàn (sync chạy TRƯỚC orphan-removal trong cùng migrate: `migrate.py:142` vs `:191`): export file với `name` giữ nguyên + `module='NTV Cockpit'` + `modified` bump mới hơn bản DB prod, đưa file vào app rồi Deploy MỘT lần. TUYỆT ĐỐI không gán module vào DB trước khi file có mặt trong bản deploy. Export không cần developer_mode:

```python
# trong bench console (LAB)
from frappe.modules.export_file import export_to_files
export_to_files(record_list=[["Workspace", "ntv-san-xuat"]], record_module="NTV Cockpit")
```

### Cheatsheet — đã chạy thật trên LAB (chặng thực hành 30/08)

```python
# TẠO bằng ORM (script pattern §3): nhớ tự set sequence_id — insert thô ra None
ws = frappe.new_doc("Workspace")
ws.update({"label": "NTV Hoc Thu", "title": "NTV Hoc Thu", "public": 1,
           "sequence_id": 25, "content": json.dumps(blocks)})   # content = CHUỖI JSON
ws.append("links", {"type": "Card Break", "label": "Thẻ SX học thử", "link_count": 2})
ws.append("links", {"type": "Link", "label": "Work Order", "link_type": "DocType", "link_to": "Work Order"})
ws.insert(); frappe.db.commit()

# VERIFY bằng đúng hàm desk dùng thật (get_workspace_sidebar_items đã CHẾT ở v16 — ImportError)
from frappe.desk.desktop import get_workspaces, get_desktop_page
get_workspaces()                       # trả {pages,...} — LUÔN = số DB trừ 1 (Welcome Workspace)
get_desktop_page(json.dumps({"name": "NTV Hoc Thu", "title": "NTV Hoc Thu", "public": 1}))

# SỬA đúng cơ chế edit mode: truyền LẠI TOÀN BỘ blocks + new_widgets là CHUỖI JSON
from frappe.desk.doctype.workspace.workspace import save_page
save_page("NTV Hoc Thu", 1, json.dumps({"shortcut": [{"type": "DocType",
    "label": "Lệnh SX học thử", "link_to": "Work Order", "doc_view": "List"}]}), blocks_str)

# XÓA (public): dọn sạch child rows theo parent — đã verify 4 tầng
frappe.delete_doc("Workspace", "NTV Hoc Thu"); frappe.db.commit()

# KIỂM SIDEBAR v16
frappe.db.exists("Workspace Sidebar", "My Workspaces")   # site ntv: CÓ (48 sidebar tổng)
```

```bash
# Verify HTTP thật (cổng 8080, site default — không cần Host header)
docker exec erpnext-demo-backend-1 bench --site ntv browse --user Administrator   # lấy sid
curl -s -H "Cookie: sid=..." http://localhost:8080/api/method/frappe.desk.desktop.get_workspaces
# get_desktop_page qua HTTP: body là JSON-lồng-JSON  {"page": "{\"name\": \"NTV Hoc Thu\"...}"}
```

### 5 loại widget gắn vào workspace

- **Shortcut** — nút nhảy nhanh tới DocType/Report/Page/Dashboard/URL, có bộ đếm: `stats_filter` (JSON) + `format` `"{} phiếu chờ"` (qua `__()`, viết tiếng Việt được — `shortcut_widget.js:104`). Tạo ngay trong Builder; gắn = dòng child `shortcuts` + block `shortcut` trỏ label.
- **Card links** — cụm link điều hướng: bảng `links` = 1 dòng `Card Break` (tên thẻ, `link_count`) + N dòng `Link`; block `card` trỏ `card_name` = label của Card Break. Manufacturing chuẩn: 6 card / 40 dòng links.
- **Number Card** — DocType riêng, **name = label** (chuỗi tiếng Việt được); 3 type: Document Type (server COUNT/SUM/AVG/MIN/MAX qua `get_list` + filters), Report (tính ở client), Custom (gọi hàm whitelisted tự viết). Tạo trên desk hoặc fixture; gắn = child `number_cards` + block.
- **Dashboard Chart** — autoname `field:chart_name`; `number_of_groups` của chart Group By chỉ cắt ở FRONTEND (`chart_widget.js` maxSlices), server trả hết; `chart_type` Count/Sum/Average/Group By/Custom/Report, kiểu vẽ Line/Bar/Pie/Donut/Percentage/Heatmap, có bảng `roles` RIÊNG. Gắn = child `charts` + block `chart`.
- **Quick List** — danh sách 4 bản ghi mới nhất của 1 doctype (`quick_list_widget.js:229`), `quick_list_filter` JSON; người xem đổi filter tại chỗ được (không lưu). Gắn = child `quick_lists` + block.

### Quyền & hiển thị — 3 cổng, kiểm bằng user thường

1. **Sửa public = role Workspace Manager** (`workspace.py:77-78` throw thẳng; rename/xóa cũng vậy). Trên LAB chỉ Administrator + tài khoản quản trị có role này — user thường KHÔNG có; test phân quyền bằng admin là vô nghĩa vì Workspace Manager bỏ qua MỌI lọc.
2. **Bảng `roles` rỗng = mọi user desk đều qua cổng role** (`desktop.py:59` — `if not allowed: return True`); muốn giới hạn thì thêm dòng Has Role. Cả 58 workspace trên LAB đều để rỗng.
3. **Cổng thật chặn user thường là `allowed_modules`**: workspace CÓ module mà user không có quyền đọc DocType nào của module đó → PermissionError/mất trang (`desktop.py:38-44`). `module=''` né được cổng này — đã verify: `thu.to-may@ntv.test` thấy `NTV Hoc Thu` NGAY, không dính cache quyền 6h.

`is_hidden=1`: public ẩn với non-manager. `for_user` set: private, chỉ chủ nhân. Sidebar trái còn cổng thứ 4: chỉ hiện khi user thấy ≥1 item không phải Section Break — sidebar `ntv-san-xuat` toàn DocType `SX *`, user không đọc được SX* thì mất sidebar dù vẫn mở được trang.

### LAB vs prod

Đã diff tag v16.29.0/v16.30.0: workspace.json + toàn bộ JS client **identical**, manufacturing/stock/buying.json identical — học trên LAB áp thẳng prod được. Khác biệt duy nhất va phải: `save_page` trên LAB 16.26.3 bắt `new_widgets` là CHUỖI JSON (`loads`), prod 16.29 nhận cả dict (`frappe.parse_json`) → luôn `json.dumps()` cho chạy được cả hai.

### Bẫy (tiếp chuỗi sổ tay, B27→)

- **B27 — Deploy xóa workspace âm thầm:** mỗi migrate chạy `remove_orphan_entities()` (`migrate.py:191`) xóa Workspace `public=1 + module set + app set` không có file JSON trong app; `validate()` TỰ điền app từ module. `ntv-san-xuat`/`ntv-mua-hang` sống nhờ `module=''` (operator `is set` = `key != ""` — `operator_map.py:111-118`) — **ai mở form gán module rồi lưu là Deploy kế tiếp mất trang.** Vòng dọn này quét cả Dashboard/Page/Report/Notification standard + Workspace Sidebar/Desktop Icon cấp app.
- **B28 — CẤM `fixtures = ["Workspace"]`:** fixture import force=True đóng dấu app rồi orphan-removal xóa nó trong CÙNG lần migrate — NTV đã trả giá, ghi tại `ntv_cockpit/hooks.py:285-289`.
- **B29 — Desync content↔child hỏng im lặng 2 chiều:** chèn dòng child bằng script không kèm block → Save kế tiếp `clean_up()` xóa sạch; block trỏ label sai → div rỗng. So desync phải so theo LABEL đã dịch, không theo `chart_name` (so sai khóa ra 15 lỗi ảo vs 1 lỗi thật).
- **B30 — `save_page` phải truyền LẠI TOÀN BỘ blocks** (thiếu là widget cũ bị `clean_up` xóa) và `new_widgets` phải `json.dumps` (LAB nổ TypeError thật khi truyền dict).
- **B31 — Insert ORM thô:** `sequence_id` ra None (chỉ `new_page` tự tính) và KHÔNG sinh Workspace Sidebar/Desktop Icon → workspace public mới không tự hiện trên sidebar trái v16.
- **B32 — `new_page` với public=1 mà user thiếu Workspace Manager → RETURN NONE ÂM THẦM** (`workspace.py:301-302`), không throw — script tưởng tạo xong.
- **B33 — Ship "thành công" mà prod không đổi:** import force=0 SKIP im lặng khi `file.modified <= db.modified` (`import_file.py:122-142`). Prod đã chạy `build_ws.py` nên bản DB prod có modified riêng — file export phải bump modified mới hơn.
- **B34 — `build_ws.py` đã lỗi thời:** nó xóa-force rồi insert bản gốc 1 header + 5-6 shortcut, trong khi DB đã tiến hóa lên 27 block (modified 19/08) — **chạy lại là reset mất sạch**; script cũng KHÔNG tạo sidebar (2 sidebar LAB tạo tay 14/07). Cấm chạy lại.
- **B35 — Xóa private workspace sót vệt:** `delete_doc` không xóa Workspace Sidebar Item trỏ tới nó trong `My Workspaces-{user}` (test thật còn item mồ côi) — phải dọn tay. Xóa public thì sạch.
- **B36 — Đếm lệch 1:** `get_workspaces()` = số DB trừ `Welcome Workspace` (hardcode loại theo TITLE — `desktop.py:402`); đặt title trùng chữ này là trang biến mất khỏi sidebar.
- **B37 — Fixture Number Card/Dashboard Chart force=True:** mỗi lần BẤT KỲ AI trong 7 kho bấm Deploy, 12 card + 9 chart module NTV Cockpit bị file trong git đè — file fixtures là nguồn sự thật duy nhất, cấm chỉnh 2 loại này trên desk prod.
- **B38 — `parent_page` KHÔNG dựng sidebar v16:** grep toàn bộ JS chỉ thấy nó trong dialog Create/Edit; sidebar dựng từ Workspace Sidebar Item (`child`/`indent`). UI cũng chỉ cho lồng 2 cấp (`workspace.js:817-836`).
- **B39 — Xóa workspace chuẩn erpnext là vô ích:** migrate kế tiếp tái sinh nguyên bản từ file trong app (doc đã xóa → db_modified=None → import lại). Muốn giấu dùng `is_hidden=1`.
- **B40 — `before_export` ÉP name=label=title** (`workspace.py:131-133`): export workspace là bị đổi danh tính theo title — nên đặt title làm name ngay từ đầu (chuẩn nhà: app `ntv` ship `Đơn mua hàng`… unicode, chạy tốt trên Frappe Cloud). Đổi tên thì `rename_doc` CẢ Workspace lẫn Workspace Sidebar (sidebar chuẩn trùng title). Đã trả giá 30/08: 2 trang cockpit phải rename `ntv-san-xuat`→`NTV · Sản xuất` mới ship được.
- **B42 — Desktop v16 (trang chủ /desk) & nút Reset:** bố cục icon trang chủ là DocType `Desktop Layout` — MỖI USER MỘT BẢN GHI (autoname theo user, field `layout` JSON: folder gộp + icon, `parent_icon` = nằm trong folder nào). Nút "Reset Desktop Layout" trên avatar = XÓA bản ghi của user đó → icon xổ hết ra rời rạc (đã dính thật 03/09). Bố cục chuẩn được phát đồng loạt 48 user 02/09/2026 — khôi phục = copy `layout` từ một user đang đúng bố cục sang bản ghi của user mất. Icon "Bàn của tôi" = Desktop Icon chuẩn `My Workspaces` (app frappe) — CHỈ hiện khi sidebar `My Workspaces-<user>` tồn tại và có ≥1 item (tạo private workspace bằng ORM/REST thô thì PHẢI tự tạo sidebar này kèm item — B31 bản private, dính thật 03/09). Danh sách icon cache per-user key `desktop_icons`; muốn xóa cache của user khác từ xa: lưu lại User đó (User.on_update → frappe.clear_cache(user)) — NHỚ kiểm role_profile trước khi lưu (bẫy 5.5 memory).
- **B41 — Gán module xong là bật cổng `allowed_modules`:** user thường chỉ thấy workspace khi ĐỌC ĐƯỢC ≥1 DocType thuộc module đó (`utils/user.py:170` — Page không tính). Module không có DocType nào = chỉ Workspace Manager thấy trang. Fix 30/08: patch dọn 22 DocType về module NTV Cockpit + role `NTV Cockpit Xem`.

### Checklist — dựng workspace "Sản xuất NTV" trong `ntv_cockpit` đúng chuẩn lên prod

1. LAB: hoàn thiện workspace trong Builder/script — **name/label kỹ thuật không dấu** (`ntv-san-xuat`), `title` tiếng Việt (`NTV · Sản xuất`), Number Card/Chart thuộc module NTV Cockpit, content ↔ child khớp label.
2. Export ra file bằng `export_to_files(..., record_module="NTV Cockpit")` (console, không cần dev-mode) → `ntv_cockpit/ntv_cockpit/ntv_cockpit/workspace/ntv_san_xuat/ntv_san_xuat.json`; kiểm field `name` trong JSON giữ nguyên `ntv-san-xuat`, `modified` MỚI HƠN bản DB prod (B33).
3. Ship kèm: `bench --site ntv export-fixtures --app ntv_cockpit` cho Number Card + Dashboard Chart (hooks.py đã filter module, an toàn); cân nhắc thêm file sidebar cấp app `ntv_cockpit/workspace_sidebar/*.json`.
4. Diễn tập trên LAB: đặt file + `bench --site ntv migrate` → workspace còn nguyên, module/app đã gán, không bị orphan-removal xóa.
5. Kiểm bằng user thường ít role (vd `thu.to-may@ntv.test`) — gán module bật cổng `allowed_modules`, trang "biến mất" là do quyền đọc DocType, không phải ship hỏng.
6. Đi đủ 5 bước GitHub (nội quy §4): `/soi-code` 🟢 → nhánh `quang/workspace-san-xuat` trong org → PR dán báo cáo soi → gộp main → Deploy (nhắn nhóm + Sao lưu trước).
7. Sau Deploy: mở desk prod kiểm trang + sidebar bằng tài khoản thường; từ nay **khóa `build_ws.py`** (B34) và cấm chỉnh card/chart trên desk prod (B37).

## 8. APP CUSTOM — tạo & deploy (quy trình NTV)

```bash
bench new-app ten_app --no-git          # scaffold (prompt: phễu printf các câu trả lời)
bench --site ntv install-app ten_app    # cài vào site
bench --site ntv migrate                # sync doctype/page từ file + chạy patches
bench build --app ten_app               # bundle assets (file .bundle.js)
bench --site ntv clear-cache
```
**Các bẫy deploy local (Docker `erpnext-demo`, apps KHÔNG mount ra host):**
- **Bẫy 13 (500 toàn site):** sau `pip install -e` app mới, gunicorn/worker KHÔNG tự nạp → **restart đủ 4 container Python** (backend, scheduler, queue-short, queue-long).
- **Bẫy 12:** `apps.txt` có thể thiếu newline cuối → nối app bằng `printf 'ten\n' >>`, đừng `echo >>`. **`patches.txt` y hệt** — dòng patch dính vào dòng comment là patch IM LẶNG không chạy (dính thật 30/08).
- **Bẫy 11 (asset 404):** `sites/assets` là SYMLINK vào image TỪNG container → asset tĩnh phải `docker cp` vào **container frontend** (`/home/frappe/frappe-bench/assets/...`); mất khi recreate frontend. Prod trị tận gốc bằng **image bake sẵn app** (Containerfile `ntv-image/` của Bình).
- JS helper dùng chung của ntv_cockpit: **nhúng thẳng vào page.js khi deploy** (`cat lib.js page.js > deploy.js`) — không phụ thuộc /assets.
- Quy trình một chiều: **local → nghiệm thu → đóng gói đẩy prod** (qua anh Bình). File của Bình sửa ở local phải báo anh ấy gộp.

## 9. LỆNH BENCH HAY DÙNG

```bash
bench --site ntv console            # REPL ipython có frappe sẵn
bench --site ntv mariadb            # vào thẳng SQL
bench --site ntv migrate            # sau khi đổi doctype file / cài app
bench --site ntv clear-cache        # đổi page JS / hooks / bootinfo
bench --site ntv clear-website-cache
bench --site ntv backup --with-files
bench --site ntv export-fixtures --app ten_app
bench --site ntv set-config -g developer_mode 0   # dự án để 0 (B27 dữ hơn khi bật)
bench --site ntv execute "frappe.db.count" --args "['User']"   # gọi 1 hàm nhanh
```

## 10. TRA CỨU MÃ NGUỒN THẬT (khi cần hiểu sâu)

Mã nguồn nằm trong container — grep trực tiếp đúng phiên bản đang chạy:
```bash
B=$(docker compose -p erpnext-demo -f pwd.yml ps -q backend)
docker exec "$B" grep -rn "def validate" apps/erpnext/erpnext/manufacturing/doctype/work_order/work_order.py
docker exec "$B" ls apps/erpnext/erpnext/<module>/doctype/
docker exec "$B" cat apps/frappe/frappe/client.py          # REST helpers
```
GitHub chỉ để xem lịch sử/PR: github.com/frappe/erpnext · github.com/frappe/frappe (nhớ chọn tag đúng version-16).

---
*Bẫy 1–13 đầy đủ + tiến độ: xem `TIEN-DO-DU-AN.md` §4. Sổ tay này là "cách làm"; TIEN-DO là "đã làm gì".*

> Bản skill phát hành từ sổ tay gốc của khối sản xuất — góp bẫy mới thì báo người giữ bản gốc bổ sung rồi phát lại, đừng sửa lệch mỗi nơi một bản.
