# Áp nhận diện thương hiệu cho bàn làm việc

Theme chung của site (anh Bình) đã là màu Thuần Việt (thanh trên #B3134B, font Quicksand). Bàn của phòng nào muốn
theo brand nào thì áp **trong khối** (token CSS) và **trên trang chỉ khi khối hiện** (`body:has(...)`), không sửa theme site.

## Token màu (đặt trên `.kd{}` của khối)

| Token | Nệm Thuần Việt | Nệm Việt Nhật | Ý nghĩa |
|---|---|---|---|
| `--kd-accent` | `#EB2364` | `#28A54A` | màu nhấn: mục đang chọn, thanh tiến độ, tháng đang xem |
| `--kd-deep` | `#B51247` | `#277714` | cảnh báo vượt ngưỡng, tiêu đề cột |
| `--kd-dark` | `#590F22` | `#1B4D22` | tiêu đề khối, gradient đầu |
| `--kd-accent-soft` | `#FCE4EC` | `#E6F4EA` | nền hover |
| `--kd-warn-bg / --kd-warn-ink` | `#FCE7EE / #B51247` | `#FCE7EE / #B51247` | cảnh báo (giữ đỏ hồng để tách với xanh) |
| `--kd-ok-bg / --kd-ok-ink` | `#E3F2E8 / #1F6D3D` | `#E3F2E8 / #1F6D3D` | tốt |
| `--kd-amber-bg / --kd-amber-ink` | `#F7EBC9 / #6F5300` | như bên | gần đạt |
| `--kd-ink / --kd-ink2 / --kd-ink3` | `#231F20 / #6F6669 / #9C9498` | `#231F20 / #5F6B62 / #8E9A91` | chữ 3 mức |
| `--kd-tile / --kd-tile2 / --kd-line` | `#F8F8F8 / #EFEFEF / #E6E6E6` | như bên | nền thẻ = xám thanh trái Frappe (anh Hưng chốt), viền |
| `--kd-bar` | `#E3E3E3` | như bên | nền thanh tiến độ |

Quy tắc 60-30-10: nền trắng/xám nhiều, màu nhấn ít. Màu ngữ nghĩa (xanh tốt / đỏ hồng cảnh báo) tách khỏi màu
thương hiệu — với Thuần Việt màu nhấn đã là hồng nên cảnh báo dùng hồng đậm `#B51247`, không dùng đỏ tươi.
❌ Không letter-spacing. ❌ Không xoay/đổi màu logo.

## Font
- SVN-Gilroy (Bold tiêu đề · Medium tiêu đề phụ · Regular body) có sẵn trên site tại
  `/assets/ntv_eshop/eshop-ui/fonts/SVN-GILROY_{REGULAR,MEDIUM,SEMIBOLD_1,BOLD}.{OTF,TTF}`.
- Khai `@font-face` vào `document.head` (1 lần, kiểm id), rồi `.kd{font-family:'SVN-Gilroy',-apple-system,sans-serif}`.
- Dự phòng: Be Vietnam Pro (Google Fonts) nếu site không còn file font.

## CSS cấp trang chỉ khi khối hiện (mẫu Thuần Việt, thay `<KHỐI>` bằng tên Custom HTML Block)

```css
@font-face{font-family:SVN-Gilroy;src:url(/assets/ntv_eshop/eshop-ui/fonts/SVN-GILROY_REGULAR.OTF);font-weight:400;font-display:swap}
@font-face{font-family:SVN-Gilroy;src:url(/assets/ntv_eshop/eshop-ui/fonts/SVN-GILROY_MEDIUM.OTF);font-weight:500;font-display:swap}
@font-face{font-family:SVN-Gilroy;src:url(/assets/ntv_eshop/eshop-ui/fonts/SVN-GILROY_SEMIBOLD_1.TTF);font-weight:600;font-display:swap}
@font-face{font-family:SVN-Gilroy;src:url(/assets/ntv_eshop/eshop-ui/fonts/SVN-GILROY_BOLD.OTF);font-weight:700;font-display:swap}
/* nới trang */
[data-page-route='Workspaces'] .layout-main:has([custom_block_name='<KHỐI>']){max-width:100% !important}
[data-page-route='Workspaces'] .layout-main:has([custom_block_name='<KHỐI>']) .layout-main-section{max-width:1400px;margin:0 auto}
/* thanh trên gradient bìa */
html body:has([custom_block_name='<KHỐI>']) .page-container .page-head .page-head-content,
html body:has([custom_block_name='<KHỐI>']) .page-container .page-head{background:linear-gradient(90deg,#590F22 0%,#B51247 55%,#EB2364 100%) !important}
/* khung góc trái + mục đang chọn */
body:has([custom_block_name='<KHỐI>']) .sidebar-header{background:linear-gradient(135deg,#590F22,#B51247) !important}
body:has([custom_block_name='<KHỐI>']) .standard-sidebar-item.active-sidebar{background:#EB2364 !important}
body:has([custom_block_name='<KHỐI>']) .standard-sidebar-item.active-sidebar .sidebar-item-label,
body:has([custom_block_name='<KHỐI>']) .standard-sidebar-item.active-sidebar svg{color:#fff !important;stroke:#fff !important}
/* font cả trang (đè Quicksand của theme) */
body:has([custom_block_name='<KHỐI>']) .body-sidebar,body:has([custom_block_name='<KHỐI>']) .layout-main,
body:has([custom_block_name='<KHỐI>']) .page-head,body:has([custom_block_name='<KHỐI>']) .sidebar-header{font-family:SVN-Gilroy,-apple-system,Roboto,sans-serif !important}
body:has([custom_block_name='<KHỐI>']) .body-sidebar *:not(svg):not(path),body:has([custom_block_name='<KHỐI>']) .layout-main *:not(svg):not(path),
body:has([custom_block_name='<KHỐI>']) .page-head *:not(svg):not(path),body:has([custom_block_name='<KHỐI>']) .sidebar-header *:not(svg):not(path){font-family:inherit !important}
/* tiêu đề khối header của workspace */
body:has([custom_block_name='<KHỐI>']) .codex-editor .h4,body:has([custom_block_name='<KHỐI>']) .ce-header{color:#590F22 !important;font-weight:700 !important}
```
Việt Nhật: thay 3 mã gradient bằng `#1B4D22 → #277714 → #28A54A`, mục đang chọn `#28A54A`.

## Chữ số
- Thẻ số lớn: hiện **đủ số đồng** có dấu chấm (`Number.toLocaleString('vi-VN')`), không viết tắt — anh Hưng chốt.
- Bảng: được dùng dạng gọn `tr` / `tỷ` (2 số lẻ) cho dễ đọc; cột số canh phải, `font-variant-numeric: tabular-nums`.
- Tiêu đề khối 15px đậm, tiêu đề chính 20px đậm, chữ thường 13px, ghi chú 11px.

## Quy tắc bảng số (anh Hưng chốt 04–05/09/2026)
- `table-layout: fixed` + `<colgroup>` chia cột theo độ dài nội dung, ví dụ bảng theo phòng: Phòng 18% · 3 cột số giữa 16–17% ·
  Chi ads 14% · %Ads 9% · Hóa đơn 9%. Đừng chia đều máy móc: cột số dài bị dồn, cột ngắn dư.
- Chữ tiêu đề cột **bằng** chữ trong bảng (12,5px), đậm, màu `--kd-deep`. Tiêu đề khối 15px đậm, tiêu đề chính 20px đậm.
- Thanh tiến độ + số %: bọc số % trong `<span class="pv">` có `min-width:48px; text-align:right` để các thanh thẳng hàng.
- Số trong bảng tổng quan cũng hiện **đủ đồng** như thẻ; chỉ dòng phụ nhỏ mới dùng "tr/tỷ".
- Ẩn dòng không có số (B2B chưa có kế hoạch/ads); dòng tổng vẫn cộng đủ và ghi rõ điều đó.
- Không nháy viền, không hiệu ứng thừa khi trượt tới khối — chỉ trượt.
