---
description: Skill GIÁM SÁT vận hành Thuần Việt Platform — canh NGUỒN + kho lưu lúc CHẠY trên 3 trục: TƯƠI (nguồn còn cập nhật?) · KHỚP (số từng khớp có lệch lại?) · BOM HẸN GIỜ (token/API sắp chết?). Phát hiện → đẩy về /phien-dev thành việc. KHÔNG tự sửa, KHÔNG ghi state. Dùng khi anh Bình nói "hệ thống có ổn không", "giám sát", "có gì đứt/lệch không", "token còn sống không", hoặc chạy định kỳ.
---

# /giam-sat — Mắt vận hành Thuần Việt Platform

**Phân vai rõ:** `/nghiem-thu` gác cổng *lúc xây một việc*. `/giam-sat` gác *lúc CHẠY, theo thời gian*. Nguồn không phải "đấu xong là xong" — token chết, API đổi schema, sync chết CÂM, số từng khớp âm thầm lệch lại. Skill này là cái mắt phát hiện sớm, **trước khi lộ ra qua số sai trên báo cáo**.

Neo đích chung: **giữ nguồn dữ liệu SỐNG** để chặng 3 (nối MISA/POS/Ads về ERPNext/Insights) không ăn dữ liệu rác — [[dich-2-giai-doan]], `docs/KE-HOACH-TONG-THE.md`.

> **Luật giám sát:** chỉ **PHÁT HIỆN + BÁO**, tuyệt đối không tự sửa, không tự ghi state. Thấy đứt/lệch → đóng gói thành việc, đẩy về `/phien-dev`. Không chắc → báo VÀNG (nghi ngờ), không im lặng cho qua.

> **🔗 Neo luật chung (1 nhà — đừng chép lại):** luật số & thang tin → §0 `docs/HIEN-PHAP-DU-LIEU.md` · cổng P1 (khớp gốc 7 ngày) → `docs/KE-HOACH-TONG-THE.md` · bẫy múi giờ → [[time-systems-warehouse]]. Skill chỉ TRỎ, không diễn giải lại.

---

## BƯỚC 0 — Chạm kho lưu
⚠️ **11/08/2026: skill `kho-cockpit-sql` đã bỏ** (đồ cũ, không còn dùng) — bước này hiện KHÔNG còn cách tự động kết nối kho Postgres. Cần canh kho lưu thì hỏi anh Bình cách kết nối trước, đừng tự khởi động cockpit hay gõ query tay.

## BƯỚC 1 — Trục TƯƠI (freshness): nguồn còn cập nhật không?
- Đọc `core.health_check` + `max(thời gian)` từng bảng raw → mỗi nguồn cập nhật **lần cuối khi nào**, có **đứt nhịp** so với tần suất kỳ vọng không (sổ cái cột "Nhịp").
- Cờ: nguồn nào trễ hơn 1 chu kỳ = 🟡; im hẳn nhiều chu kỳ = 🔴.
- Bẫy múi giờ khi so ngày: `AT TIME ZONE 'Asia/Ho_Chi_Minh'` ([[time-systems-warehouse]]).

## BƯỚC 2 — Trục KHỚP (drift): số từng khớp có lệch lại không?
- **Chỉ nguồn đã qua cổng P1** (đã từng khớp gốc) mới kiểm trục này — nguồn chưa khớp là việc của build-time, không phải drift.
- Lấy **mẫu vài ngày gần nhất**, đối chiếu lại chỉ số gốc (dashboard nền tảng / MISA) trên metric LÕI (doanh thu, đơn chốt, chi ads). Raw là vua, engine trọng tài ([[working-style-binh]], [[doanh-thu-nguon-misa]]).
- Lệch dưới ngưỡng = 🟢; vượt ngưỡng không giải thích được = 🔴 (có thể API gốc đổi schema, edge-case mới).
- Token-aware: lấy MẪU, không quét lại toàn bộ lịch sử mỗi lần.

## BƯỚC 3 — Trục BOM HẸN GIỜ (expiry): cái gì sắp chết?
Soi hạn sống của nguồn — cảnh báo **trước khi đứt**, không phải sau:

| Bom | Hạn | Memory |
|---|---|---|
| Pancake JWT | hết hạn ~**18/07** | [[pos-dashboard-datbot]] |
| MShopKeeper OpenAPI | tắt **30/06/2026** | [[mshopkeeper-datbot]] |
| Google Ads 19 account | đang **403**, chờ cấp quyền | [[gads-datbot]] |
| Token Base/khác | rà hạn gia hạn | [[base-finance-api]], [[base-goal-api]] |

Còn < ~14 ngày tới hạn / đang đứt = 🔴. Mới phát sinh nguồn có hạn → ghi thêm vào bảng này.

## BƯỚC 4 — Tổng hợp bảng tình trạng

| Nguồn/Bảng | Tươi | Khớp | Bom | Cờ | Ghi chú |
|---|:---:|:---:|:---:|:---:|---|
| ví dụ: raw.pancake_orders | 🟢 | 🟢 | 🔴 18/07 | 🔴 | JWT sắp hết hạn |

Cờ tổng = đỏ nhất trong 3 trục. Xếp việc theo độ đau: 🔴 chặn đích / chặn báo cáo BOD trước.

## BƯỚC 5 — Đẩy về /phien-dev (không tự sửa)
Mỗi cờ 🔴/🟡 → đóng gói thành **việc gợi ý** (nguồn nào · trục nào · hệ quả nếu để lâu) trả về `/phien-dev`. `/phien-dev` chọn & giao `/thuc-thi` sửa, `/nghiem-thu` gác lại. `/giam-sat` **không** đụng tay.

---

## Ghi nhớ (ranh giới cứng)
- `/giam-sat` = **PHÁT HIỆN + BÁO**. KHÔNG build, KHÔNG sửa, KHÔNG ghi sổ cái/memory, KHÔNG chọn việc.
- 3 trục: **Tươi · Khớp · Bom hẹn giờ**. Không chắc = báo VÀNG, không im.
- Khác `/nghiem-thu`: nghiệm thu gác MỘT việc lúc xây; giám sát canh TOÀN hệ lúc chạy theo thời gian.
- **Phạm vi hiện tại = NGUỒN + kho lưu** (thứ đang chạy thật). Khi ERPNext vận hành thật (≥ chặng 2) → bổ sung trục canh site `ntv` (job/sync/lỗi). CHƯA làm bây giờ — chưa có gì để thối.
- Token-aware: lấy mẫu, dựa `core.health_check`; chạy định kỳ hoặc khi anh hỏi, không quét sâu mỗi phiên.
