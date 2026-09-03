# Mười cổng — cách soi từng cổng

Máy quét (`scripts/quet.sh`) chỉ in **dấu hiệu**. File này dạy cách **đọc dấu hiệu đó**: cái nào là lỗi thật, cái nào là báo nhầm, và phán mức nào.

Mỗi cổng có 4 mục: **bắt gì · báo nhầm điển hình · ví dụ SAI ↔ ĐÚNG · mức phán**.

---

## Cổng 1 — Lộ khóa, mật khẩu, token

**Bắt gì:** chuỗi bí mật viết thẳng vào code hoặc file cấu hình.

**Báo nhầm điển hình:**
- Tên biến có chữ `token` nhưng giá trị lấy từ nơi khác → không phải lỗi.
- Chuỗi mẫu `"your-api-key-here"`, `"xxx"`, `""` → không phải lỗi.
- Test dùng khóa giả rõ ràng (`"test_key_123"`) → 🟡, đổi tên cho rõ là giả.

**SAI:**
```python
API_KEY = "AIzaSyD-9tL8xK3mNpQ7rS2vW1yZ4bC6eF8gH0j"
headers = {"Authorization": "Bearer EAAG7xk2..."}
```
```bash
# .env.example
DB_PASSWORD=Th4nhC0ng@2026
```

**ĐÚNG:**
```python
API_KEY = frappe.get_doc("Platform Credential", "google-ads-dat").get_password("secret")
API_KEY = os.environ["GOOGLE_ADS_KEY"]
```
```bash
# .env.example
DB_PASSWORD=            # để rỗng, giá trị thật nằm ngoài repo
```

**Mức phán:** chuỗi thật = 🔴 **CHẶN + báo anh Bình**. Xóa khỏi code là **chưa đủ** — khóa đã vào lịch sử git thì coi như đã lộ, phải **xoay khóa mới**. Ghi rõ trong báo cáo: khóa nào, của dịch vụ nào, ai xoay.

---

## Cổng 2 — Đúng kho, đúng nhánh, không rác

**Bắt gì:** code nằm sai chỗ, hoặc file không nên có mặt trong commit.

**Ba lỗi hay gặp:**
1. **Kho ngoài org** `nem-thuan-viet` → 🔴. Code này không có đường lên nhà mới, không phải chuyện sửa vài dòng là xong.
2. **Nhầm kho `ntv-fb` (gạch ngang) với `ntv_fb` (gạch dưới)** → 🔴. Kho gạch ngang là bản cũ, không nằm trong bench nhà mới. Đẩy nhầm vào đó là code biến mất khỏi đường lên.
3. **Rác iCloud** — tên có ` 2`, ` 3` ở cuối file **hoặc giữa đường dẫn** (`doctype/item 3/item.json`). Đây là bản nhân đôi do iCloud đồng bộ, không phải code.

**Đứng ngay trên `main`** → 🔴 dừng: tạo nhánh `tên/việc`, `git branch <nhánh>` rồi `git reset` đưa main về chỗ cũ.

**Mức phán:** sai kho = 🔴 · rác = 🟡 dọn rồi soi lại.

---

## Cổng 3 — Không lấn sang app nền

**Luật:** danh mục dùng chung (Item/SKU · Employee · Team · Company · Cost Center · Customer Group) **thuộc app nền `ntv`**. App kênh đọc qua `ntv.api.master_data`.

**Báo nhầm điển hình:** app kênh **tham chiếu** tới Item bằng `Link` field → hoàn toàn đúng, không phải lấn. Chỉ khi **tự định nghĩa DocType mới** để lưu bản sao mới là lấn.

**SAI:** app `ntv_shopee` tạo DocType `Shopee Product` chứa tên, giá, tồn — thành bản SKU thứ hai, hai bên lệch nhau là hết đường đối chiếu.

**ĐÚNG:** DocType `Shopee Listing` chỉ chứa **thứ riêng của Shopee** (mã listing, trạng thái đăng bán) + một `Link` sang `Item`.

