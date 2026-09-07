---
name: ntv-ban-lam-viec-erp
description: Dựng "bàn làm việc" (dashboard cá nhân) cho một trưởng phòng / CEO / trưởng khối ngay trên ERP Frappe 16 của Nệm Thuần Việt (platform.nguoithuanviet.com) bằng Workspace + Custom HTML Block, không cần deploy code, không cần app mới. Dùng skill này mỗi khi người dùng muốn "làm bàn làm việc", "dashboard trên ERP", "màn tổng quan cho phòng X", "bàn của CEO / của anh Y", "thêm khối số / bảng / biểu đồ vào workspace", "chỉnh màu font bàn làm việc theo thương hiệu", "đưa OKR / KPI / doanh thu / chi phí ads lên bàn", hoặc bất kỳ yêu cầu hiển thị số nội bộ trên desk Frappe — kể cả khi họ chỉ nói ngắn như "làm cho anh cái bàn giống bàn của Hưng" hay "gắn thêm bảng %ads theo ngày". Bao gồm bản vẽ trước khi code, khảo sát nguồn số chỉ-đọc, dựng từng khối, thanh trái + ô Desktop, áp nhận diện thương hiệu, và các bẫy đã cắn trên Frappe 16.
---

# Bàn làm việc trên ERP (Frappe 16) — cách làm đã kiểm chứng

Skill này gói lại đúng cách **Bàn Marketing & Kinh Doanh** của anh Hưng được dựng ngày 03/09/2026 trên
`platform.nguoithuanviet.com/desk/marketing`: 3 khối số sống (Tổng quan · OKR · %Ads theo ngày), thanh trái riêng,
nhận diện Nệm Thuần Việt, hoàn toàn **không deploy code** — chỉ tạo bản ghi cấu hình trên ERP.
Mục tiêu: một trưởng phòng khác (CEO, TP Kho vận, TP Nhân sự…) ngồi với Claude là ra bàn của mình trong một buổi.

## Ý tưởng cốt lõi (đọc trước khi làm gì)

1. **Workspace là cái khung, Custom HTML Block là cái ruột.** Frappe 16 cho phép một khối HTML + CSS + JS chạy
   trong Workspace (shadow DOM, biến `root_element`). JS trong khối gọi REST của chính ERP (`/api/resource/...`,
   `/api/method/...`) bằng phiên đăng nhập của người xem → số hiện theo đúng quyền của người đó. Không có server
   mới, không có DB mới (đúng luật L6: đọc qua đường ống Frappe).
2. **Chỉ ĐỌC.** Khối chỉ GET. Việc ghi duy nhất là tạo/sửa bản ghi cấu hình (Custom HTML Block, Workspace,
   Workspace Sidebar, Desktop Icon) — đều đảo ngược được. Không đụng site config, không xóa gì.
3. **Làm từng phần.** Vẽ trước → chốt → dựng khối 1 → cho xem → khối 2… Mỗi lần thêm khối là một lần PUT
   nhỏ, người dùng thấy ngay, sửa ngay. Đừng dựng cả 8 khối rồi mới cho xem.
4. **Số phải khớp với màn có sẵn.** Nếu ERP đã có API/màn tính số đó (ví dụ app eShop có `bridge.staff/kpi/ebit`),
   dùng lại, đừng tự cộng. Khi buộc phải tự cộng trên trình duyệt (ví dụ theo ngày), đối chiếu tổng tháng với
   API gốc trước khi giao và ghi rõ "nguồn sự thật đôi" vào ghi chú.

## Quy trình 6 bước

### Bước 0 — Hỏi 3 câu rồi mới vẽ
- Người này **nhìn gì mỗi sáng**? (CEO nhìn tiền: doanh thu, nợ, tiền vào/ra. TP KD nhìn người và hiệu quả:
  doanh thu so kế hoạch theo phòng/team/người, %ads. TP Kho nhìn tồn, tuổi tồn, ca lỗi.)
- Số lấy ở **bảng nào trên ERP**, đã có API/màn nào tính rồi chưa? (Xem `references/nguon-so-erp.md`.)
- Ai được xem? Bàn **public** = mọi user đăng nhập thấy trang, nhưng số chỉ hiện với ai có quyền đọc DocType.

### Bước 1 — Bản vẽ (artifact HTML, chưa code gì)
Vẽ 1 trang tĩnh với số minh hoạ, cùng ngôn ngữ hình với các bàn đã có (thanh trái · thẻ số · bảng · biểu đồ
nhỏ · "Cần anh xem" · "Báo cáo"). Chú thích 3 màu chấm: 🟢 đã có nguồn · 🟤 phải tạo · 🔴 nguồn có nhưng
đang hỏng/thiếu. Kèm bảng "từng khối lấy số ở đâu" và "phải chốt trước khi dựng". Mẫu: `assets/ban-ve-mau.html`.
Chỉ đi tiếp khi người dùng chốt bố cục và các câu hỏi mở (ví dụ: lấy cây chi nhánh nào, đếm theo ngày nào).

