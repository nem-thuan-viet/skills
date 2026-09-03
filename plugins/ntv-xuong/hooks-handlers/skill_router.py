#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Hook "người chỉ đường skill" cho Thuần Việt Platform.

Chạy ở UserPromptSubmit: đọc chữ anh Bình gõ, khớp với BẢNG TỪ KHÓA bên dưới,
rồi BƠM THẲNG tên skill ứng viên vào đầu Claude — biến việc "Claude tự đoán
skill nào" (dè dặt ở quy mô ~50 skill) thành "được chỉ đúng chỗ".

- Khớp KHÔNG DẤU + thường hóa → bắt cả khi gõ thiếu dấu / sai chính tả
  ("đẩy lên vm", "day len vm", "dep len vm" đều trúng).
- Gợi ý MẠNH, không ép cứng: Claude vẫn được bỏ qua nếu có lý do rõ
  (ép sai skill còn tệ hơn không gợi ý).
- Không khớp gì → IM (thoát lặng), nên prompt vu vơ không bị nhiễu.

Sửa bảng ở KEYWORD_MAP: mỗi dòng = (skill, [từ khóa]). Ưu tiên cao hơn
(số lớn hơn ở PRIORITY) thắng khi nhiều skill cùng khớp bằng điểm.
"""
import sys
import json
import unicodedata


def bo_dau(s: str) -> str:
    """Thường hóa + bỏ dấu tiếng Việt để khớp bền với gõ thiếu dấu."""
    s = s.lower().replace("đ", "d")
    s = unicodedata.normalize("NFD", s)
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


# (skill, [từ khóa đã ở dạng thường, có dấu cũng được — sẽ tự bỏ dấu khi so])
KEYWORD_MAP = [
    ("desk-giao-dien-frappe", ["giao diện desk", "trang chủ", "sidebar", "launcher",
                               "landing", "desk 500", "desk lỗi", "màu desk",
                               "navbar", "sơn màu desk", "trang chào"]),
    ("mcp-server-builder", ["dựng cổng mcp", "tạo mcp server", "biến api thành tool",
                            "làm cổng cho ai"]),
    ("database-schema-designer", ["erd", "sơ đồ quan hệ", "thiết kế bảng",
                                  "thiết kế database", "chuẩn hóa", "quan hệ giữa các bảng",
                                  "migrate schema"]),
    ("ui-ux-pro-max", ["chọn màu", "bảng màu", "font chữ", "chọn font", "dashboard",
                       "biểu đồ", "accessibility", "giao diện web", "giao diện mobile",
                       "thiết kế component", "phối màu"]),
    ("frontend-design", ["làm giao diện", "thiết kế trang", "cho đẹp hơn", "bớt rối",
                         "sửa layout", "sửa bố cục"]),
    ("frappe-syntax-serverscripts", ["server script"]),
    ("frappe-syntax-clientscripts", ["client script"]),
    ("frappe-syntax-doctypes", ["doctype", "fieldtype", "child table", "child doctype"]),
    ("frappe-core-workflow", ["workflow", "trạng thái duyệt", "transition", "phê duyệt"]),
    ("frappe-core-permissions", ["phân quyền", "permission", "quyền truy cập",
                                 "role frappe", "siết quyền"]),
    ("frappe-core-api", ["api integration", "webhook", "rest api", "@frappe.whitelist"]),
    ("frappe-core-database", ["frappe.db", "frappe.get_doc", "frappe.get_list"]),
    ("frappe-agent-debugger", ["bench console", "traceback", "error log", "lỗi frappe",
                               "debug frappe"]),
    ("frappe-ops-backup", ["backup", "restore", "sao lưu", "khôi phục site"]),
    ("frappe-ops-deployment", ["nginx", "supervisor", "letsencrypt", "ssl frappe"]),
    ("sql-database-assistant", ["tối ưu query", "query chậm", "migration", "prisma",
                                "drizzle", "orm"]),
]

# NTV-riêng thắng skill chung khi hòa điểm (số lớn = ưu tiên cao)
PRIORITY = {
    "desk-giao-dien-frappe": 9,
}


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    prompt = (data.get("prompt") or "").strip()
    if not prompt:
        return 0

    norm = bo_dau(prompt)
    hits = []  # (skill, so_luot_trung, tu_khoa_dau_tien_trung)
    for skill, kws in KEYWORD_MAP:
        matched = [kw for kw in kws if bo_dau(kw) in norm]
        if matched:
            hits.append((skill, len(matched), matched[0]))

    if not hits:
        return 0  # không khớp → im, khỏi nhiễu

    # điểm cao trước; hòa thì ưu tiên NTV-riêng; hòa nữa thì tên a→z
    hits.sort(key=lambda h: (h[1], PRIORITY.get(h[0], 0), h[0]), reverse=True)

    top = hits[0]
    msg = (f"[Chỉ đường skill] Prompt khớp skill \"{top[0]}\" "
           f"(bắt từ: \"{top[2]}\"). HÃY gọi Skill này trước khi làm, "
           f"trừ khi có lý do rõ để không.")
    if len(hits) > 1:
        alts = ", ".join(f"\"{h[0]}\"" for h in hits[1:3])
        msg += f" Ứng viên khác nếu lệch: {alts}."
    print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