**Mức phán:** đẻ bản sao master data = 🔴 (lỗi thật, phải sửa). Người code app kênh mà **sửa file trong app `ntv`** — nếu code sạch (cổng đạt + có bằng chứng chạy được) = **🔵 đẩy lên anh Bình quyết** (app nền là của anh Bình, không phải lỗi kỹ thuật); nếu chính sửa đó lại phạm cổng khác (VD tự đẻ bản sao, ghi thẳng sổ sách) thì vẫn 🔴.

### Cổng 3b — Đọc thẳng, không đẻ bản sao nhưng vẫn bỏ qua cửa hẹp

Khác Cổng 3 (tự **tạo DocType** trùng nghĩa): đây là **đọc thẳng DocType có sẵn của ERPNext/`ntv`** bằng `frappe.get_doc`/`get_all`/`get_list`/`db.get_value`... mà không qua `ntv.api.master_data`. Không nhân đôi dữ liệu, nhưng vẫn sai vì hai lý do: (1) bỏ qua field đã được `ntv.api.master_data` lọc an toàn (VD gọi thẳng `Employee` ra cả field `salary` mà facade không bao giờ trả) (2) khi `ntv` đổi cấu trúc bảng, app kênh gọi thẳng sẽ vỡ ngay không ai báo trước, còn gọi qua facade thì chỉ app nền phải sửa 1 chỗ.

**Báo nhầm điển hình:** app đang chính là `ntv` (app nền) — nó ĐƯỢC đọc thẳng ERPNext, đây là vai của nó. Máy quét tự đọc `app_name` trong `hooks.py` để loại trường hợp này, không cần soi tay.

**SAI:**
```python
# ntv_fb/ntv_fb/api.py
def lay_nhan_su():
    return frappe.get_all("Employee", fields=["employee_name", "salary"])
```

