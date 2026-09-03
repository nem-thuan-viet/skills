# Chạy thử thật — cách lấy bằng chứng

**Luật cứng: không có bằng chứng chạy được thì không cho 🟢.**

Đọc code thấy đúng ≠ chạy đúng. Phần lớn lỗi lọt lên bản chạy thật là lỗi *"nhìn thì hợp lý"*. Cổng soi tồn tại để chặn đúng loại đó.

**Bằng chứng hợp lệ = thứ dán được vào Pull Request:** kết quả lệnh, số đếm thật, ảnh màn hình, số dòng test pass. Câu *"em đã kiểm rồi"* không phải bằng chứng.

---

## Chọn cách thử theo loại việc

| Loại việc vừa làm | Bằng chứng tối thiểu |
|---|---|
| Hàm Python trong app | Gọi thẳng hàm qua bench console, dán kết quả trả về |
| DocType mới / sửa field | Tạo thử 1 bản ghi, dán `name` sinh ra + ảnh màn hình form |
| Server Script / hook | Kích hoạt đúng sự kiện, dán bản ghi trước ↔ sau |
| Báo cáo, con số | Dán con số thật + cách đối chiếu với nguồn |
| Giao diện | Ảnh màn hình, có cả trạng thái rỗng và trạng thái có dữ liệu |
| Sửa lỗi | Tái hiện lỗi cũ **trước**, rồi cho thấy nó hết |
| Job chạy nền | Chạy tay một lần, dán log + thời gian chạy |
| Migration / patch | Chạy **hai lần liên tiếp**, lần hai không được hỏng |
| Đụng chứng từ | Xem `docstatus` trước/sau + kiểm sổ cái cân |

---

## Lệnh hay dùng

Không có bench cài thẳng máy — mọi lệnh qua docker.

**Console để gọi hàm và xem kết quả thật:**
```bash
docker exec -i ntv-thu-backend-1 bench --site ntv.local console
```

**Chạy một đoạn kiểm nhanh không cần vào console:**
```bash
docker exec ntv-thu-backend-1 bench --site ntv.local execute ntv.api.master_data.get_items --kwargs "{'filters':'[[\"disabled\",\"=\",0]]','limit_page_length':5}"
```

**Xem lỗi khi có traceback:**
```bash
docker exec ntv-thu-backend-1 bench --site ntv.local console
# >>> frappe.get_all("Error Log", fields=["method","creation"], order_by="creation desc", limit=5)
```

**Mở desk xem bằng mắt (URL kèm sid, mở thẳng được):**
```bash
docker exec ntv-thu-backend-1 bench --site ntv.local browse --user Administrator
```

**Sau khi sửa DocType / fixtures thì phải migrate rồi mới thử:**
```bash
docker exec ntv-thu-backend-1 bench --site ntv.local migrate
```

---

## Ba phép thử bắt buộc theo cổng

Nếu diff chạm vào các vùng dưới đây, **thử thêm** đúng phép tương ứng — đây là chỗ đã cắn thật.

### Chạm chứng từ hoặc sổ sách (Cổng 9)

Kiểm sổ còn cân sau khi code chạy:
```python
# trong bench console — thay SI-xxxxx bằng chứng từ vừa đụng
doc = frappe.get_doc("Sales Invoice", "SI-xxxxx")
print("docstatus:", doc.docstatus)

gl = frappe.get_all("GL Entry",
        filters={"voucher_no": doc.name, "is_cancelled": 0},
        fields=["account", "debit", "credit"])
print("tổng nợ :", sum(r.debit for r in gl))
print("tổng có :", sum(r.credit for r in gl))     # hai số này PHẢI bằng nhau
```
Lệch một đồng cũng là 🔴.

### Chạm quyền hoặc API (Cổng 5)

Thử bằng **tài khoản thường**, không phải Administrator — Administrator qua được mọi cửa nên thử bằng nó là thử giả:
```python
frappe.set_user("nhan.vien@example.com")
try:
    ket_qua = ten_ham_vua_viet()
    print("GỌI ĐƯỢC — kiểm xem có nên gọi được không:", ket_qua)
except frappe.PermissionError:
    print("bị chặn đúng ✓")
finally:
    frappe.set_user("Administrator")
```
Cửa `allow_guest` thì thử bằng `curl` không kèm cookie đăng nhập.

### Chạm việc nặng (Cổng 6)

Đếm trước, đo sau:
```python
print("số bản ghi sẽ đụng:", frappe.db.count("Kho Giao Dich", {"cu": 1}))
```
Trên 500 thì phải chạy nền theo lô. Chạy thử một lô rồi dán thời gian thật.

---

## Khi không thử được

Thiếu khóa, thiếu dữ liệu, thiếu môi trường — chuyện thường. **Không được nói dối là đã thử.**

Ghi 🟡 kèm ba dòng:
1. Đã thử tới đâu.
2. Vướng chỗ nào.
3. Cần gì để thử được (khóa nào, dữ liệu nào, ai cấp).

Việc chưa thử được **không tự lên 🟢**. Nó nằm chờ, hoặc anh Bình quyết cho qua với điều kiện rõ ràng.

---

## Không được làm khi thử

- ❌ Thử trên **bản chạy thật** `platform.nguoithuanviet.com`. Thử ở máy mình hoặc Khu Lab.
- ❌ Dùng **dữ liệu thật của khách hàng hay nhân viên** làm dữ liệu thử.
- ❌ Tạo chứng từ thử rồi bỏ đó — dọn sạch, hoặc đánh dấu rõ là bản thử.
- ❌ Thử bằng tài khoản Administrator rồi kết luận "quyền chạy đúng".
