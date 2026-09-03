# Giấy phép

Kho này gom skill từ nhiều nguồn. **Mỗi gói có giấy phép riêng** — đọc đúng gói đang dùng.

| Gói | Giấy phép | Nguồn gốc |
|---|---|---|
| `ntv-frappe` | **LGPL-3.0** — nguyên văn ở [`plugins/ntv-frappe/LICENSE`](plugins/ntv-frappe/LICENSE) | [Impertio-Studio/Frappe_Claude_Skill_Package](https://github.com/Impertio-Studio/Frappe_Claude_Skill_Package) |
| `ntv-du-lieu` | **MIT** — [`plugins/ntv-du-lieu/LICENSE`](plugins/ntv-du-lieu/LICENSE) | [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) |
| `ntv-giao-dien` | **MIT** — [`plugins/ntv-giao-dien/LICENSE`](plugins/ntv-giao-dien/LICENSE) | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) v2.11.0 |
| `ntv-xuong` | Đồ nhà Nệm Thuần Việt, trừ `karpathy-guidelines` khai **MIT** trong frontmatter của chính nó | tự viết |

## Đã sửa so với bản nội bộ

- **`ntv-frappe`**: frontmatter các `SKILL.md` ghi `license: MIT` là **SAI**. File `LICENSE.md` của kho gốc là
  **LGPL-3.0** (đã đối chiếu 03/09/2026) — lấy LGPL-3.0 làm chuẩn.
- **`ntv-giao-dien`**: skill `frontend-design` (chép từ kho `anthropics/claude-code`) **đã gỡ khỏi bản công khai**.
  Kho đó ghi *"© Anthropic PBC. All rights reserved"* — không cho phát lại.
  Ai cần thì lấy thẳng từ plugin chính chủ của Anthropic.

Sửa/đóng góp: mở Issue hoặc Pull Request ngay trên kho này.
