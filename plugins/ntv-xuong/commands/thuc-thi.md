---
description: Skill THỰC THI Thuần Việt Platform — nhận MỘT việc rõ (từ /phien-dev hoặc anh Bình) rồi làm tới XONG + verify có bằng chứng, theo đúng quy ước repo. KHÔNG tự ôm chuyên môn: bật đúng SKILL MIỀN chuyên (frappe-*, desk-giao-dien-frappe…) để làm phần "how". Phân vai: /phien-dev lên kế hoạch & giao việc; /thuc-thi là quản đốc thực thi. Dùng khi anh Bình nói "làm việc này", "code cái này", "thực thi", "làm luôn đi", hoặc khi /phien-dev giao 1 đầu việc.
---

# /thuc-thi — Quản đốc thực thi Thuần Việt Platform

**Phân vai:** `/phien-dev` = QUẢN LÝ (chọn việc → giao). `/thuc-thi` = QUẢN ĐỐC THỢ (nhận 1 việc → **bật đúng thợ chuyên** → ép kỷ luật verify + báo cáo → bàn giao). Skill này KHÔNG tự chọn việc, và **KHÔNG tự ôm quy ước từng miền** — chuyên môn nằm ở các skill miền; việc của `/thuc-thi` là **điều đúng thợ + không cho ai nói "xong" khi chưa có bằng chứng**.

Neo đích: mọi việc phục vụ **một nền chung** + làm kiểu **agent-ready** (data sạch, có nguồn chân lý, ghi lại đủ) — [[dich-2-giai-doan]].

> **🔗 Neo luật chung (1 nhà — đừng chép lại):** luật số & thang tin → §0 `docs/HIEN-PHAP-DU-LIEU.md` · cổng P1 → `docs/KE-HOACH-TONG-THE.md` · quy ước nền (tên Anh/nhãn Việt, Link/Select, data-khóa-thuộc-nền) → `CLAUDE.md`. Skill chỉ TRỎ, không diễn giải lại.

---

## BƯỚC 1 — Nhận & chốt lệnh
Cần đủ 3 thứ trước khi động tay: **(a) việc gì · (b) tiêu chí XONG · (c) ràng buộc**. Thiếu → hỏi lại /phien-dev hoặc anh đúng 1 câu, **đừng đoán**.

## BƯỚC 2 — Bật ĐÚNG thợ chuyên (tim của skill này)
`/thuc-thi` không tự biết mọi nghề — nó **gọi skill miền** làm phần chuyên môn. Nhận diện việc thuộc miền nào rồi bật skill tương ứng (bảng đầy đủ ở `/phien-dev` Bước 1):

| Việc thuộc | Bật skill |
|---|---|
| DocType · hooks · client/server script · workflow · report · query builder · permission · API · backup · bench | **frappe-** (syntax-\* / core-\* / ops-\*) |
| Lỗi Frappe / traceback / bench console | **frappe-agent-debugger** · rà code trước deploy → **frappe-agent-validator** |
| Giao diện desk · trang chủ · landing · CSS · màu · sidebar | **desk-giao-dien-frappe** |
| Web chung · phối màu · font · component · dashboard · biểu đồ | **frontend-design** · **ui-ux-pro-max** |
| ERD · thiết kế bảng · SQL/ORM chung | **database-schema-designer** · **sql-database-assistant** |
| Dựng MCP server MỚI từ API | **mcp-server-builder** |

Không skill nào khớp → làm tay, **nêu "làm tay vì …"**; mảng lặp lại đáng kể → đề xuất đẻ skill mới (`skill-creator`).

## BƯỚC 3 — Kiểm QUYỀN trước khi làm (3 câu — 1 "không" là dừng)
1. **Đảo ngược được không?** (ghi DB hàng loạt · sửa Drive · gửi ra ngoài · deploy = thường KHÔNG).
2. **Có phải quyết định của Claude không?** Kỹ thuật/số = làm; kinh doanh/nhân sự/luật số = anh quyết.
3. **Đủ dữ kiện làm ĐÚNG không?** Thiếu (vd ai-thuộc-team-nào) = cần người cấp.