### Bước 2 — Khảo sát nguồn số, chỉ đọc, ngay trên trình duyệt đã đăng nhập
Mở tab ERP đã đăng nhập, chạy các đoạn trong `scripts/khao-sat.js`:
- Liệt kê field của DocType (`frappe.desk.form.load.getdoctype`), số dòng, giá trị distinct (REST `group_by`).
- Thử hàm API có sẵn (`/api/method/<app>.api.<hàm>?...`) xem trả gì.
- Kiểm bẫy: ngày nào là ngày đếm, trạng thái nào tính doanh thu, bảng nào ngưng cập nhật (MAX(day)).
Ghi kết quả vào phần "Ghi chú nguồn" của bàn — người xem sau phải biết số từ đâu.

### Bước 3 — Dựng khối, từng khối một
- Bắt đầu từ `assets/templates/block-khung.{html,css,js}`: đã có helper GET/list/count/agg, chọn tháng,
  thẻ số, bảng, pill, thanh tiến độ, skeleton, token màu. JS render **theo khối có trong HTML** (`if ($('#id'))`),
  nên mở rộng = chỉ thêm `<section>` vào HTML rồi PUT lại.
- Tạo bản ghi **Custom HTML Block** (html/style/script, `private=0`) và gắn vào Workspace bằng
  `scripts/dan-block.js` (chạy trong console tab desk — cần `frappe.csrf_token`). Đặt tên khối có tiền tố phòng
  (`KDMKT Tổng quan`, `CEO Tiền`, …) để khỏi trùng.
- Kiểm tra bằng cách **tải lại trang thật**, đọc số trong shadow root, chụp màn hình; đối chiếu 1–2 số với
  màn gốc. Xong khối này mới sang khối kế.
- Muốn thử trước khi lưu: chèn tạm khối vào trang bằng đoạn "thử không lưu" trong `scripts/dan-block.js`.

### Bước 4 — Thanh trái, tên, link, ô Desktop
Frappe 16 tách 4 thứ, làm đủ 4 mới "thấy" được bàn (chi tiết + bẫy ở `references/frappe16-workspace.md`):
Workspace (nội dung) · Workspace Sidebar (thanh trái + là thứ Desktop trỏ tới) · Desktop Icon (ô trên màn Desktop)
· mục trong "My Workspaces-<user>" của từng người. **Đặt một tên cho cả bốn** (name = title = tên sidebar = label
icon); URL = slug tên đó; tên hiển thị bị **dịch** ("Marketing" → "Tiếp thị"). Chốt tên trước khi tạo, đổi sau rất phiền.
- **Thanh trái = danh sách các khối trên bàn** (mục URL `/desk/<bàn>#<id>`), báo cáo chi tiết xếp xuống nhóm dưới.
  Dán `assets/templates/dieu-huong-thanh-trai.js` vào khối đầu: bấm mục là trượt chậm dần tới khối, cuộn tay tới đâu
  ô đó sáng. Không viền nháy, không hiệu ứng thừa.
- Chrome mất kết nối thì vẫn tạo/sửa được bản ghi qua MCP `fac-prod` (mục 9 trong reference), nhưng không chụp được
  màn hình → nhờ người dùng tải lại và mô tả.

### Bước 5 — Nhận diện thương hiệu (chỉ áp trên trang này)
Token màu + font theo brand ở `references/nhan-dien.md`. Font SVN-Gilroy có sẵn trên site
(`/assets/ntv_eshop/eshop-ui/fonts/`), khai `@font-face` **vào document.head** (khai trong shadow DOM không ăn).
Muốn đổi thanh trên / thanh trái / font cả trang mà không ảnh hưởng người khác: bọc mọi luật trong
`body:has([custom_block_name='<tên khối>'])` — chỉ hiệu lực khi khối đang hiện. ❌ Không dùng letter-spacing.

### Bước 6 — Giao và ghi nhớ
- Giao link trang + ảnh chụp + danh sách "còn treo" (nguồn hỏng, tên lệch, quyền).
- Lưu bản HTML/CSS/JS của từng khối vào thư mục dự án của người đó (`<Tên>/phan-N/`) — bản ghi trên ERP ai
  sửa nhầm là mất. Bước tiếp theo đúng quy trình nhà mới là đưa vào kho app dưới dạng fixture.
- Ghi memory: tên khối, workspace, sidebar, nguồn số, bẫy đã gặp.

## Những phanh hãm (từ CLAUDE.md của anh Hưng và những gì đã trả giá)

- Agent **soạn và tạo cấu hình**, nhưng deploy/xóa/đụng tiền là việc của người. Trước khi tạo bản ghi trên
  prod lần đầu, nói rõ sẽ tạo gì và xin một câu đồng ý. Nếu bộ kiểm duyệt quyền chặn thao tác ghi, **dừng và
  hỏi**, đừng lách; người dùng có thể tự làm trong 1 phút bằng nút Edit của Workspace.
