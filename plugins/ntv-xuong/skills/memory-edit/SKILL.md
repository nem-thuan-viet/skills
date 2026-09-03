---
name: memory-edit
description: "Chuẩn THIẾT KẾ MỤC LỤC + GHI/SỬA memory (trí nhớ dài hạn giữa các phiên) của Thuần Việt Platform. Nguyên tắc gốc: MỘT CHỦ ĐỀ = MỘT FILE = MỘT DÒNG mục lục, để phiên sau đẩy lệnh đi mà không phải cân nhắc. Hãy dùng skill này BẤT CỨ KHI NÀO đụng tới memory: khi anh Bình nói 'nhớ giúp anh cái này', 'lưu lại đi', 'ghi vào memory', 'cập nhật memory', 'dọn memory', 'memory trùng rồi', 'gộp memory lại', 'sao mày nhớ sai', 'sửa mục lục', 'xây lại mục lục'; khi sắp sửa MEMORY.md; khi phát hiện 2 file memory cùng chủ đề hoặc nói khác nhau; khi mục lục sắp chạm trần 200 dòng; hoặc khi tự thấy cuối phiên có việc đáng lưu. Cũng dùng trước khi chạy consolidate-memory."
---

# Sửa memory đúng chuẩn — Thuần Việt Platform

## Vì sao skill này tồn tại

Memory không có máy tìm kiếm. Tài liệu chính thức của Claude Code nói thẳng: file chủ đề **không được nạp lúc mở phiên**, Claude *"reads them on demand using its standard file tools"* — mở bằng lệnh đọc file thường. Chỉ `MEMORY.md` được nạp sẵn, và chỉ **200 dòng đầu hoặc 25KB**, cái nào tới trước.

Hệ quả: **không có xếp hạng, không có "file mới nhất thắng".** Phiên sau mở file nào là do đọc **mục lục** rồi tự quyết.

**Giá đã trả (17/08/2026):** hỏi *"sidebar Thuần Việt bao nhiêu mục"* → trả lời **56**. Số đúng là **71**. Ba file cùng nói về sidebar; dòng mục lục của file cũ có sẵn chữ "56 mục" nên trả lời được luôn **mà không mở file nào**; file đúng thì dòng mục lục không nhắc gì tới số mục nên bị bỏ qua.

Anthropic chốt đúng gốc bệnh này trong bài *Effective context engineering for AI agents*:

> *"If a human engineer can't definitively say which tool should be used in a given situation, an AI agent can't be expected to do better."*

Dịch sang bài toán mục lục: **anh Bình không chỉ ra được ngay phải mở dòng nào, thì Claude cũng không.** Sự mơ hồ ở mục lục không thể chữa bằng cách viết khéo hơn — phải chữa bằng cách **xoá bỏ sự mơ hồ**.

Skill chia hai phần theo thứ tự quan trọng:

| | Phần | Quyết định điều gì |
|---|---|---|
| **1** | **Mục lục `MEMORY.md`** | File nào được mở — và câu trả lời khi **không mở file nào** |
| **2** | **Ruột từng tờ** | Nội dung trả lời sau khi đã mở đúng file |

**Phần 1 quan trọng hơn.** Ruột hay tới mấy mà mục lục không dẫn tới thì tờ đó không bao giờ được đọc.

---

# PHẦN 1 — THIẾT KẾ MỤC LỤC

## Nguyên tắc gốc

> **Trang 1 là bảng ĐỊA CHỈ, không phải bản tóm tắt.**
> **Mỗi chủ đề đúng một dòng — và với mọi cách anh Bình có thể hỏi, chỉ đúng một dòng khớp.**

Ba tính chất khiến mục lục khác mọi file khác:

1. **Nó là thứ duy nhất tốn token mỗi phiên**, kể cả phiên không dùng memory. Chi phí cố định, phải đáng đồng tiền. Anthropic gọi mục tiêu này là *"find the smallest set of high-signal tokens"*.
2. **Nó bị CẮT ĐUÔI, không cắt giữa.** *"The first 200 lines … are loaded … Content beyond that threshold is not loaded."* Dòng 201 trở đi **biến mất im lặng** — không lỗi, không dấu vết. Thứ tự dòng là thiết kế, không phải thẩm mỹ.
3. **Nó thường được trả lời thẳng, không cần mở file.** Móc câu chứa con số thì con số đó được lấy luôn. Số sai ở mục lục **sai từ giây đầu của phiên**.

