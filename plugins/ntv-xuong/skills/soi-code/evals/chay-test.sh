#!/usr/bin/env bash
# chay-test.sh — bộ test hồi quy cho máy quét /soi-code
#
# VÌ SAO CẦN: một cổng báo "sạch" có HAI nghĩa — code thật sự sạch, HOẶC regex sai
# nên không bao giờ khớp. Bộ này phân biệt hai cái đó. Đã cắn thật: cổng cur_frm
# từng để nhầm phạm vi `py` nên vĩnh viễn không kêu, chỉ phát hiện tình cờ lúc đọc lại.
#
# CÁCH LÀM: dựng hai repo git tạm.
#   Lượt A — nhét file CÓ LỖI cài sẵn, mỗi cổng một lỗi → cổng phải KÊU.
#   Lượt B — nhét file VIẾT ĐÚNG → những cổng dễ kêu bừa phải IM.
# Lượt B quan trọng ngang lượt A: cổng kêu nhầm bị người ta tắt còn nhanh hơn cổng bỏ sót.
#
# Cả hai lượt đều để file ở dạng CHƯA COMMIT — nên đồng thời kiểm luôn việc máy quét
# có soi đủ ba tầng không (lỗi cũ: chỉ nhìn commit đã có → báo sạch giả).
#
# Chạy:  bash .claude/skills/soi-code/evals/chay-test.sh
# Thoát 0 = đạt hết. Thoát 1 = có ca trượt.

set -uo pipefail

GOC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUET="$GOC/../scripts/quet.sh"

if [ ! -f "$QUET" ]; then
  echo "LỖI: không tìm thấy máy quét ở $QUET"
  exit 1
fi

DAT=0
TRUOT=0
DANH_SACH_TRUOT=""

# ───────────────────────── hàm chấm ─────────────────────────

# Cắt đúng khối kết quả của một cổng: từ dòng "──── <mã> ·" tới dòng "────" kế tiếp.
khoi_cong() {
  local ma="$1" file="$2"
  awk -v m="──── $ma ·" '
    index($0, m) == 1 { in_block = 1; print; next }
    in_block && /^──── / { exit }
    in_block && /^[A-Z]\. / { exit }
    in_block { print }
  ' "$file"
}

# phai_keu <mã cổng> <mô tả bằng lời thường>
phai_keu() {
  local ma="$1" mo_ta="$2" khoi
  khoi=$(khoi_cong "$ma" "$KQ")
  if [ -z "$khoi" ]; then
    TRUOT=$((TRUOT+1)); DANH_SACH_TRUOT="$DANH_SACH_TRUOT
  ❌ $ma — KHÔNG TÌM THẤY cổng trong kết quả (đổi tên cổng? xóa nhầm?)"
    printf '  ❌ %-6s %s\n' "$ma" "cổng không tồn tại trong kết quả"
    return
  fi
  if printf '%s' "$khoi" | grep -q '⚑\|🔴'; then
    DAT=$((DAT+1)); printf '  ✅ %-6s %s\n' "$ma" "$mo_ta"
  else
    TRUOT=$((TRUOT+1)); DANH_SACH_TRUOT="$DANH_SACH_TRUOT
  ❌ $ma — lỗi đã cài sẵn mà cổng vẫn báo sạch: $mo_ta"
    printf '  ❌ %-6s %s  ← CÓ LỖI MÀ CỔNG IM\n' "$ma" "$mo_ta"
  fi
}

# phai_im <mã cổng> <mô tả bằng lời thường>
phai_im() {
  local ma="$1" mo_ta="$2" khoi
  khoi=$(khoi_cong "$ma" "$KQ")
  if [ -z "$khoi" ]; then
    TRUOT=$((TRUOT+1)); DANH_SACH_TRUOT="$DANH_SACH_TRUOT
  ❌ $ma — KHÔNG TÌM THẤY cổng trong kết quả"
    printf '  ❌ %-6s %s\n' "$ma" "cổng không tồn tại trong kết quả"
    return
  fi
  if printf '%s' "$khoi" | grep -q '⚑\|🔴'; then
    TRUOT=$((TRUOT+1)); DANH_SACH_TRUOT="$DANH_SACH_TRUOT
  ❌ $ma — code viết ĐÚNG mà cổng vẫn kêu: $mo_ta"
    printf '  ❌ %-6s %s  ← KÊU NHẦM\n' "$ma" "$mo_ta"
  else
    DAT=$((DAT+1)); printf '  ✅ %-6s %s\n' "$ma" "$mo_ta"
  fi
}

# dung_repo <thư mục file mẫu> — dựng repo git tạm, trả đường dẫn qua biến REPO
dung_repo() {
  local mau="$1"
  REPO=$(mktemp -d)
  (
    cd "$REPO" || exit 1
    git init -q -b main
    git config user.email "test@ntv.local"
    git config user.name "Bo test soi-code"
    git remote add origin https://github.com/nem-thuan-viet/thu-nghiem.git
    # nền: một commit trống để có nhánh main so sánh
    printf '# repo giả cho bộ test\n' > README.md
    git add -A && git commit -qm "nền"
    git checkout -qb test/soi-code
    cp -R "$mau"/. .
    # File bắt đầu bằng dấu chấm không lưu thẳng trong repo được: `.gitignore` của
    # repo thật chặn `.env`, nên fixture đó sẽ MẤT khi người khác clone về và ca C1b
    # trượt oan. Cách vòng: cất dưới tên `DOT_<tên>`, đặt lại tên khi dựng repo tạm.
    find . -name 'DOT_*' -type f 2>/dev/null | while IFS= read -r d; do
      mv "$d" "$(dirname "$d")/.$(basename "$d" | sed 's/^DOT_//')"
    done
  )
}

