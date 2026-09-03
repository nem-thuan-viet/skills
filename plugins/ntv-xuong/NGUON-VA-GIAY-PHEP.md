# Nguồn & giấy phép — gói `ntv-xuong`

**Đây là gói ĐỒ NHÀ.** Trừ một ngoại lệ, toàn bộ nội dung do đội Thuần Việt tự viết, tự do dùng và sửa trong nội bộ:

| Món | Nguồn |
|---|---|
| `skills/soi-code` | đồ nhà — cổng soi 34 mục trước khi gộp `main` |
| `skills/memory-edit` | đồ nhà — chuẩn ghi/sửa memory |
| `skills/desk-giao-dien-frappe` | đồ nhà — giao diện desk NTV, màu hồng thương hiệu |
| `commands/*`, `agents/kts.md`, `hooks-handlers/skill_router.py` | đồ nhà |
| `skills/karpathy-guidelines` | ⚠️ **đồ kéo về**, frontmatter khai `license: MIT` — chép nguyên văn LICENSE của kho gốc vào đây trước khi mở chợ công khai |

## Hook đi kèm

`hooks/hooks.json` gắn vào sự kiện `UserPromptSubmit`: chạy `skill_router.py` (định tuyến skill) + nhắc luật khai skill.
**Cài gói này rồi thì phải gỡ khối `hooks` trùng trong `.claude/settings.local.json` của repo**, không thì chạy 2 lần.

## Đã gỡ khỏi bản công khai (03/09/2026)

- **`skills/van-hanh-cong-mcp/`** — sổ tay vận hành cổng MCP: nêu tên tài khoản AI, endpoint thật
  và đường dẫn file khóa. Giữ trong kho kín của đội.
- **`skills/soi-code/NHAT-KY-SOI.md`** — nhật ký ghi lỗ hổng thật chưa vá. File trong kho này chỉ là
  **mẫu trống**.