## Nhóm A — Luật MỘT CỬA (cốt lõi, đừng nhân nhượng)

### Đ1. Một chủ đề = một file = một dòng

Hai file cùng chủ đề **không phải chuyện phải sống chung** — đó là **lỗi ở tầng dưới**, và phải sửa ở tầng dưới bằng cách **gộp file**.

**Cấm vá ở mục lục.** Viết một dòng gộp kiểu *"đọc file A trước, file B là nền, file C là bẫy lẻ"* nghe có vẻ chu đáo nhưng thực chất là **hợp thức hoá sự trùng lặp**: nó vẫn bắt phiên sau đọc rồi cân nhắc. Mục tiêu là **không còn gì để cân nhắc**.

Cơ sở: Johnny.Decimal — *"only one correct location for each file"*; và authority control trong thư viện học — mỗi khái niệm đúng **một tiêu đề được phép**, *"no two authorized terms are the same within any controlled vocabulary."*

### Đ2. Từ đồng nghĩa nhét VÀO dòng đó, không đẻ dòng mới

Đây là kỹ thuật `see` reference của thư viện: cách gọi khác **không được có mục riêng**, chúng trỏ về tiêu đề chính.

Anh Bình có thể hỏi "sidebar", "menu trái", "thanh bên", "cột trái desk", "71 mục" — **tất cả phải nằm trong cùng một móc câu**, để mọi cách hỏi đều dẫn về một cửa.

| ❌ | 3 dòng cho sidebar, mỗi dòng một cách gọi |
|---|---|
| ✅ | 1 dòng: `sidebar desk (menu trái / thanh bên) — 71 mục, commit 23a74cc đã push` |

### Đ3. Tên file là ĐỊA CHỈ CỐ ĐỊNH

Johnny.Decimal: địa chỉ *"permanent, unchanging … works for years"*. Đổi tên file là **gãy mọi `[[link]]` trỏ tới nó**, và gãy im lặng.

Chỉ đổi tên khi tên cũ sai chủ đề. Đổi rồi thì phải quét lại toàn bộ `[[...]]` trong kho.

### Đ4. Phép thử một cửa — làm trước khi lưu

Nghĩ ra **3 câu anh Bình có thể hỏi** về việc này, bằng 3 cách nói khác nhau. Dò xem mỗi câu khớp mấy dòng trong mục lục.

- Khớp **đúng 1 dòng** → đạt.
- Khớp **>1 dòng** → thiết kế sai. Gộp file theo **Đ1**, hoặc tách lại chủ đề cho hết chồng lấn.
- Khớp **0 dòng** → móc câu thiếu từ khoá, sửa theo **Đ6**.

Đây là phép thử rẻ nhất và bắt được nhiều lỗi nhất. Đừng bỏ.

## Nhóm B — Luật VIẾT DÒNG

### Đ5. Mục lục chứa địa chỉ, không chứa tri thức

Quy định gốc: *"never put memory content there."* Đang **giải thích** một luật ngay trong mục lục nghĩa là phần đó thuộc về file — chuyển xuống, để lại móc câu.

Thử nhanh: dòng mục lục mà đọc xong **không cần mở file nữa** thì nó đã nuốt mất nội dung của file.

### Đ6. Móc câu viết theo CÂU ANH BÌNH SẼ HỎI

Không viết theo tiêu đề file. Nhét vào **từ khoá tra cứu**: con số, tên nhánh, tên màn hình, tên lỗi, tên công cụ, và các cách gọi khác theo **Đ2**.

| ❌ viết theo tiêu đề | ✅ viết theo câu sẽ hỏi |
|---|---|
| "dựng nhà cho DocType, breadcrumb" | "sidebar desk (menu trái) **71 mục**, commit `23a74cc` đã push" |

### Đ7. Số BIẾT ĐỔI phải kèm ngày

Vì mục lục nạp mỗi phiên và thường được trả lời thẳng, số sai ở đây nguy hơn số sai trong file.

- **Kèm ngày:** trạng thái (push/gộp/deploy/xong-chưa) · tiến độ · số đang chạy · mã commit · giá · hạn dùng. → `56 mục (05/08/2026)`
- **Không cần:** số cấu trúc năm thì mười hoạ mới đổi — `3 pháp nhân`, `7 kho code`, `4 chặng`. Ép gắn ngày chỉ làm dòng dài vô ích.

