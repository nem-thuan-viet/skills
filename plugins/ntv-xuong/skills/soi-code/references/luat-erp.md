# Luật ERP phải theo — bảng tra cho Cổng 9 & 10

Tra file này khi diff có đụng chứng từ, sổ sách, kho, master data, hoặc code Frappe nói chung.
Mỗi luật ghi: **luật → vì sao → dấu hiệu code sai → cách đúng.**

---

# A. Luật sổ sách — cứng nhất, phá là không sửa lại được

## A1. Chứng từ đã Submit là BẤT BIẾN

**Luật:** `docstatus` có 3 trạng thái — `0` Nháp (sửa thoải mái) · `1` Đã chốt (**bất biến**) · `2` Đã hủy. Chứng từ đã chốt chỉ được **Hủy rồi lập bản sửa (Amend)**, không bao giờ sửa trực tiếp.

**Vì sao:** lúc Submit, ERP sinh ra một loạt hệ quả — bút toán sổ cái, dòng sổ kho, cập nhật công nợ, cập nhật tồn. Sửa thẳng vào bảng thì các hệ quả đó **không sinh lại** → chứng từ nói một đằng, sổ cái nói một nẻo, và không có dấu vết để lần ra.

**Dấu hiệu code sai:**
```python
frappe.db.set_value("Sales Invoice", name, "grand_total", 5_000_000)   # 🔴
frappe.db.sql("UPDATE `tabSales Invoice` SET status='Paid' WHERE ...")  # 🔴
doc.db_set("qty", 10)          # 🔴 nếu doc.docstatus == 1
```

**Cách đúng:**
```python
doc = frappe.get_doc("Sales Invoice", name)
doc.cancel()                    # docstatus 1 → 2, ERP tự đảo hết hệ quả
amended = frappe.copy_doc(doc)
amended.amended_from = doc.name
amended.grand_total = 5_000_000
amended.insert()
amended.submit()
```

**Ngoại lệ hợp lệ duy nhất:** các field được khai `allow_on_submit = 1` (thường là ghi chú, người phụ trách, trạng thái giao hàng). Sửa field khác = 🔴.

## A2. Sổ cái và sổ kho KHÔNG BAO GIỜ ghi tay

**Luật:** `GL Entry` (bút toán sổ cái) và `Stock Ledger Entry` (dòng sổ kho) là **hệ quả tự sinh**. Không ai được `insert` / `set_value` / `delete` vào hai bảng này.

**Vì sao:** chúng phải luôn cân với chứng từ gốc và với nhau. Ghi tay một dòng là sổ mất cân, mà báo cáo tài chính đọc thẳng từ đó.

**Dấu hiệu:** bất kỳ chỗ nào xuất hiện `frappe.get_doc({"doctype": "GL Entry"...})`, `tabGL Entry`, `tabStock Ledger Entry` trong câu lệnh ghi → 🔴 **CHẶN + báo anh Bình**.

**Cách đúng:** muốn sinh bút toán thì lập đúng loại chứng từ (Journal Entry, Payment Entry, Stock Entry…) rồi Submit. Đọc thì thoải mái.

## A3. Không xóa chứng từ đã chốt

`frappe.delete_doc` trên chứng từ `docstatus=1` → 🔴. Kể cả `force=True`, nhất là `force=True`.

Xóa hàng loạt bất cứ thứ gì > 1.000 bản ghi → 🔴 (đã nghẽn hệ thống 7 tiếng ngày 31/07). Phải chạy nền theo lô, có `commit` từng lô, hẹn ngoài giờ.

## A4. `frappe.db.set_value` bỏ qua toàn bộ luật

**Luật:** `db.set_value` / `db.sql` ghi thẳng xuống bảng — **không chạy** `validate`, không chạy hooks, không cập nhật `modified`, không vào version history.

**Chỉ được dùng khi:** field không ảnh hưởng sổ sách, không có validate liên quan, và cần tốc độ (vd đánh dấu `sync_status`, `last_synced_at` của bản ghi kỹ thuật).

**Không được dùng cho:** tiền · số lượng · trạng thái chứng từ · bất cứ field nào của bản ghi đã Submit.

---

# B. Luật kho & giá vốn

## B1. Tồn kho chỉ đổi qua chứng từ kho

Không `UPDATE tabBin`. Tồn là kết quả cộng dồn của sổ kho. Muốn đổi tồn → Stock Entry / Stock Reconciliation / Purchase Receipt / Delivery Note.

## B2. Ghi lùi ngày làm tính lại toàn bộ về sau

Chứng từ kho đặt `posting_date` trong quá khứ → ERP phải **tính lại giá vốn của mọi giao dịch sau đó**. Nhập lùi ngày hàng loạt = treo hệ thống + số giá vốn nhảy.

Code có sinh chứng từ kho lùi ngày → 🟡, phải ghi rõ trong báo cáo: lùi bao nhiêu ngày, bao nhiêu chứng từ, chạy lúc nào.

## B3. Giá vốn 0 là dấu hiệu hỏng

Item có `valuation_rate = 0` mà vẫn xuất kho → giá vốn hàng bán bằng 0 → lãi gộp ảo. Code nhập tồn đầu kỳ / nhập hàng phải đặt giá trị thật, hoặc chặn lại và báo, chứ không để 0 trôi qua.

---

# C. Luật ba pháp nhân

## C1. Mọi chứng từ phải đúng Company

Ba Company: **TVD · TVG · Nệm Thành Công**. Code sinh chứng từ mà lấy company mặc định (`frappe.defaults.get_user_default("Company")`) là **đang đánh bạc** — chạy dưới tài khoản khác nhau ra công ty khác nhau.

