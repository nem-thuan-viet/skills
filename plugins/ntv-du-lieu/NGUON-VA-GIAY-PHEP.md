# Nguồn & giấy phép — gói `ntv-du-lieu`

3 skill kéo từ https://github.com/alirezarezvani/claude-skills (thư mục `engineering/skills/`), **giấy phép MIT**, anh Bình duyệt đích danh 15/07/2026:

- `sql-database-assistant/` — viết/tối ưu SQL, sinh migration, dò lược đồ
- `database-schema-designer/` — vẽ ERD, chuẩn hóa bảng
- `mcp-server-builder/` — sinh MCP server từ OpenAPI (Python/TS)

Skill `postgres/` khai `license: MIT` trong frontmatter.

Cả 3 skill trên đã **địa phương hóa**: chèn khối "🏭 Bối cảnh NTV" ở đầu mỗi `SKILL.md` (bẫy múi giờ · luật tên · cấm token), ruột gốc giữ nguyên để còn nâng cấp — nâng cấp xong nhớ **chèn lại khối Bối cảnh NTV**.

## An toàn script

5 script `.py` đã soi 15/07/2026: chỉ dùng stdlib, không gọi mạng, không đọc secret, không lệnh phá (`os` duy nhất là `os.path.isfile`).

## Trước khi mở chợ công khai

MIT cho phép phát lại, **miễn kèm nguyên văn giấy phép + ghi công**. Chép file `LICENSE` của kho gốc vào đây trước khi mở public.