## Nhóm C — Luật XẾP TRANG

### Đ8. Nhóm theo MỘT trục duy nhất — trục CHỦ ĐỀ

Trộn nhiều trục phân loại là gốc khiến "một chủ đề một chỗ" không thực hiện được. Ví dụ có thật:

| Nhóm | Trục |
|---|---|
| "Đang treo" | **trạng thái** |
| "Bẫy đã trả giá" · "Luật nhà" | **thể loại** |
| "Hạ tầng" · "Nguồn dữ liệu" | **chủ đề** |

Trộn ba trục thì một file có **nhiều nhà hợp lệ cùng lúc** — nằm đâu cũng có lý, nên tìm ở đâu cũng có lý. Đúng cái Anthropic cảnh báo.

**Chữa:** chọn trục **chủ đề** làm trục duy nhất, hạ trạng thái xuống thành **dấu trên dòng**:

```markdown
## 0 · Đọc trước — cách làm việc
## 1 · Luật nhà
## 2 · Bẫy đã trả giá
## 3 · Dự án & nghiệp vụ        🔴 = đang treo · 🟢 = xong
## 4 · Hạ tầng · cổng · công cụ
## 5 · Nguồn dữ liệu
## 6 · Đích · người · cơ cấu
```

Được ba thứ cùng lúc: mỗi file **đúng một nhà** · xem việc treo thì **quét dấu 🔴** không cần nhóm riêng · vẫn giữ được thứ tự ưu tiên của **Đ9**.

Đánh số nhóm là mượn Johnny.Decimal: nhóm có địa chỉ cố định, thêm bớt file không xô lệch cấu trúc.

### Đ9. Quan trọng lên đầu — vì trần cắt từ đáy

Xếp nhóm theo **tần suất mở**, không theo thứ tự thời gian. Nhóm dưới cùng phải là nhóm **chịu mất được**, vì đó là nhóm rơi khỏi trần trước tiên.

### Đ10. Không chép thứ `CLAUDE.md` đã có

`CLAUDE.md` cũng nạp mỗi phiên. Chép lại là trả tiền hai lần cho cùng một câu. Thay vì chép, để một dòng ghi chú kiểu *"luật nhà + chỗ làm việc nằm ở `CLAUDE.md`, đừng chép lại vào đây"* — vừa tiết kiệm, vừa nhắc phiên sau đừng tái phạm.

## Ràng buộc ngân sách (không phải luật thiết kế)

| Thứ | Ngưỡng | Ghi chú |
|---|---|---|
| `MEMORY.md` | **200 dòng / 25KB** | Cứng. Vượt là **cắt từ đáy, im lặng** |
| Một dòng | ~150 ký tự | **Tham chiếu, không phải luật.** Chỉ ép khi mục lục vượt **160 dòng hoặc 20KB** |

Kiểm bằng máy, đừng ước:

```bash
bash .claude/skills/memory-edit/scripts/soat-memory.sh
```

Khi mục lục sắp đầy, thứ tự xử lý — **gộp file trước, xoá sau**:
1. **Gộp file** các chủ đề trùng theo **Đ1** (thu được nhiều dòng nhất, không mất thông tin).
2. Rút gọn dòng đang mang chi tiết lẽ ra thuộc về file (**Đ5**).
3. Bỏ dòng trỏ tới memory hết giá trị — và **xoá luôn file đó**, đừng để file mồ côi.

---

# PHẦN 2 — RUỘT TỪNG TỜ

## Bước 0 — Tìm trước khi tạo (bước hay bị bỏ nhất)

Trước khi tạo file mới, **luôn liệt kê thư mục memory và đọc `MEMORY.md`** xem đã có tờ nào cùng chủ đề chưa.

Quy định gốc: *"Before saving, check for an existing file that already covers it. Update that file rather than creating a duplicate."* Trang Memory tool nói gọn hơn: *"Đừng tạo file mới nếu không thật cần."*

Có tờ cũ rồi thì **sửa tờ đó**. Đẻ tờ mới là cách nhanh nhất phá vỡ **Đ1**.

## Khuôn file (Anthropic quy định)

