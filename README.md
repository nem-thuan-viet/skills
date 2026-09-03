# Bộ đồ nghề Claude Code — Nệm Thuần Việt

Chợ plugin (marketplace) cho Claude Code: **4 gói · 30 skill · 5 lệnh gạch chéo**.
Cài một lần, dùng được ở **mọi thư mục** trên máy.

> Kho này **công khai** — tải được mà **không cần tài khoản GitHub**.

---

## Cách lấy về

### Cách 1 — Cài thẳng vào Claude Code (nên dùng)

Mở Claude Code, gõ 2 dòng:

```
/plugin marketplace add nem-thuan-viet/skills
/plugin install ntv-frappe@nem-thuan-viet
```

Đổi `ntv-frappe` thành tên gói khác nếu muốn cài thêm. Xem gói đã cài: `/plugin`.

⚠️ **Plugin KHÔNG tự cập nhật.** Khi có bản mới phải chạy lại:

```
/plugin marketplace update nem-thuan-viet
```

### Cách 2 — Tải file ZIP (không cần cài gì)

Bấm nút **Code** màu xanh ở đầu trang → **Download ZIP**. Giải nén, rồi chép thư mục
skill muốn dùng vào `.claude/skills/` trong dự án của mình.

---

## 4 gói có gì

| Gói | Dùng khi nào | Bên trong |
|---|---|---|
| **`ntv-frappe`** | Viết code Frappe/ERPNext (v14–v16) | 21 skill: **sổ tay ERPNext thực chiến** · cú pháp DocType · hooks · report · quyền · API · sao lưu · gỡ lỗi |
| **`ntv-du-lieu`** | Đụng tới dữ liệu | Viết & tối ưu SQL · vẽ ERD · luật PostgreSQL · dựng server MCP từ OpenAPI |
| **`ntv-giao-dien`** | Thiết kế giao diện | Kho tra: 161 bảng màu · 57 cặp font · 99 luật UX · 25 loại biểu đồ (tra bằng script Python chạy tại chỗ) |
| **`ntv-xuong`** | Nhịp làm việc chung | Cổng `/soi-code` soi code trước khi gộp · `/phien-dev` · `/thuc-thi` · `/kts` · `/nghiem-thu` · `/giam-sat` · chuẩn ghi memory · kỷ luật code Karpathy |

**Chưa biết cài gì thì cài `ntv-xuong`** — nó là nội quy và nhịp làm việc, ai cũng dùng được.
Ai code Frappe thì cài thêm `ntv-frappe`.

---

## Lưu ý

- Nội dung viết cho **bối cảnh Nệm Thuần Việt** (ERPNext trên Frappe Cloud, tiếng Việt).
  Người ngoài dùng được, nhưng vài ví dụ sẽ nhắc tên hệ thống nội bộ.
- Cần **Claude Code** bản có hỗ trợ plugin.
- Giấy phép từng gói: xem [GIAY-PHEP.md](GIAY-PHEP.md).