→ ⛔ **Nhà mới `platform.nguoithuanviet.com` & thao tác tiền thật: KHÔNG tự đụng** — soạn sẵn để anh Bình tự làm. Phải dừng thì **chuẩn bị sẵn** (text/SQL/lệnh nháp) rồi kêu đúng người, không làm liều.

## BƯỚC 4 — Làm theo QUY ƯỚC
Theo quy ước của **skill miền** đã bật (ở đó có chi tiết "how") + quy ước nền ở `CLAUDE.md` (tên kỹ thuật tiếng Anh / nhãn tiếng Việt · trường chọn-được phải Link/Select · master data đọc qua API nền, app kênh không đẻ bản riêng). Đọc token-aware: chỉ file/bảng LIÊN QUAN việc, không đọc cả repo.

## BƯỚC 5 — VERIFY (BẮT BUỘC — cổng P1)
Không tự verify được thì việc **chưa xong**. Cách kiểm tùy miền:
- **🖥️ Giao diện người dùng (BẮT BUỘC nếu có người dùng cuối — lỗi hay quên nhất):** một tính năng/app **CHƯA xong** khi mới có API/backend chạy mà **người dùng chưa có màn để thao tác**. Phải: (1) mở đúng màn người dùng sẽ bấm, làm trọn 1 việc từ đầu tới cuối; (2) nếu có ô/card ở launcher — **lật "Sắp có" → vào dùng được**, đừng để card treo. Xây API/luật mới mà chưa nối UI → ghi rõ "còn nợ UI" và **chưa được coi là xong**.
- **ERPNext**: chạy thử trên bản local qua `docker exec ntv-thu-backend-1 bench --site ntv.local ...` / mở desk xem / gọi endpoint thật; đổi giao diện → xem bằng trình duyệt (http://localhost:8091).
- **Số/nguồn**: đối chiếu khớp gốc. **Nguồn mới phải khớp gốc 7 ngày liên tiếp TRƯỚC khi xây tầng trên** — chưa khớp thì DỪNG.
- **Kho lưu Postgres (nếu còn đụng)**: nhớ **bẫy múi giờ** — DB lưu UTC, cắt ngày `::date` phải kèm `AT TIME ZONE 'Asia/Ho_Chi_Minh'`.
- Luôn đưa **BẰNG CHỨNG** (số đo · ảnh · log · kết quả gọi). Tuyệt đối không nói "chắc xong".

## BƯỚC 6 — Báo cáo + định tuyến (qua gác cổng nếu GẮT)
`/thuc-thi` TỰ viết báo cáo việc mình làm. Cập nhật trạng thái bền (kế hoạch · memory) để **`/phien-dev`** lo.
- Việc **GẮT** (vượt P1 · số lên báo cáo BOD · đụng luật số/tài chính/lương) → **KHÔNG** trả thẳng; chuyển báo cáo + bằng chứng sang **`/nghiem-thu`** kiểm độc lập (người làm ≠ người gác cổng).
- Việc **nhẹ** (đảo ngược được · UI · doc) → trả thẳng `/phien-dev`.

Báo cáo gồm: **✅ đã làm/đổi gì** (file · DocType · site cụ thể) · **🔎 bằng chứng verify** (bắt buộc) · **⏳ còn vướng/chờ ai** + đề mục cần /phien-dev ghi trạng thái. Việc đáng kể → thêm `docs/reports/<YYYY-MM-DD>-bao-cao-cong-viec.md`.

Giữa chừng gặp việc cần quyết định hoặc ngoài phạm vi → **dừng, trả về /phien-dev hoặc anh**, không đào hang bỏ dở việc chính.

---
## Ghi nhớ
- `/thuc-thi` = **điều đúng thợ chuyên** + LÀM + VERIFY + viết báo cáo; **KHÔNG** tự ôm quy ước miền, **KHÔNG** cập nhật sổ/memory (để /phien-dev).
- Làm 1 việc; muốn chuỗi việc → để `/phien-dev` chia rồi giao từng cái.
- Không nói "xong" nếu chưa có bằng chứng verify.