- Không hardcode token/khóa; khối chỉ dùng phiên đăng nhập của người xem.
- Không viết số thật vào skill, memory hay artifact công khai; số chỉ nằm trên ERP.
- Không tự bịa team/phòng/cây tổ chức: lấy từ API hoặc bảng khai (org_chart, KPI Assignment, FB Ads Config).
- Tài nguyên site là của chung: một khối nên ≤ 15 request khi mở, cache theo tháng trong `state.cache`,
  tải phần nặng (biểu đồ 12 tháng) sau khi vẽ xong phần chính.

## Các kiểu khối hay gặp và cách làm (mỗi người mỗi khối, đây là công thức chung)

- **Dải thẻ số** (4–6 thẻ): `tile({l, v, s, cls, href, dot})`. Thẻ số hiện đủ số đồng; dòng phụ ghi nguồn/ngày
  cuối có số; `cls` ok/warn theo ngưỡng; chấm màu = sức khỏe nguồn (`dot(lastDay, expectDays)`).
- **Bảng theo đơn vị** (phòng / kho / team / người): `table(heads, rows, sumRow)` + `bar(pct, low)` + `pill()`.
  Luôn có dòng tổng và dòng "chưa gán" nếu có số rơi ra ngoài cây tổ chức.
- **Bảng theo ngày có tab**: 1 lệnh REST `group_by` nhiều cột (ví dụ `report_date,sale_staff,cashier`) rồi gộp trên
  trình duyệt; tab bằng `.kd-tabs/.kd-tab`; đồng bộ tháng giữa các khối qua `CustomEvent('kd-month')`.
- **Cây mục tiêu / OKR**: lấy DocType `NTV Muc Tieu`, dựng cây theo `parent_id`, % kỳ vọng theo thời gian,
  gấp cấp cá nhân, liệt kê "gốc khác không nối vào cây".
- **Biểu đồ nhỏ 12 tháng**: vẽ SVG tay (cột + vạch kế hoạch, đường + vạch ngưỡng), tải sau khi phần chính xong.
- **Chip "Cần anh xem"**: mỗi chip = 1 câu đếm (`count()` hoặc lọc từ số đã tải) + link tới chỗ xử lý, tooltip là danh sách.
- **Ghi chú & Việc** (khối cuối bàn, theo mẫu bàn CEO): ghi chú = Comment, việc = ToDo của ERP gắn vào Workspace; có giao
  người, hạn, tick xong. Mã sẵn `assets/templates/ghi-chu-viec.{html,css,js}`, chỉ đổi tên Workspace. Đây là khối duy nhất
  có ghi, và chỉ ghi thứ người dùng gõ.
Với tháng đang chạy, so KPI theo **tiến độ ngày đã qua**, không so KPI cả tháng (đầu tháng ai cũng "chưa đạt").
Bảng số: chia cột theo độ dài nội dung, tiêu đề cột bằng chữ bảng, thanh tiến độ thẳng hàng, số đủ đồng (xem
`references/nhan-dien.md` mục "Quy tắc bảng số").

### Bước 7 — Tài liệu giải thích cho đồng nghiệp
Khi bàn xong, viết **một trang Artifact ngắn** (vừa một màn hình): cấu trúc · số lấy từ đâu (sơ đồ 3 ô Nguồn → Đường đọc →
Hiển thị + bảng 5 dòng) · cách tính · hiển thị bằng gì. Không đưa số thật vào trang để chia sẻ rộng được. Người dùng chỉ
muốn ý chính; bản dài lần đầu của bàn KD&MKT bị yêu cầu rút gọn.

## Khi nào đọc file nào

- Cần cấu trúc Workspace / Sidebar / Desktop Icon, cách PUT, các bẫy tên–URL–cache → `references/frappe16-workspace.md`
- Cần biết số nằm ở bảng nào, API nào có sẵn, định nghĩa doanh thu/%ads, bẫy dữ liệu → `references/nguon-so-erp.md`
- Cần mã màu, font, CSS áp thương hiệu (Thuần Việt / Việt Nhật) → `references/nhan-dien.md`
- Vẽ bản vẽ → xem `assets/ban-ve-mau.html` (bản vẽ thật của bàn KD&MKT, có chú thích 🟢🟤🔴 và bảng nguồn số)
- Thanh trái trượt tới khối + ô sáng theo cuộn → `assets/templates/dieu-huong-thanh-trai.js`
- Khối Ghi chú & Việc → `assets/templates/ghi-chu-viec.{html,css,js}`
- Bắt tay code → `assets/templates/block-khung.{html,css,js}` rồi `scripts/`:
  `tao-ban.js` (Workspace + Sidebar + Desktop Icon cùng tên) · `khao-sat.js` (đọc field, đếm, group_by, thử API) ·
  `dan-block.js` (tạo/sửa khối + gắn vào workspace, có chế độ chỉ thử) · `xuat-block.js` (xuất khối về file để lưu)
