---
name: desk-giao-dien-frappe
description: "Tùy biến GIAO DIỆN ERPNext (Frappe v16) của Thuần Việt Platform — trang chủ desk, landing /, launcher, sidebar, màu thương hiệu, chrome desk. Hãy dùng skill này khi anh Bình nói 'làm giao diện desk', 'sửa trang chủ', 'trang chủ desk', 'đổi giao diện desk', 'sơn màu / phối màu desk', 'sửa sidebar', 'launcher', 'landing', 'desk lỗi 500', 'desk mất CSS / mất khung', 'navbar chói', 'thêm/bớt ô trên trang chủ' — kể cả khi chỉ nói 'trang này xấu, sửa lại' trong ngữ cảnh ERPNext/desk. KHÁC frontend-design/ui-ux-pro-max (web chung): skill này biết ĐÚNG chỗ sửa của desk Frappe + các bẫy 500."
---

# Giao diện Desk Frappe — Thuần Việt Platform

Nền chạy **ERPNext 16.30.0 / Frappe 16.29.0 trên Docker** (bản local: project `ntv-thu`, site `ntv.local`, **cổng 8091**; chạy thật: `platform.nguoithuanviet.com`). Đây là bản đồ "sửa gì ở đâu" cho giao diện — chi tiết đầy đủ + lịch sử ở memory [[frontend-trang-chu-erpnext]].

## Kiến trúc 2 tầng (CHỐT theo ý anh Bình)

| Route | Là gì | Sửa ở đâu |
|---|---|---|
| **`/`** | LANDING mặt tiền (marketing, dark đỏ mận) | Web Page DocType trong DB, name `thuần-việt-platform`, field **`main_section_html`** |
| **`/desk`** | Bàn làm việc thật; login vào thẳng **Trang chủ NTV** (lưới ô hồng theo phòng) | App nền **`ntv`**, Page `trang-chu` → `trang_chu.js` (data = mảng `NTV_GROUPS`) |

Xem thật (bản local): `http://localhost:8091/trang-chu` (landing) · `http://localhost:8091/desk`.

## 3 chỗ sửa giao diện — dùng đúng chỗ

1. **Nội dung trang chủ desk** (thêm/bớt/sửa ô, nhóm phòng): sửa mảng `NTV_GROUPS` trong `erpnext-setup/ntv-apps/ntv/ntv/ntv/page/trang_chu/trang_chu.js`.
2. **Chrome desk TOÀN CỤC** (màu navbar, sidebar, page-head, font, mọi tinh chỉnh CSS desk): **luôn** bỏ vào `ntv/public/js/ntv_desk.js` (khai `app_include_js` trong hooks.py). App `ntv` nạp cuối → JS thắng; selector prefix `body ` để đè theme.
3. **Landing `/`**: sửa `main_section_html` của Web Page qua bench console (xem memory).

**Màu thương hiệu**: hồng trầm gradient `#B3134B→#8E0E3B` (navbar/sidebar-header), accent `#EB2365`, dark-mode `#f0407a` qua `[data-theme="dark"]` (v16 dùng đúng attribute này). KHÔNG sơn hồng cho trạng thái OK (xanh lá cho tích cực).

## LUẬT sống còn

- **KHÔNG sửa app bên thứ 3** (frappe_theme, hrms…) → mọi override đặt trong app nền `ntv`.
- **Agent KHÔNG tự đụng nhà mới** `platform.nguoithuanviet.com` — code lên nhà mới CHỈ qua GitHub → Deploy (`docs/QUY-TRINH-NHA-MOI.md`), không chép file, không sửa trực tiếp.
- Chép vào container chỉ sống qua `restart`, **KHÔNG sống qua `compose down`** → sửa thật phải commit vào kho app `ntv`.

## Xem thử nhanh trên bản local (chép tạm, KHÔNG phải cách lên nhà mới)

```
docker cp <file> ntv-thu-backend-1:<path>          # + frontend nếu là asset
docker cp <file> ntv-thu-frontend-1:<path>
docker exec ntv-thu-backend-1 bench --site ntv.local clear-cache
docker restart ntv-thu-backend-1                   # nếu đổi hooks.py
docker exec ntv-thu-frontend-1 nginx -s reload
```

## 🔑 Mẹo vàng: agent NHÌN được desk không cần mật khẩu

```
docker exec ntv-thu-backend-1 bench --site ntv.local browse --user Administrator
```
→ trả URL kèm `sid` → mở trong Browser pane = thấy desk thật (agent bị cấm nhập mật khẩu). Trình duyệt nhớ workspace xem lần cuối (localStorage `current_page`) → mở **ẩn danh** để kiểm `/desk` vào thẳng trang chủ.

## Bẫy đã dính (đừng lặp)