# ═══════════════════ LƯỢT A — file CÓ LỖI, cổng phải KÊU ═══════════════════

echo "════════════════════════════════════════════════════════════"
echo " BỘ TEST MÁY QUÉT /soi-code"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "LƯỢT A — nhét lỗi cài sẵn, cổng PHẢI KÊU"
echo ""

dung_repo "$GOC/mau"
REPO_A="$REPO"

# C22 cần một cột BỊ XÓA khỏi bảng ĐÃ commit — dựng riêng ở đây:
#   commit bảng có 2 cột trước, rồi xóa 1 cột đi.
(
  cd "$REPO_A" || exit 1
  git add -A >/dev/null 2>&1
  git commit -qm "bản đầu của bảng" >/dev/null 2>&1
  # xóa dòng định nghĩa cột "ma_cu"
  grep -v '"ma_cu"' app_gia/doctype/thu/thu.json > /tmp/thu.$$ && mv /tmp/thu.$$ app_gia/doctype/thu/thu.json
)

KQ=$(mktemp)
( cd "$REPO_A" && bash "$QUET" ) > "$KQ" 2>&1

phai_keu C1    "nhét mã khóa thẳng vào code"
phai_keu C1b   "thêm file .env vào kho"
phai_keu C2    "file rác iCloud tên kết thúc ' 3'"
phai_keu C3    "app riêng đẻ bản Item"
phai_keu C3b   "đọc thẳng DocType Employee, né cửa ntv.api.master_data"
phai_keu C4    "pyproject thiếu khai phiên bản Frappe"
phai_keu C5    "cửa API mở cho khách vãng lai"
phai_keu C5b   "trả ra lương / giá vốn"
phai_keu C6    "xóa hàng loạt trong vòng lặp"
phai_keu C7    "bật quảng cáo, đụng tiền thật"
phai_keu C9a   "ghi tay vào sổ cái GL Entry"
phai_keu C9b   "ghi thẳng xuống bảng, né kiểm"
phai_keu C9c   "đụng trạng thái chứng từ"
phai_keu C9d   "lấy công ty mặc định"
phai_keu C10a  "bỏ qua kiểm quyền"
phai_keu C10b  "chốt giao dịch giữa chừng"
phai_keu C10c  "ghép câu lệnh CSDL bằng dán chuỗi"
phai_keu C10d  "sửa tay custom field"
phai_keu C10e  "cắt ngày thiếu múi giờ Việt Nam"
phai_keu C11   "Server Script nạp thư viện + dùng self"
phai_keu C12   "trình duyệt gọi hàm của máy chủ"
phai_keu C13   "gán thẳng frappe.call vào biến"
phai_keu C14   "dùng cur_frm thay vì frm"
phai_keu C15   "cách viết v16 đã bỏ"
phai_keu C16   "lỗi chết câm — nuốt lỗi rồi đi tiếp"
phai_keu C17   "tên sự kiện bám sai"
phai_keu C18   "ghi đè, có thể quên giữ phần gốc"
phai_keu C19   "viết cứng tên hệ thống"
phai_keu C20   "tên kỹ thuật viết tiếng Việt"
phai_keu C21   "bản vá chưa khai vào patches.txt"
phai_keu C22   "xóa cột khỏi bảng đã commit"
phai_keu C23   "đóng gói thiếu cờ chip amd64"
phai_keu C24   "docker cp — sửa trong máy ảo"
phai_keu C25   "ô chọn-được để gõ tay"

KQ_A="$KQ"

# ═══════════════════ LƯỢT B — file ĐÚNG, cổng phải IM ═══════════════════

echo ""
echo "LƯỢT B — code viết ĐÚNG, cổng PHẢI IM (bắt cổng kêu bừa / sai phạm vi)"
echo ""

dung_repo "$GOC/mau-sach"
REPO_B="$REPO"
KQ=$(mktemp)
( cd "$REPO_B" && bash "$QUET" ) > "$KQ" 2>&1

phai_im C11   "Server Script không import, dùng doc"
phai_im C12   "frappe.db.get_value nằm trong .py là ĐÚNG"
phai_im C3b   "đọc Customer qua cửa ntv.api.master_data, không đọc thẳng"
phai_im C13   "có await trước frappe.call"
phai_im C14   "dùng frm, không dùng cur_frm"
phai_im C16   "bắt lỗi rồi ghi log + ném ra ngoài"
phai_im C20   "tên kỹ thuật tiếng Anh, nhãn tiếng Việt"
phai_im C21   "bản vá đã khai trong patches.txt"
phai_im C23   "đóng gói có --platform=linux/amd64"
phai_im C25   "chọn-được dùng Link/Select"

KQ_B="$KQ"

# ═══════════════════ CHỐT ═══════════════════

echo ""
echo "════════════════════════════════════════════════════════════"
TONG=$((DAT + TRUOT))
if [ "$TRUOT" -eq 0 ]; then
  echo " ✅ ĐẠT $DAT/$TONG ca"
  echo "════════════════════════════════════════════════════════════"
  rm -rf "$REPO_A" "$REPO_B" "$KQ_A" "$KQ_B"
  exit 0
else
  echo " ❌ TRƯỢT $TRUOT/$TONG ca"
  echo "$DANH_SACH_TRUOT"
  echo ""
  echo " Kết quả đầy đủ để soi:"
  echo "   lượt A (có lỗi): $KQ_A"
  echo "   lượt B (sạch)  : $KQ_B"
  echo "   repo giả A     : $REPO_A"
  echo "   repo giả B     : $REPO_B"
  echo "════════════════════════════════════════════════════════════"
  exit 1
fi
