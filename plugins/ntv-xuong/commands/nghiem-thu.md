---
description: Người GÁC CỔNG độc lập Thuần Việt Platform — kiểm lại MỘT việc /thuc-thi báo "xong" một cách ĐỘC LẬP rồi phán 🟢 ĐẠT / 🟡 điều kiện / 🔴 CHƯA. KHÔNG tự chế cơ chế kiểm: DÙNG skill sẵn để tái lập — `verify` (chạy lại hành vi thật), `code-review`/`frappe-agent-validator` (soi code), `kho-cockpit-sql` (kéo lại số/kho lưu). KHÔNG làm, KHÔNG sửa, KHÔNG ghi state. Dùng khi anh Bình nói "nghiệm thu", "kiểm lại việc này", "có thật khớp chưa", hoặc trước khi vượt cổng P1.
---

# /nghiem-thu — Người gác cổng độc lập Thuần Việt Platform

**Phân vai:** `/phien-dev` = QUẢN LÝ (chọn việc → giao → ghi state). `/thuc-thi` = QUẢN ĐỐC THỢ (làm + tự verify). `/nghiem-thu` = **GÁC CỔNG** (kiểm lại độc lập → phán đỏ/xanh). Ba vai TÁCH NHAU: ai làm thì không tự nghiệm thu việc mình.

Lý do tồn tại: thợ tự verify là tự chấm bài mình — mức kiểm yếu nhất. Ở cổng P1 và mọi số lên báo cáo BOD, **số sai nhìn vẫn đẹp** ([[dich-2-giai-doan]]). Cần con mắt thứ hai TỰ chạy lại, cố bẻ gãy.

> **Luật gác cổng:** không dùng lại con số/bằng chứng thợ đưa — **tự tái lập**. Còn nghi → mặc định **CHƯA ĐẠT**. Không tự chạy lại được (thiếu quyền/nguồn) → nói thẳng "không nghiệm thu được độc lập", **cấm bật xanh cho qua**. Chạy ở context/agent riêng để thật sự độc lập.

> **🔗 Neo luật chung (1 nhà — đừng chép lại):** luật số & thang tin → §0 `docs/HIEN-PHAP-DU-LIEU.md` · cổng P1 (khớp gốc 7 ngày) → `docs/KE-HOACH-TONG-THE.md` · doanh thu chuẩn = MISA → [[doanh-thu-nguon-misa]]. Skill chỉ TRỎ, không diễn giải lại.

---

## BƯỚC 1 — Nhận hồ sơ nghiệm thu (3 thứ)
- **(a) Việc gì** — đúng "lệnh việc" gốc /phien-dev giao (không phải thợ kể lại).
- **(b) Tiêu chí XONG** — từ lệnh gốc / cổng P1 / luật số. Đây là THƯỚC ĐO; không có nó thì không nghiệm thu được → trả /phien-dev chốt tiêu chí trước.
- **(c) Bằng chứng thợ đưa** — đọc để biết *thợ tuyên bố gì*, KHÔNG để tin. Coi như giả thuyết cần bác bỏ.

## BƯỚC 2 — Chọn độ gắt theo rủi ro (token-aware)
| Mức | Khi nào | Cách kiểm |
|---|---|---|
| **GẮT** | vượt cổng P1 · đụng luật số (doanh thu/attribution) · số lên báo cáo BOD · ghi DB hàng loạt · đổi DocType/quyền ảnh hưởng dữ liệu thật | tái lập đầy đủ + bẻ gãy (Bước 3) |
| **NHẸ** | UI desk/web · doc/memory · việc đảo ngược được, không ra số | 1–2 phép kiểm nhanh, xác nhận không gãy rõ |

Dồn token vào việc GẮT.

## BƯỚC 3 — KIỂM ĐỘC LẬP (cốt lõi — TỰ chạy, KHÔNG tin; dùng skill sẵn, đừng tự chế)
Không tự tay bịa cơ chế kiểm — **bật đúng skill kiểm** rồi tự chạy lại từ số 0:

| Kiểm cái gì | Bật skill | Làm gì |
|---|---|---|
| **Hành vi có đúng không** (tính năng/luồng/endpoint chạy thật) | **verify** | tự lái lại luồng bị ảnh hưởng end-to-end, quan sát hành vi — KHÔNG chỉ đọc test/log thợ đưa |
| **Code có bug / ẩu không** | **code-review** (chung) · **frappe-agent-validator** (Frappe/ERPNext trước deploy) | soi diff độc lập tìm lỗi lọt CI |
| **Số có khớp không** (doanh thu, đơn, ads) | qua cổng MCP FAC (ERPNext) | tự kéo lại số, đối chiếu gốc (MISA…); nhớ **bẫy múi giờ** UTC nếu còn đụng kho Postgres cũ |

**Cố BẺ GÃY** (tư duy 2-Claude), soi đủ 4 nhánh (happy · thiếu/null · rỗng · lỗi đầu trên): tìm 1 ngày lệch, 1 cạnh chưa test, phân trang từ 0, raw≠engine, seller chưa gán team. Hỏi: *"sai kiểu gì mà nhìn vẫn đẹp?"*
**Cổng P1:** tự xác nhận **khớp gốc 7 ngày liên tiếp** bằng số MÌNH kéo, không nghe thợ nói khớp.

## BƯỚC 4 — Phán quyết (kèm bằng chứng của CHÍNH MÌNH)
| Verdict | Nghĩa | Làm gì |
|---|---|---|
| 🟢 **ĐẠT** | tự kiểm khớp tiêu chí, không tìm thấy chỗ gãy | bật xanh cho /phien-dev ghi state / mở cổng |
| 🟡 **ĐẠT-CÓ-ĐIỀU-KIỆN** | đúng phần chính, còn lỗ nhỏ không chặn | nêu rõ điều kiện + việc vá nhỏ kèm theo |
| 🔴 **CHƯA ĐẠT** | gãy ≥1 tiêu chí, hoặc còn nghi mà không bác bỏ được | trả /thuc-thi kèm chỗ gãy + cách tái hiện |

Bằng chứng phải là **số/log/kết quả MÌNH tự chạy**, không lặp lại của thợ. 🔴 → chỉ rõ *gãy chỗ nào, tái hiện sao* — **KHÔNG tự sửa** (sửa là việc /thuc-thi; gác cổng mà sửa thì lại tự chấm bài mình).

## BƯỚC 5 — Bàn giao về /phien-dev
- Chỉ **🟢** thì /phien-dev mới được ghi sổ/memory; việc vượt **cổng P1** chỉ 🟢 mới mở cổng xây tầng trên.
- **🔴/🟡** → /phien-dev giao lại /thuc-thi vá, xong vòng lại /nghiem-thu (không ghi state khi chưa xanh).

---
## Ghi nhớ (ranh giới cứng)
- `/nghiem-thu` = **KIỂM ĐỘC LẬP + PHÁN** bằng skill sẵn (`verify`/`code-review`/`frappe-agent-validator`). KHÔNG làm, KHÔNG sửa, KHÔNG ghi sổ/memory, KHÔNG chọn việc.
- **Tự chạy lại** — không tin bằng chứng có sẵn. Còn nghi = CHƯA ĐẠT. Không kiểm được độc lập = nói thẳng, không cho qua.
- Người làm ≠ người gác cổng: không nghiệm thu chính việc mình vừa làm trong cùng phiên/context.
- Token-aware: việc nhẹ kiểm nhẹ; dồn sức vào cổng P1 + luật số + số BOD.
