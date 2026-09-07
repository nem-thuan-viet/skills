# Nguồn số trên ERP Nệm Thuần Việt — biết tìm ở đâu trước khi vẽ

Kiểm 03/09/2026 trên prod. Đọc rồi **kiểm lại bằng `scripts/khao-sat.js`** — bảng đổi, job ngưng, tên đổi là chuyện thường.

## Nguyên tắc chọn nguồn
1. Đã có API/màn của app nào tính rồi → gọi lại (số khớp với màn người ta đang xem).
2. Chưa có → REST `group_by` thẳng bảng, gộp trên trình duyệt; đối chiếu tổng với API gốc trước khi giao.
3. Master data (nhân sự, phòng, cost center, mã hàng) chỉ lấy từ nhà cao qua API nền `ntv.api.master_data.*`
   hoặc bảng gốc — không tự khai bản riêng (luật L5).
4. Ghi định nghĩa số ngay dưới khối (footer): công thức, trạng thái lọc, ngày đếm, nguồn từng cột.

## Bán hàng · Marketing (đã dùng cho bàn KD&MKT)

| Cần | Nguồn | Ghi chú |
|---|---|---|
| Doanh thu thuần, theo phòng/team/người/kênh | DocType `eShop Invoice` (app ntv_eshop, sync MISA, ~46k dòng) | DT thuần = `(total_item_amount − discount_amount)/1.08`, chỉ `payment_status in (2,3,8)`, đếm theo `report_date` (≠ `create_date`, có thể lệch tuần). Kênh: `sale_channel`. Người: `sale_staff` (fallback `cashier`) dạng `MÃ TEAM - Tên`; quy team→phòng theo luật trong `ntv_eshop/misa/org_chart.py` |
| Số đã tính sẵn: theo phòng/team/người, KPI, kế hoạch, EBIT | `GET /api/method/ntv_eshop.api.bridge.staff?from&to` (byDept, byTeam, byStaff có `chiNhanhErp`, doiChieu) · `…bridge.kpi?phong=all&team=all&from&to` (rows: ten, team, kpiThang, thucTe, pct, loaiDong canhan/quanly) · `…bridge.ebit?scope=all|dept:<phòng>|team:<mã>` (thang[]: dtKH, dtTT, chiPhi; scopes) · `…bridge.summary?from&to` (theo ngày, 2 shop) · `…bridge.channels`, `…customers`, `…analytics` | Tham số tên như Node cũ. Kế hoạch tháng nằm trong code `misa/plan_2026.py` — không có DocType |
| Ads Facebook | `FB Insight Daily` (day, account_id, account_name, spend…) | Map tài khoản→team trong Single `FB Ads Config.page_map_json.accounts[id].teams[0]`; team "số 1/2/4" → Việt Nhật, còn lại Thuần Việt; không map → "Chưa gán phòng". Có số từ 01/07/2026 |
| Ads Google | `Google Ads Cache` (payload JSON theo khoảng ngày, nạp ~3h sáng) | Lấy bản `cache_key like 'YYYY-MM-01::%'` mới nhất; `payload.by.all.gads.per_account[{id,name,cost}]`, `payload.by.<id>.gads.daily[{date,cost}]`; map cứng 5379729446→TV, 4957214544/9817726949→VN. Luôn thiếu ngày hôm nay |
| Ads TikTok phòng KD | `NTV Ads TikTok Daily` (day, phong, team, advertiser_name, spend) | phong "KD Nệm Việt Nhật"/"KD Nệm Thuần Việt"/"Ecom"; từng ngưng 26/08–03/09 |
| Ads TikTok sàn (Ecom) | `TikTok Ads Daily` (shop_id, day, cost, gross_revenue) | trùng phần Ecom của bảng trên → chỉ lấy Ecom ở đây |
| Ads Shopee | `Shopee Ads Daily` (shop_id, day, cost) | có từ 13/08/2026 |
| Chi nhánh của nhân sự | `Employee.branch` (qua bridge.staff `chiNhanhErp` hoặc API nền `get_employees`) | 99/347 người chưa có branch; sale online đều "Office Quận 12" → chiều chi nhánh chỉ có nghĩa với cửa hàng |
| Chờ duyệt của tôi | `Workflow Action` filters status=Open, user=frappe.session.user | |

## OKR / mục tiêu
- DocType `NTV Muc Tieu` (đồng bộ Base Goal): `cycle_name` ("Quý 03 - 2026"), `scope` company|dept|team|personal,
  `parent_id`, `muc_tieu`, `employee_name`, `pct`, `current_value/target_value`, `start_date/end_date`; `krs` rỗng.
- Page có sẵn: `/desk/okr-chu-ky`. Chọn chu kỳ: nhóm theo cycle_name, lấy chu kỳ có `MIN(start_date) ≤ hôm nay ≤ MAX(end_date)`.
- Trạng thái tự tính: kỳ vọng = ngày đã qua / tổng ngày; pct/kỳ vọng ≥ 0,9 đúng tiến độ · ≥ 0,6 chậm · < 0,6 rủi ro.
- Cây có thể đứt: nhiều mục tiêu phòng khác không nối `parent_id` vào mục tiêu của trưởng khối → hiện mục "gốc khác".

## Các mảng khác (chưa dựng, gợi ý điểm bắt đầu)
- **Tiền / kế toán (CEO):** sổ cái ERP còn ít bút toán, kế toán vẫn ở MISA — số tiền thật chưa có trên ERP; hỏi
  anh Bình nguồn (MISA/AMIS về ERP theo chặng). Bàn CEO hiện dùng Query Report chuẩn ERPNext (P&L, Cash Flow) — 0 dòng.
- **Kho vận:** ERP nhà máy chạy thật (Stock Ledger Entry ~9.400 bút toán) → `Bin`, `Stock Ledger Entry`, `Delivery Note`.
- **Sản xuất:** `Work Order`, `Stock Entry`, DocType riêng app `NTV · Sản xuất`.
- **Nhân sự:** app `Nhân sự NTV` (NTV Cham Cong, NTV Nghi Phep, NTV Tang Ca), `Employee`.
- **Đơn hàng ERP (tương lai):** `Sales Order` (chặng 1 "ERP chỉ quản đơn"), hiện đơn thật = 0.

## Bẫy đã cắn
- Tên người lệch dấu giữa MISA và ERP ("Thùy" vs "Thuỳ") → join theo tên trống cột.
- `report_date` ≠ ngày tạo hóa đơn; số đầu/cuối tháng lệch sổ.
- Kế hoạch năm trong app eShop (168,28 tỷ) khác số ghi chép cũ (216,69 tỷ) — luôn hỏi lại nguồn kế hoạch.
- Bảng ads có thể ngưng cập nhật im lặng → luôn hiện `MAX(day)` và chấm màu sức khỏe nguồn.
- Cộng 2 bảng TikTok = tính trùng phần Ecom.
- REST `group_by` giới hạn `limit_page_length` mặc định 20 → luôn đặt 500–5000.
