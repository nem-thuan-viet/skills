---
name: soi-code
description: >
  CỔNG SOI CODE tự động của Thuần Việt Platform — chạy TRƯỚC khi gộp code vào nhánh
  main (bản đang chạy thật trên platform.nguoithuanviet.com). Thay cho việc anh Bình
  đọc code từng người: chạy máy quét 34 cổng chia 5 nhóm (NGUY HIỂM: lộ khóa · lộ dữ liệu ·
  sai số · hỏng sổ sách · sập hệ — CHẠY PHÁT CHẾT — IM LẶNG KHÔNG CHẠY — VỠ DỮ LIỆU CŨ —
  LUẬT NHÀ), bắt chạy thử thật có bằng chứng, rồi phán
  🟢 TỰ GỘP ĐƯỢC / 🔵 SẠCH NHƯNG CẦN ANH BÌNH QUYẾT / 🔴 CHƯA XONG, PHẢI SỬA
  rồi soi lại — kèm báo cáo dán vào Pull Request.
  Hãy dùng skill này khi ai đó nói "soi code", "kiểm code giúp", "review giúp",
  "code xong rồi", "chuẩn bị push", "merge được chưa", "đẩy lên main được chưa",
  "kiểm trước khi đẩy", "gộp được chưa", hoặc khi vừa code xong một việc trong repo
  và sắp đẩy lên GitHub.
license: nội bộ NTV
metadata:
  author: Thuần Việt Platform
  version: "2.0"
  created: 2026-08-03
---

# Cổng soi code — gác cửa vào nhà mới

Nhà mới (Frappe Cloud) chỉ nhận code qua GitHub. Nhánh `main` của 7 kho trong org `nem-thuan-viet` = **bản đang chạy thật cho ~100 người**. Trước 03/08/2026 anh Bình đọc code từng người mới cho gộp — không kịp và không cần.

Cổng này làm phần máy làm được, và **chỉ đẩy lên anh Bình những việc thật sự cần người quyết**.

**Cổng KHÔNG:** tự gộp `main` · tự deploy · tự xoay khóa · tự quyết luật số liệu.
**Cổng CÓ:** quét, đọc ngữ cảnh, bắt chạy thử, phán verdict, soạn báo cáo.

## Tài liệu đi kèm

| File | Đọc khi nào |
|---|---|
| `scripts/quet.sh` | **Luôn** — chạy đầu tiên ở Bước 1 |
| `references/cong-chi-tiet.md` | Khi máy quét in ra dấu hiệu ⚑ cần đọc ngữ cảnh |
| `references/luat-erp.md` | Khi diff chạm chứng từ · sổ sách · kho · master data · code Frappe |
| `references/chay-thu.md` | **Luôn** — ở Bước 4 |
| `NHAT-KY-SOI.md` | **Luôn** — ghi một dòng ở Bước 6 |
| `evals/chay-test.sh` | **Sau mỗi lần sửa `quet.sh`** — chạy trước khi tin cổng còn nguyên |

---

## Năm nguyên tắc — đọc trước khi soi

1. **Chỉ soi dòng THÊM MỚI.** Gỡ một cái token cũ ra khỏi code là việc *tốt*. Máy quét đã lọc sẵn; khi soi tay cũng phải nhớ.
2. **Máy quét in DẤU HIỆU, không phán tội.** `grep` không hiểu code. Mỗi ⚑ phải mở file đọc ngữ cảnh rồi mới kết luận. Báo nhầm điển hình của từng cổng nằm ở `cong-chi-tiet.md`.
3. **Không chắc thì 🔴, đừng đoán 🟢.** Cho nhầm 🟢 là code hỏng vào bản chạy thật của 100 người. Cho nhầm 🔴 chỉ tốn thêm một vòng soi.
4. **Không có bằng chứng chạy được thì không 🟢.** Không có ngoại lệ cho việc "nhỏ, chắc chắn đúng".
5. **Không nới tay cho quen biết.** Verdict dựa vào bằng chứng, không dựa vào ai viết hay việc gấp cỡ nào.