- **SIDEBAR (menu trái) muốn sống qua deploy → là FILE, không phải script.** Frappe v16 có thư mục
  app-level `<app>/workspace_sidebar/*.json`, `bench migrate` tự nạp (`frappe/model/sync.py` →
  `app_level_folders`). Của mình: `ntv/workspace_sidebar/thuần_việt.json` (56 mục, `standard:1`,
  `app:"ntv"`). Đừng viết hook `after_migrate` — Frappe tự làm.
  🔴 **TÊN FILE PHẢI CÓ DẤU.** `remove_orphan_entities()` xoá mọi sidebar `standard=1` không tìm
  được file, và nó tìm theo `frappe.scrub(tên sidebar)` → chờ đúng `thuần_việt.json`. Đặt
  `thuan_viet.json` thì migrate **nạp vào rồi xoá đi ngay trong cùng một lần chạy**, chỉ để lại một
  dòng `Deleting entity` lẫn giữa hàng nghìn dòng log — loại lỗi im lặng. Tên có dấu đi qua GitHub
  an toàn: macOS (`core.precomposeunicode=true`) · git · Frappe trên Linux đều dùng NFC.
- **Nhãn sidebar KHÔNG cần dịch tay** — Frappe dịch lúc render (Selling→Bán hàng, Invoicing→Lập hóa
  đơn). Đọc `label` lưu trong DB thấy tiếng Anh mà kết luận "màn hình tiếng Anh" là **đọc sai chỗ**.
  Còn sót tiếng Anh thì thường là chuỗi app hrms chưa có bản dịch vi (Payroll · Leaves · Recruitment
  · Performance · Tenure · Tax & Benefits · HR Setup) → thêm bản dịch, đừng hardcode nhãn.

- **Tùy biến LIST VIEW của doctype app khác (Customer, Item…) — 4 bẫy đã dính 05/08/2026** (mẫu chạy được: `ntv/public/js/ntv_customer_filters.js`):
  1. `frappe.listview_settings["Customer"] = {...}` trong `app_include_js` **KHÔNG ăn** — erpnext nạp `customer_list.js` muộn hơn rồi GÁN ĐÈ cả object. Móc vào `frappe.views.ListView.prototype.setup_view` mới chắc.
  2. Đổi giá trị **standard filter** bằng `filter_area.add()` **không ăn**: `exists()` với toán tử `=` chỉ xét "ô chuẩn có giá trị hay chưa", không xét giá trị nào → nút hiện giá trị mới mà URL còn giá trị cũ. Và `remove()` trả promise TRƯỚC khi ô kịp rỗng. **Cách đúng: `page.fields_dict[fieldname].set_value(v)`** — tự lo URL + refresh.
  3. `set_value()` cũng trả promise sớm → refresh ngay sau đó vẫn gửi filter CŨ. Phải **chờ tới khi `get_value()` khớp** rồi mới `refresh()` (chờ mù bằng setTimeout là mùi race).
  4. `frappe.db.get_list` **không nhận `group_by`** — promise treo, không lỗi không kết quả. Đếm theo trường phải dùng `frappe.desk.listview.get_group_by_count`. Với Link-**cây**, ô lọc chuẩn lọc `descendants of (inclusive)` nên **số đếm phải cộng dồn cả nhánh con**, không thì nút hiện 0 mà bấm ra cả trăm dòng.
- 🔴 **desk-500 / mất CSS khung**: gốc là 11 app vá tay lệch manifest — đã trị bằng image tùy chỉnh `ntv/erpnext:v16.26.2-ntv1+`. Nếu tái diễn xem [[frontend-trang-chu-erpnext]] + [[trien-khai-vm]].
- **`-webkit-text-fill-color`** của theme ĐÈ cả `color:!important` → chữ heading đen thui; fix: set `-webkit-text-fill-color:var(--ink)!important`.
- **Custom HTML Block gắn vào Home Workspace → SẬP boot toàn desk 500**. Dùng Page trong app `ntv` thay vì nhồi custom block vào Home.
- **CẤM đổi `title` workspace chuẩn** (Users→"Người dùng" gãy route 404 — để hệ dịch nhãn lo).
- **nginx `Host $host` cắt cổng local** khi login (login xong nhảy về `localhost/desk` cổng 80, trang trắng) → sửa `Host $host`→`Host $http_host` (giữ cổng) trong `frappe.conf`, `nginx -s reload`. Chỉ lộ ở local cổng-không-chuẩn (8091), domain 443/80 vô hại.
- **Switcher ở `.sidebar-header` (nút chức năng) — KHÔNG được ẩn**, chỉ đổi màu.
- Popup onboarding "Thiết lập tồn kho" đè trang chủ → đóng X, hoặc `System Settings.enable_onboarding=0` (hỏi anh).

Liên quan: [[frontend-trang-chu-erpnext]] · [[skill-thiet-ke-giao-dien]] · [[trien-khai-vm]] · [[pr1-hung-ui-branding]]
