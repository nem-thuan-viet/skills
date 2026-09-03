# Nguồn & giấy phép — gói `ntv-frappe`

**Không phải đồ nhà.** 20 skill trong gói này lọc từ kho cộng đồng, cài 12/07/2026.

- Nguồn: https://github.com/Impertio-Studio/Frappe_Claude_Skill_Package (tên cũ: OpenAEC-Foundation)
- Bản gốc: push 08/07/2026, phủ Frappe v14–v16
- ⚠️ **Giấy phép còn vênh**: frontmatter mỗi SKILL.md ghi `license: MIT`, nhưng `LICENSE.md` của kho gốc là **LGPL-3.0** (README kho gốc lại ghi MIT). Đã ghi nhận 12/07/2026, **chưa gỡ**.

## Trước khi mở chợ ra công khai — phải làm 2 việc

1. Hỏi lại kho gốc / đọc kỹ `LICENSE.md` để chốt giấy phép thật.
2. Chép nguyên văn file LICENSE của kho gốc vào thư mục này.

Cả MIT lẫn LGPL-3.0 **đều cho phép phát lại**, miễn kèm nguyên văn giấy phép + ghi công.
Chừng nào chưa làm 2 việc trên: **giữ kho chợ ở chế độ private**, chỉ phát trong org `nem-thuan-viet`.

## Cập nhật bản mới

```bash
git clone --depth 1 https://github.com/Impertio-Studio/Frappe_Claude_Skill_Package.git /tmp/fcsp
# copy đè các thư mục cùng tên từ /tmp/fcsp/skills/source/{syntax,core,ops,agents}/
```

## Tiêu chí chọn 20/61

Phục vụ kế hoạch "4 chặng về một nền" (`docs/KE-HOACH-TONG-THE.md`): syntax (10) · core (5) · ops (3) · agents (2).
Nhóm 🟡 để dành, cài khi đụng việc: `frappe-impl-integrations` (Data Import — chặng 2), `frappe-impl-scheduler`, nhóm `errors/*`, `testing/*`.