---

## Bước 1 — Chạy máy quét

```bash
bash .claude/skills/soi-code/scripts/quet.sh
```

Nhánh gốc không tên `main` thì truyền tay: `quet.sh <nhánh-gốc>`.

Máy quét soi **cả ba tầng**: commit đã có · sửa chưa commit · file mới chưa add. Bỏ hai tầng sau là báo "sạch" giả — người ta gõ `/soi-code` **trước** khi commit là chuyện thường nhất. Mục A in rõ từng tầng bao nhiêu file.

Máy quét in: **A. Bối cảnh** (nhánh, kho, phạm vi ba tầng, commit) · **B. Cảnh báo nền** (đứng trên main, sai org, có phần chưa commit, khối quá lớn, file nặng) · **C→G. 34 cổng** chia 5 nhóm theo *hỏng kiểu gì*, kèm vị trí `file:dòng`.

Máy quét **không soi ruột chính nó** (`.claude/skills/soi-code/`) — nó là nơi định nghĩa các mẫu nên luôn tự khớp. Sửa cổng thì đọc tay, **rồi chạy `evals/chay-test.sh`**.

### Sửa `quet.sh` thì bắt buộc chạy lại bộ test

```bash
bash .claude/skills/soi-code/evals/chay-test.sh
```

Lý do: một cổng báo "sạch" có **hai** nghĩa — code thật sự sạch, hoặc **mẫu tìm bị sai nên không bao giờ khớp**. Nhìn kết quả quét thì hai cái giống hệt nhau. Bộ test phân biệt bằng số: lượt A nhét lỗi cài sẵn (cổng phải kêu), lượt B đưa code viết đúng (cổng phải im). Chi tiết ở `evals/README.md`.

**Dừng ngay, không soi tiếp, nếu máy quét báo:**
- 🔴 đang đứng trên `main`/`master` → bảo tạo nhánh `tên/việc` rồi làm lại.
- 🔴 remote ngoài org `nem-thuan-viet` → code này không có đường lên nhà mới; đây là việc chuyển kho, không phải việc sửa code.

**Nếu máy quét chạy lỗi** (không phải repo git, không tìm thấy nhánh gốc): xử lý cái đó trước. Đừng bỏ máy quét rồi soi tay — soi tay bỏ sót nhiều hơn.

---

## Bước 2 — Khoanh vùng và định tuyến

Từ phần A của máy quét, ghi lại: **nhánh · số file · số dòng thêm · app nào bị đụng**.

Rồi chọn cổng nào phải soi kỹ theo loại thay đổi:

| Diff chạm vào | Cổng bắt buộc soi kỹ | Đọc thêm |
|---|---|---|
| `*.py` trong app Frappe | 1 · 3 · 5 · 6 · 9 · 10 | `luat-erp.md` A–F |
| `doctype/*.json`, `fixtures/` | 3 · 9 · 10 | `luat-erp.md` D |
| Chứng từ, kế toán, kho | **9** (nặng nhất) · 7 | `luat-erp.md` A–C |
| Báo cáo, query, dashboard | 5 · 8 · 9d · 10e | `luat-erp.md` C3 · F |
| Frontend (`*.js`, `*.vue`) | 1 · 5 · 8 | — |
| Job nền, `scheduler_events` | 6 · 9 · 10 | `luat-erp.md` E |
| `pyproject.toml`, cấu hình build | 4 | — |
| Sync nguồn ngoài, ETL | 1 · 6 · 8 · 10e | `luat-erp.md` D3 · F |
| Chỉ tài liệu `*.md` | 1 · 8 | — |

**Khối quá lớn (>2000 dòng thêm):** vẫn soi, nhưng ghi vào báo cáo *"khối lớn, độ tin của lần soi này thấp hơn"* và khuyên tách nhỏ lần sau. Đừng giả vờ soi kỹ được một khối 5000 dòng.