**Cách đúng:** company phải xác định rõ từ nghiệp vụ (kênh bán / đơn hàng / nhân sự), truyền tường minh, không để hệ thống đoán.

## C2. Cost center theo cây, không tạo tay

Cost center sinh từ `dim_team`. Code tự `insert` Cost Center mới → 🔴, cây lệch là báo cáo theo team sai hết.

## C3. Không trộn dữ liệu giữa công ty

Query báo cáo mà thiếu điều kiện `company` → số của ba pháp nhân cộng dồn thành một. 🟡, bắt buộc thêm bộ lọc company.

---

# D. Luật master data (danh mục dùng chung)

## D1. Danh mục chung thuộc app nền `ntv`

SKU/Item · Employee · Team · Company · Cost Center · Customer Group. App kênh **đọc qua** `ntv.api.master_data`, cấm đẻ bản riêng. Vi phạm → 🔴 (xem `docs/API-NEN-NTV.md`).

## D2. Không xóa master data đã có giao dịch

Item/Customer/Supplier đã xuất hiện trong chứng từ → xóa là gãy tham chiếu. Cần bỏ dùng thì `disabled = 1`, không xóa.

## D3. Nhập hàng loạt phải chống trùng

Import từ nguồn ngoài (MISA, sàn) phải có khóa đối chiếu — `misa_external_id` hoặc mã nguồn tương đương — và kiểm tra tồn tại trước khi tạo. Chạy lại lần hai không được đẻ bản trùng.

## D4. Naming series không đổi giữa chừng

Đổi `naming_series` của DocType đang chạy → trùng mã hoặc gãy chuỗi. Cần đổi thì phải có patch xử lý, và báo anh Bình.

---

# E. Bẫy kỹ thuật Frappe hay chết người

| Bẫy | Vì sao chết | Cách đúng |
|---|---|---|
| `ignore_permissions=True` rải khắp nơi | Thủng toàn bộ phân quyền — người không có quyền vẫn ghi được | Chỉ dùng trong job chạy nền không có người dùng; mỗi chỗ dùng phải có comment giải thích |
| Thêm Custom Field / sửa Customize Form **bằng tay trên site** | Lần deploy sau **mất sạch** — nhà mới dựng lại từ code | Khai trong `fixtures` của app rồi export, hoặc patch |
| `import` trong Server Script | Sandbox chặn hết, chạy là lỗi | Dùng hàm `frappe.*` có sẵn, hoặc viết thành hàm trong app |
| Vòng lặp `frappe.get_doc` nghìn lần | Mỗi lần là một loạt truy vấn → treo | `frappe.get_all` lấy cả lô một lần, xử lý trong bộ nhớ |
| `frappe.db.commit()` giữa request | Phá transaction — lỗi nửa chừng là dữ liệu dở dang không rollback được | Để framework tự commit; chỉ commit thủ công trong job nền chạy theo lô |
| Việc nặng đặt trong `doc_events` | Người dùng bấm Lưu phải ngồi chờ | `frappe.enqueue` đẩy sang hàng đợi |
| Patch chạy lại là hỏng | Migrate chạy nhiều lần | Patch phải **idempotent** — kiểm tra trạng thái trước khi làm |
| Hardcode `name` của bản ghi tự sinh | Máy khác có name khác | Tra theo field nghiệp vụ, không theo name |
| Fixture thiếu `__islocal` | Import câm, không báo lỗi mà cũng không vào (đã cắn vụ Google Ads) | Thêm `__islocal: 1` |
| `frappe.db.sql` nối chuỗi | SQL injection | Query builder `frappe.qb`, hoặc tham số hóa `%(x)s` |

---

# F. Luật riêng của nhà NTV

| Luật | Chi tiết |
|---|---|
| Đặt tên | Tên kỹ thuật (DocType, fieldname, biến, hàm) = **tiếng Anh**; nhãn hiển thị = **tiếng Việt có dấu** |
| Chọn được thì không gõ | Trường chọn-được phải `Link`/`Select`, gõ tay tối thiểu |
| Múi giờ | Kho Postgres chạy UTC — mọi phép cắt ngày `::date` phải `AT TIME ZONE 'Asia/Ho_Chi_Minh'` (POS từng lệch 35,3%) |
| Nguồn doanh thu | **MISA là chuẩn doanh thu.** Sổ kế toán nội bộ ERPNext là sổ nháp vận hành, **không lên báo cáo BOD** |
| Khóa & token | Chỉ lấy từ Kho Khóa Nền (DocType `Platform Credential`) hoặc biến môi trường. Không viết vào code, không commit |
| Dữ liệu nhạy cảm | Lương · tài chính · tên+hiệu suất nhân viên · số chưa P1 → **mặc định sau đăng nhập** |
| Lương & tài chính thật | **Chưa được đổ dữ liệu thật vào ERP** cho tới khi siết xong quyền + hoàn tất SSO |
| Luật số liệu | Đụng cách tính doanh thu / phân bổ team → **hỏi anh Bình**, không tự suy ra luật (`docs/HIEN-PHAP-DU-LIEU.md`) |

---

# G. Khi không chắc

Không tra được luật nào áp cho tình huống đang gặp → **cho 🟡, ghi rõ chỗ nghi**, đừng đoán 🟢.

Đụng bốn thứ này thì dù code đúng vẫn phải **báo anh Bình**: lộ khóa · app nền `ntv` · tiền thật · cách tính số liệu.