```markdown
---
name: <ten-kieu-kebab-case>
description: <MỘT dòng — dùng để quyết định có mở file này hay không>
metadata:
  type: user | feedback | project | reference
---

<sự thật>

**Why:** <vì sao lại thế>
**How to apply:** <lần sau gặp thì làm gì>

[[to-lien-quan]] — <lý do phải bấm sang>
```

Nguyên văn: *"the fact; **for feedback/project**, follow with **Why:** and **How to apply:** lines. Link related memories with [[their-name]]."*

`modified` (ISO 8601) do hệ thống tự ghi — đừng đặt tay.

### `Why` + `How to apply` chỉ bắt buộc với 2 trong 4 loại

| `type` | Chứa gì | Cần `Why` + `How to apply`? |
|---|---|---|
| `project` | Việc đang chạy, ràng buộc **không suy ra được từ code/git** | ✅ có |
| `feedback` | Anh Bình dạy cách làm việc — kèm lý do | ✅ có |
| `user` | Anh Bình là ai — vai trò, chuyên môn, sở thích | ❌ không |
| `reference` | Trỏ ra ngoài — URL, dashboard, ticket | ❌ không |

Lý do phân đôi: hai loại trên là **việc phải làm** nên mới cần biết *vì sao* và *lần sau làm gì*; hai loại dưới chỉ là thông tin nằm im.

⚠️ Đừng khái quát thành "mọi file đều 3 phần" — sai, và đã có người mắc.

### Luật gốc còn lại

- **Một file = một sự thật** (*"Each memory is one file holding one fact."*).
- **Ngày tuyệt đối** — loại `project` phải đổi "tuần sau / quý này" thành ngày cụ thể.
- **Sai thì xoá** (*"delete memories that turn out to be wrong."*).
- **Không chép thứ repo đã có** — cấu trúc code, lịch sử git, lỗi đã sửa, nội dung `CLAUDE.md`; cũng không ghi thứ chỉ dùng trong đúng cuộc trò chuyện đó.
- **Ghi file xong phải thêm đúng 1 dòng vào `MEMORY.md`** — file không có dòng mục lục là file chết.

## 4 luật nhà cho ruột tờ

### R1. `description` viết theo CÂU ANH BÌNH SẼ HỎI

Giống **Đ6**, và vì cùng một lý do: đây là chữ đem đi so khớp lúc chọn file. Nhét đủ từ khoá tra cứu và các cách gọi khác. Không có → file coi như không tồn tại.

### R2. Số liệu và trạng thái phải kèm ngày, ngay tại chỗ

Viết "**56 mục (tính đến 05/08/2026)**". Áp cho số biết đổi, như **Đ7**.

### R3. Tờ bị lật thì phải TỰ KHAI — ở ba chỗ

⚠️ **Đây là phương án TẠM.** Theo **Đ1**, hai file cùng chủ đề thì cách đúng là **gộp**. Chỉ dùng R3 khi chưa kịp gộp, hoặc khi file cũ vẫn còn phần riêng có giá trị (bẫy kỹ thuật, gốc bệnh) mà chưa quyết được đưa đi đâu.

Khi đó, sửa **file cũ** ở đủ ba chỗ:

1. **`description`** — chỗ chạy lúc chọn file.
2. **Dòng đầu ruột**, kèm `[[file mới]]`.
3. **Dòng mục lục** trong `MEMORY.md` — chỗ hay quên nhất, mà lại là chỗ nạp mỗi phiên.

```markdown
---
description: "Sidebar desk v16 lạc về 'Kho' — vá bằng 1 sidebar dùng chung.
  ⚠️SỐ MỤC + trạng thái push trong file này ĐÃ CŨ → số mới ở [[no-15-muc-sidebar-nha-moi]].
  Giá trị còn lại: gốc bệnh + bẫy TÊN FILE PHẢI CÓ DẤU"
---

⚠️ **Số 56 và "chưa push" bên dưới tính đến 05/08/2026 — ĐÃ BỊ LẬT.**
Mới nhất: **71 mục**, commit `23a74cc` đã push → **[[no-15-muc-sidebar-nha-moi]]**.
```

### R4. Link phải có lý do đi kèm

Link trần đọc thành *"đọc thêm nếu rảnh"*. Link có lý do đọc thành *"phải bấm"*.