**ĐÚNG** (mẫu MỀM #5 — tự dò trước khi nối, mất dây thì im lặng bỏ qua, không sập app):
```python
# ntv_fb/ntv_fb/integrations/ntv_bridge.py
def lay_nhan_su():
    if "ntv" not in frappe.get_installed_apps():
        return []
    try:
        return frappe.get_attr("ntv.api.master_data.get_employees")()
    except Exception:
        frappe.log_error(title="ntv_fb: mat day toi ntv", message=frappe.get_traceback())
        return []
```

**Mức phán:** 🔴 — chặn, sửa lại thành gọi qua `ntv.api.master_data.*` rồi soi lại.

---

## Cổng 4 — `pyproject.toml` khai phiên bản Frappe

Máy quét kiểm thẳng file, không cần đọc diff.

```toml
[tool.bench.frappe-dependencies]
frappe = ">=16.0.0,<17.0.0"
```

Thiếu → Frappe Cloud từ chối với thông báo *"Could not find compatible Frappe version"*, và **cả bản dựng của đội hỏng theo**, không riêng app này.

Chỉ khai `frappe`. Không khai `erpnext` trừ khi app thật sự đụng DocType của ERPNext.

**Mức phán:** 🟡 — thêm vào rồi soi lại. Nhưng nếu sắp deploy thì thành chặn, vì nó làm đứng cả đội.

---

## Cổng 5 — Quyền và dữ liệu nhạy cảm

**Bắt gì:** cửa API mở ra ngoài mà không có người gác.

Với **mỗi** `@frappe.whitelist()` mới, hỏi đủ ba câu:

1. **Có `allow_guest=True` không?** Nếu có, đây là cửa **ai cũng vào được, không cần đăng nhập**. Chỉ đúng khi cố ý làm cửa công khai (webhook, trang landing). Còn lại = 🔴.
2. **Bên trong có gác quyền không?** `frappe.has_permission(...)`, kiểm role, hoặc kiểm bản ghi có thuộc về người gọi không. Không có = 🔴 — đã cắn đúng lỗi này ở bản Google Ads.
3. **Trả về cái gì?** Lương · giá vốn · số liệu tài chính · tên kèm hiệu suất nhân viên · số chưa P1 → phải gác. Không gác = 🔴.

**SAI:**
```python
@frappe.whitelist(allow_guest=True)
def danh_sach_nhan_vien():
    return frappe.get_all("Employee", fields=["name", "ctc", "bank_ac_no"])
```

**ĐÚNG:**
```python
@frappe.whitelist()
def danh_sach_nhan_vien():
    if not frappe.has_permission("Employee", "read"):
        frappe.throw("Không có quyền xem", frappe.PermissionError)
    return frappe.get_all("Employee", fields=["name", "department"])   # không trả field lương
```

**Thêm:** trang/app hiển thị dữ liệu nội bộ → **mặc định sau đăng nhập**. Lên bản chạy thật phải là **bản build tĩnh**, không chạy dev-server (dev-server phơi cả secret lẫn ổ đĩa — đã trả giá 24/07).

---

## Cổng 6 — Việc nặng và xóa hàng loạt

**Bối cảnh:** nhà mới chạy trần **2 giờ CPU/ngày**, dùng chung cả công ty. Ngày 31/07 xóa 100k dòng làm nghẽn hàng đợi **7 tiếng**, và lúc đó chẩn nhầm là "worker chết".

**Ba câu phải trả lời được:**
- Việc này đụng **bao nhiêu bản ghi**? Không biết = 🟡, phải đếm trước.
- Chạy **đồng bộ hay chạy nền**? Trên 500 bản ghi mà chạy đồng bộ = 🔴.
- Chạy **lúc nào**? Job mới thêm phải ghi rõ giờ chạy và thời lượng ước tính.

**SAI:**
```python
for row in frappe.get_all("Kho Giao Dich"):          # 49.680 bản ghi
    frappe.delete_doc("Kho Giao Dich", row.name)
```

**ĐÚNG:**
```python
def don_theo_lo(limit=500):
    rows = frappe.get_all("Kho Giao Dich", filters={"cu": 1}, limit=limit, pluck="name")
    for name in rows:
        frappe.delete_doc("Kho Giao Dich", name)
    frappe.db.commit()
    if rows:
        frappe.enqueue(don_theo_lo, queue="long", limit=limit)   # tự gọi lô kế tiếp
```

**Mức phán:** không giới hạn + không chạy nền = 🔴 · job mới thêm = 🟡 ghi rõ lịch chạy.

---

## Cổng 7 — Đụng tiền thật

**Tính là tiền thật:** bật/tắt quảng cáo · đổi ngân sách · tạo chiến dịch · thanh toán · xuất hóa đơn · ghi sổ kế toán.

**Câu hỏi duy nhất:** code này có thể tiêu tiền **mà không có người bấm duyệt** không?

**ĐÚNG:** đi qua nấc duyệt — tạo bản **Nháp**, người có quyền duyệt mới chạy thật. Trong báo cáo phải chỉ ra **nấc duyệt nằm ở dòng nào**.

**Mức phán:** tự động tiêu tiền = 🔴 **CHẶN + báo anh Bình**, không có ngoại lệ.

---

## Cổng 8 — Số liệu chưa qua kiểm

- Màn hình/báo cáo mới hiển thị doanh thu, chi phí, hiệu suất → hỏi **số này qua P1 chưa?**
- Chưa qua → 🟡, bắt buộc dán nhãn *"số nội bộ, chưa kiểm"* **ngay trên màn hình**, không phải ghi trong tài liệu.
- **Đụng cách tính** (công thức doanh thu, phân bổ team, quy tắc gộp) — nếu code kỹ thuật đúng nhưng công thức **chưa ai chốt** → **🔵 đẩy lên anh Bình quyết** (không phải lỗi code, chỉ là luật số không tự chế trong lúc code — xem `docs/HIEN-PHAP-DU-LIEU.md`). Nếu ghi thẳng số **chưa qua P1** lên báo cáo BOD mà không dán nhãn cảnh báo → vẫn 🔴.

Nhắc lại luật nền: **MISA là chuẩn doanh thu.** Sổ kế toán nội bộ ERPNext là sổ nháp vận hành, không lên báo cáo BOD.

---

## Cổng 9 — Luật sổ sách ERP

Cổng nặng nhất. Chi tiết đầy đủ ở `luat-erp.md` mục A–D. Đây là cách đọc dấu hiệu máy quét in ra.

### C9a — `GL Entry` / `Stock Ledger Entry` / `tabBin`

**Đọc thế nào:** phân biệt **đọc** và **ghi**.

- `frappe.get_all("GL Entry", ...)` để làm báo cáo → **ĐÚNG**, đọc thoải mái.
- `frappe.get_doc({"doctype": "GL Entry"...}).insert()` · `db.set_value("GL Entry"...)` · `DELETE FROM tabGL Entry` → 🔴 **chặn cứng, báo anh Bình.**

Không có ngoại lệ. Hai sổ này là hệ quả tự sinh từ chứng từ.

### C9b — `db.set_value` / `db_set` / SQL UPDATE

**Đọc thế nào:** hỏi *bản ghi đích có `docstatus = 1` không?*

- Chứng từ đã chốt → 🔴. Đúng cách là `cancel()` → `amend`. Ngoại lệ **duy nhất**: field khai `allow_on_submit = 1`.
- Bản ghi kỹ thuật (cờ đồng bộ, `last_synced_at`, cache) → **ĐÚNG**, đây chính là chỗ nên dùng `db.set_value` cho nhanh.
- Bản ghi nháp (`docstatus = 0`) mà có validate liên quan → 🟡, nên dùng `doc.save()` để validate chạy.

### C9c — `posting_date` / `docstatus` / `naming_series`

- **Lùi ngày** chứng từ kho → 🟡 bắt buộc ghi trong báo cáo: lùi mấy ngày, bao nhiêu chứng từ, chạy lúc nào. ERP sẽ tính lại giá vốn của **mọi giao dịch sau đó**.
- **Đổi `naming_series`** của DocType đang chạy → 🔴 báo anh Bình (trùng mã hoặc gãy chuỗi).

### C9d — Company / Cost Center

- `frappe.defaults.get_user_default("Company")` khi tạo chứng từ → 🟡 đến 🔴: chạy dưới tài khoản khác nhau ra **công ty khác nhau**. Company phải suy ra từ nghiệp vụ (kênh bán, đơn hàng, nhân sự) và truyền tường minh.
- Query báo cáo **thiếu bộ lọc company** → 🟡: số ba pháp nhân cộng dồn thành một.
- `insert` Cost Center mới → 🔴: cây sinh từ `dim_team`, tạo tay là lệch cây, báo cáo theo team sai hết.

---

## Cổng 10 — Bẫy kỹ thuật Frappe

Chi tiết ở `luat-erp.md` mục E–F.

| Dấu hiệu | Khi nào là lỗi thật | Mức |
|---|---|---|
| `ignore_permissions=True` | Không có comment giải thích ngay cạnh, hoặc nằm trong đường có người dùng gọi | 🟡 (🔴 nếu ở hàm whitelist) |
| `frappe.db.commit()` | Nằm giữa một request — phá transaction, lỗi nửa chừng không rollback được | 🟡 |
| `for ... frappe.get_doc(...)` | Số vòng lặp không chặn trên, hoặc lấy từ bảng lớn | 🟡 — đổi sang `get_all` lấy cả lô |
| `frappe.db.sql(f"...")` | Có nội suy biến vào chuỗi SQL | 🔴 SQL injection |
| `import` trong Server Script | Luôn luôn — sandbox chặn hết | 🔴 |
| `custom_field` / `property_setter` | Sửa tay trên site thay vì khai `fixtures` | 🔴 — deploy sau mất sạch |
| Fixture thiếu `__islocal` | Import chạy câm, không vào mà cũng không báo lỗi | 🟡 |
| `::date` trên kho Postgres | Thiếu `AT TIME ZONE 'Asia/Ho_Chi_Minh'` — DB chạy UTC | 🟡 (POS từng lệch 35,3%) |
| Việc nặng trong `doc_events` | Người dùng bấm Lưu phải ngồi chờ | 🟡 — đẩy `frappe.enqueue` |
| Patch không idempotent | Chạy lần hai là hỏng dữ liệu | 🟡 |

**Quy ước NTV, kiểm bằng mắt:**
- Tên kỹ thuật (DocType, fieldname, biến, hàm) = **tiếng Anh**; nhãn hiển thị = **tiếng Việt có dấu**.
- Trường chọn-được phải `Link`/`Select`, không để `Data` gõ tay.
- Commit message tiếng Việt có dấu, mô tả việc thật.