**Diff rỗng ở CẢ BA tầng:** chưa sửa gì thật, hoặc đang so sai nhánh gốc.

**Có phần chưa commit:** vẫn soi bình thường, nhưng ghi vào báo cáo rằng verdict chỉ có giá trị **sau khi commit đúng những thứ đó** — vì mã commit là thứ neo verdict lại.

---

## Bước 3 — Đọc từng dấu hiệu

Với **mỗi** ⚑ máy quét in ra:

1. Mở file tại đúng dòng đó, đọc **cả hàm**, không đọc mỗi một dòng.
2. Tra `cong-chi-tiet.md` mục tương ứng — ở đó có **báo nhầm điển hình** và **ví dụ SAI ↔ ĐÚNG**.
   ⚠️ File này mới phủ **nhóm C (cổng nguy hiểm, C1–C10e)**. Các cổng nhóm D/E/F/G mang phần "cách đọc" **in thẳng trong kết quả máy quét** — đọc dòng đó, đừng đi tìm trong `cong-chi-tiet.md`.
3. Chạm sổ sách/chứng từ/kho/master data → tra thêm `luat-erp.md`.
4. Kết luận: **thật sự sai** hay **báo nhầm**. Ghi bằng chứng `file:dòng` cho cả hai loại — báo nhầm cũng phải ghi để lần sau không phải soi lại.

Rồi soi thêm ba thứ **máy quét không bắt được**, phải đọc bằng mắt:

- **Code có làm đúng việc được giao không.** Máy không biết yêu cầu là gì. Hỏi người viết: việc này giải quyết vấn đề nào? Code có khớp không, có làm dư thứ không ai xin không?
- **Có xóa/sửa nhầm thứ của người khác không.** `git diff` có động vào file ngoài phạm vi việc đang làm? Sửa "tiện tay" file bên cạnh = 🔴, tách ra commit riêng rồi soi lại.
- **Có code chết, code thử còn sót lại không** — `print()` gỡ lỗi, endpoint thử, dữ liệu cứng để test.

**Có file Frappe (`.py`/`.js`/DocType JSON)** → gọi thêm skill **`frappe-agent-validator`** soi cú pháp và bẫy v16. Cộng kết quả nó vào báo cáo, đừng soi lại bằng tay.

---

## Bước 4 — Bắt chạy thử thật

Đọc `references/chay-thu.md`, chọn phép thử theo loại việc, **lấy bằng chứng dán được**.

Ba phép thử bắt buộc nếu chạm đúng vùng:
- **Chạm chứng từ / sổ sách** → kiểm tổng nợ = tổng có của bút toán liên quan.
- **Chạm quyền / API** → thử bằng **tài khoản thường**, không phải Administrator.
- **Chạm việc nặng** → đếm số bản ghi trước, đo thời gian một lô.

Không thử được → 🔴, ghi rõ: đã thử tới đâu · vướng gì · cần gì để thử được. **Không nói dối là đã thử.**

---

## Bước 5 — Phán verdict

| Verdict | Điều kiện | Làm gì tiếp |
|---|---|---|
| 🟢 **XANH** | mọi cổng đạt (hoặc đã xác nhận là báo nhầm) **và** có bằng chứng chạy được | **Tự gộp vào `main`, không cần hỏi anh Bình.** Dán báo cáo vào Pull Request |
| 🔵 **XANH DƯƠNG** | Y hệt điều kiện 🟢 (cổng sạch + có bằng chứng chạy được) **nhưng** việc rơi vào phạm vi chỉ anh Bình được quyết | **Không tự gộp** — không phải vì code sai, chỉ vì vượt quyền người soi. Báo anh Bình, không cần sửa gì |
| 🔴 **ĐỎ** | Còn thứ chưa đạt — cổng bắt được lỗi (chưa xác nhận là báo nhầm), chưa có bằng chứng chạy được, hoặc chạm loại luôn-luôn-chặn-cứng | **Không gộp.** Sửa/thử tiếp rồi soi lại từ Bước 1 |