| ❌ | `Liên quan: [[no-15-muc-sidebar-nha-moi]]` |
|---|---|
| ✅ | `[[no-15-muc-sidebar-nha-moi]] — giữ SỐ MỤC mới nhất, lật con số trong file này` |

---

## Checklist trước khi lưu

**Mục lục (làm trước):**
- [ ] **Phép thử một cửa (Đ4)**: nghĩ 3 câu hỏi khác cách nói — mỗi câu chỉ khớp đúng 1 dòng chứ?
- [ ] Đã có file nào cùng chủ đề chưa? Có → **gộp file (Đ1)**, tuyệt đối không thêm dòng thứ hai.
- [ ] Các cách gọi khác đã nhét vào cùng dòng chưa **(Đ2)**?
- [ ] Móc câu có chứa từ khoá anh Bình sẽ gõ không **(Đ6)**?
- [ ] Số **biết đổi** đã kèm ngày chưa **(Đ7)**? Số cấu trúc thì thôi.
- [ ] Dòng này có đang giải thích thay cho file không **(Đ5)**?
- [ ] File nằm đúng **một** nhóm chủ đề chứ **(Đ8)**? Trạng thái để bằng dấu 🔴, không đẻ nhóm mới.
- [ ] `MEMORY.md` còn dưới 200 dòng / 25KB? Nhóm quan trọng có nằm trên không **(Đ9)**?

**Ruột tờ:**
- [ ] Đã tìm file cũ cùng chủ đề chưa? Có thì **sửa**, không đẻ tờ mới.
- [ ] `type` đúng chưa? `project`/`feedback` → có `Why` và `How to apply` chưa?
- [ ] Mọi con số / trạng thái biết đổi đã kèm ngày tuyệt đối chưa?
- [ ] File này có lật số liệu của file nào không? Có → **gộp theo Đ1**; chưa gộp được thì **R3 đủ ba chỗ**.
- [ ] Link `[[...]]` đã ghi lý do đi kèm chưa?
- [ ] Có đang chép lại thứ `CLAUDE.md` hoặc git đã ghi không? Có → bỏ.

---

## Khi hai file cùng một chủ đề

**Mặc định là GỘP, không phải sống chung.** Giữ cả hai chỉ là phương án tạm khi chưa đủ thông tin để gộp an toàn.

1. **Đừng vội xoá.** Mở cả hai, so `modified` trong frontmatter và nội dung.
2. **Chọn tờ chính** — tờ giàu thông tin hơn, **giữ nguyên đường dẫn của nó** (`consolidate-memory`: *"combine into one and keep the richer file's path"*). Giữ đường dẫn là để không gãy `[[link]]` theo **Đ3**.
3. **Gộp phần còn giá trị** của tờ kia vào tờ chính. Đọc kỹ trước khi bỏ chữ nào — mất thông tin ở bước này là mất thật.
4. **Xoá tờ kia.** Nếu nó vẫn còn phần riêng chưa biết đưa đi đâu → giữ tạm + gắn cảnh báo theo **R3**, và ghi vào việc còn nợ.
5. **Sửa mục lục**: xoá dòng của tờ đã bỏ, dồn từ đồng nghĩa của nó vào dòng tờ chính theo **Đ2**. Bước này hay bị quên, mà thiếu nó thì 4 bước trên vô ích.
6. **Chạy lại phép thử một cửa (Đ4)** để xác nhận đã hết mơ hồ.
7. **Báo lại cho anh Bình** đã gộp và xoá những tờ nào — đừng dọn im lặng.

---

## Đọc thêm khi cần

`docs/CHUAN-GHI-MEMORY.md` — giữ **nguyên văn tiếng Anh** của từng quy định + bảng nguồn. Mở khi cần chứng minh một luật ở đây là thật.

⚠️ Phần khuôn file **không tra được trên Google**. Nó nằm trong bản hướng dẫn auto-memory mà Anthropic nạp riêng cho Claude mỗi phiên, không đăng công khai. Trang tài liệu công khai chỉ nói cơ chế nạp, không nói gì về ruột file — đừng đi tìm rồi kết luận "không có quy định nào".

**Cơ sở thiết kế Phần 1** (nếu cần tra lại): [Effective context engineering — Anthropic](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) · [Authority control — Wikipedia](https://en.wikipedia.org/wiki/Authority_control) · [Johnny.Decimal](https://johnnydecimal.com/documentation)