**Chỉ 3 mức, không chia "nhẹ/nặng" ở tầng verdict** — 🟡 (lỗi nhẹ sửa nhanh) và mức "nguy hiểm phải sửa trước" từng tách riêng, nhưng dẫn tới **đúng một hành động**: chưa gộp, sửa/thử rồi soi lại. Tách hai màu chỉ thêm rối mà không đổi việc phải làm. Mức độ nặng-nhẹ của từng lỗi vẫn ghi rõ trong nội dung báo cáo (từng cổng ⚑ nặng cỡ nào) — chỉ không cần làm thành màu riêng ở đây.

🔴 và 🔵 dễ lẫn vì cả hai đều "không tự gộp được" — nhưng **khác nhau ở việc có phải sửa gì không**: 🔴 là còn việc phải làm (sửa code, hoặc đi thử cho có bằng chứng); 🔵 là việc đã xong, chỉ đợi người có quyền bấm nút. Đừng gắn 🔴 cho việc thứ hai — nhìn vào sổ nhật ký sẽ tưởng code hỏng liên tục, trong khi 34 cổng vẫn sạch mỗi lần.

**Bốn loại luôn phải báo anh Bình** — máy không quyết thay người được, nhưng verdict tùy loại:

1. **Lộ khóa/mật khẩu** → luôn **🔴**. Xóa khỏi code là chưa đủ, khóa đã vào lịch sử git thì phải **xoay khóa mới** — báo anh Bình để xoay, dù code đã sửa sạch.
2. **Ghi tay vào sổ cái/sổ kho, xóa/sửa chứng từ đã chốt** → luôn **🔴** (xem `luat-erp.md` — đây là loại luôn-chặn-cứng, không phải chuyện thẩm quyền).
3. **Đụng app nền `ntv`** (sửa file trong app nền, không phải đẻ bản sao master data — cái đó vẫn 🔴 ở Cổng 3) → **🔵** nếu 34 cổng sạch + có bằng chứng chạy được. App nền là của anh Bình, không phải lỗi kỹ thuật.
4. **Đụng cách tính số liệu / luật dữ liệu chưa chốt** (công thức doanh thu, phân bổ team, lương/tài chính) → **🔵** nếu code kỹ thuật đúng nhưng tự chế công thức chưa ai chốt; **🔴** nếu code ghi thẳng số chưa qua kiểm lên báo cáo BOD.

**Quy tắc gộp mức:** một 🔴 là cả lần soi 🔴, không bù trừ bằng chín cổng xanh. Một 🔵 (không có 🔴 nào) thì cả lần soi 🔵 — vẫn không tự gộp, nhưng ghi rõ trong báo cáo là **chờ quyết, không phải chờ sửa**.

### Verdict hết hiệu lực khi nào

🟢 và 🔵 chỉ có giá trị cho **đúng cái đã soi**. Ghi commit cuối vào báo cáo để đối chiếu:

```bash
git rev-parse --short HEAD     # dán số này vào báo cáo
```

**Thêm commit mới sau khi soi xanh → verdict cũ BỎ, soi lại từ Bước 1.** Kể cả khi commit thêm chỉ là sửa chính tả — vì không ai kiểm được "chỉ sửa chính tả" mà không soi.

Cũng phải soi lại khi: `rebase`/`merge main` vào nhánh (code nền đã đổi) · sửa theo góp ý của người khác · đổi nhánh đích.

Khi soi lại, **không cần soi từ đầu toàn bộ**: chạy máy quét lại (nó nhanh), rồi chỉ đọc kỹ phần diff mới thêm. Nhưng verdict phải phát lại, không nói "lần trước xanh rồi".

---

## Bước 6 — Soạn báo cáo + ghi nhật ký

### 6a. Ghi một dòng vào `NHAT-KY-SOI.md`

**Làm trước, đừng bỏ.** Không có sổ thì không đo được cổng tốt hay dở, và mọi tranh cãi về cổng sẽ chỉ dựa vào cảm giác. Nối vào cuối bảng:

```
| <ngày> | <commit ngắn> | <n file / n dòng> | <verdict> | <mã cổng đã kêu, hoặc —> | <đúng ?/nhầm ?> | |
```

Cột cuối (**bỏ sót**) **để trống** — chỉ điền sau, khi có thứ vỡ mà lần soi này đã cho qua. Đó là cột đắt nhất: nó đo cái cổng KHÔNG bắt được, thứ không đo được lúc soi.

### 6b. Soạn báo cáo

In ra để người đó dán vào Pull Request. **Pull Request là cuốn sổ** — sau này có chuyện thì lần theo đây.

```
## Kết quả soi code — <🟢 XANH / 🔵 XANH DƯƠNG (cần anh Bình quyết) / 🔴 ĐỎ (chưa xong)>

**Nhánh:** <tên nhánh> → main
**Soi tại commit:** <mã commit ngắn>   ← thêm commit mới thì báo cáo này hết giá trị
**Phạm vi:** <n> file, <n> dòng thêm, app <tên>
  (commit đã có <n> · sửa chưa commit <n> · file mới chưa add <n>)
**Việc:** <một câu — code này làm gì>

| Nhóm cổng | Kết quả |
|---|---|
| C. Nguy hiểm — lộ khóa · lộ dữ liệu · sai số · hỏng sổ · sập hệ | ✅ / ❌ <mã cổng + file:dòng> |
| D. Chạy phát chết ngay | ✅ / ❌ |
| E. Im lặng không chạy | ✅ / ❌ |
| F. Vỡ dữ liệu cũ | ✅ / ❌ / không đụng |
| G. Luật nhà NTV | ✅ / ❌ |
| Bốn thứ grep không bắt được (đọc tay) | ✅ / ❌ / không đụng |
| Cú pháp Frappe (validator) | ✅ / ❌ / không chạy |

**Đã chạy thử:**
<làm gì — kết quả THẬT, dán số/log/ảnh>

**Dấu hiệu đã xem và kết luận là báo nhầm:**
<file:dòng — vì sao không phải lỗi>

**Còn phải sửa:**
<liệt kê, hoặc "không">

**Cần anh Bình:**
<lý do cụ thể, hoặc "không">
```

---

## Tình huống đặc biệt

**Người soi không phải dân code** (nhiều bạn dùng Claude Code làm việc nhưng không đọc được code). Đừng đọc thuật ngữ ra rồi bắt họ tự hiểu. Nói bằng lời thường: *"chỗ này đang để lộ mật khẩu, phải đổi mật khẩu mới, em đừng lo phần đó — báo người phụ trách là được."* Verdict vẫn giữ nguyên độ nghiêm.

**Repo mới chưa có `main`** — máy quét sẽ báo. So với commit đầu tiên, và ghi rõ trong báo cáo là kho mới.

**Code do AI viết phần lớn** — soi kỹ hơn, không nhẹ tay hơn. Chỗ AI hay sai: thêm tính năng không ai xin · bọc lớp trung gian cho code dùng một lần · xử lý lỗi cho tình huống bất khả · đổi tên/format file bên cạnh "tiện tay".

**Soi code của người khác** (không phải người viết ngồi cạnh) — không tự sửa hộ rồi cho 🟢. Đề xuất bản vá, người ta nhận thì **soi lại từ Bước 1**.

**Việc gấp, sắp deploy** — quy trình không rút ngắn. Gấp thì bỏ bớt phạm vi việc, không bỏ bớt cổng soi.

---

## Ranh giới với các skill khác

- `frappe-agent-validator` — soi **cú pháp** Frappe. Cổng này gọi nó ở Bước 3, không làm thay.
- `/nghiem-thu` — kiểm **kết quả** một việc đã xong (số liệu, hành vi thật). Cổng này soi **code trước khi gộp**. Việc gắt (số BOD, dữ liệu tài chính, lương) nên qua cả hai.
- `/thuc-thi` — người làm. Cổng này là người gác. Không kiêm nhau.
