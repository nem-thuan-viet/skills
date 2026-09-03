#!/usr/bin/env bash
# quet.sh — máy quét cho /soi-code (Thuần Việt Platform)
#
# NHIỆM VỤ: quét cơ học rồi in DẤU HIỆU ra màn hình. KHÔNG phán verdict.
# Người/agent đọc kết quả, xem ngữ cảnh, rồi mới phán 🟢/🟡/🔴.
#
# NGUYÊN TẮC: chỉ soi DÒNG THÊM MỚI. Dòng bị xóa không tính —
# gỡ một cái token cũ ra là việc TỐT, không phải lỗi.
# (Ngoại lệ DUY NHẤT: cổng C22 soi dòng BỊ XÓA, vì xóa cột là cái nguy.)
#
# PHẠM VI: soi CẢ BA tầng — commit đã có · sửa chưa commit · file mới chưa add.
# Bỏ hai tầng sau là báo "sạch" giả: người ta gõ /soi-code TRƯỚC khi commit
# là chuyện thường nhất.
#
# Chạy:  bash .claude/skills/soi-code/scripts/quet.sh
#        bash .claude/skills/soi-code/scripts/quet.sh <nhánh-gốc>
#
# Luôn thoát 0. Không có match không phải là lỗi.

set -uo pipefail

# ───────────────────────────── chuẩn bị ─────────────────────────────

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "LỖI: không phải thư mục git. Chạy lệnh này trong repo."
  exit 0
fi

BASE="${1:-}"
if [ -z "$BASE" ]; then
  for c in main origin/main master origin/master; do
    if git rev-parse --verify -q "$c" >/dev/null 2>&1; then BASE="$c"; break; fi
  done
fi

if [ -z "$BASE" ]; then
  echo "LỖI: không tìm thấy nhánh gốc (main/master). Truyền tay: quet.sh <nhánh-gốc>"
  exit 0
fi

NHANH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
RANGE="$BASE...HEAD"

# app_name khai trong hooks.py — dùng để loại app NỀN (ntv) khỏi cổng C3b,
# vì ntv được PHÉP đọc thẳng ERPNext (nó chồng lên ERPNext, không phải app kênh).
APP_NAME_HOOK=""
for hf in $(find . -maxdepth 3 -iname "hooks.py" 2>/dev/null); do
  v=$(grep -m1 -E '^app_name[[:space:]]*=' "$hf" 2>/dev/null | sed -E 's/^app_name[[:space:]]*=[[:space:]]*"([^"]*)".*/\1/')
  [ -n "$v" ] && APP_NAME_HOOK="$v" && break
done

# ───────────────────── thu thập: BA TẦNG ─────────────────────
# Bản nhân đôi iCloud có dấu cách trong tên ("Containerfile 3") — git in trần,
# không bọc nháy, nên mảng bash đọc đúng miễn là dùng "${arr[@]}".

FILES=()          # mọi file trong phạm vi soi
FILES_TON=()      # file còn tồn tại trên đĩa (để grep lấy số dòng)
FILES_CODE=()     # file mã nguồn
FILES_JS=()       # chỉ phía trình duyệt
FILES_PY=()       # chỉ phía máy chủ
FILES_JSON=()     # định nghĩa bảng / fixture
FILES_MOI=()      # file mới chưa add — nội dung TOÀN BỘ là dòng thêm

# Chính máy quét này định nghĩa các mẫu regex, nên nó LUÔN tự khớp mẫu của mình.
# Vẫn ghi tên vào FILES (để cổng tên file soi được) nhưng KHÔNG soi ruột.
TU_SOI='^\.claude/skills/soi-code/'

them_file() {
  local f="$1"
  [ -z "$f" ] && return 0
  # chống trùng khi một file vừa có commit vừa đang sửa dở
  local x
  for x in "${FILES[@]:-}"; do [ "$x" = "$f" ] && return 0; done
  FILES+=("$f")
  [ -f "$f" ] || return 0
  printf '%s' "$f" | grep -qE "$TU_SOI" && return 0
  FILES_TON+=("$f")
  case "$f" in
    *.py)   FILES_CODE+=("$f"); FILES_PY+=("$f") ;;
    *.js|*.ts|*.jsx|*.tsx|*.vue)
            FILES_CODE+=("$f"); FILES_JS+=("$f") ;;
    *.json) FILES_CODE+=("$f"); FILES_JSON+=("$f") ;;
    *.sql|*.html|*.sh|*.toml|*.yaml|*.yml)
            FILES_CODE+=("$f") ;;
  esac
}

SO_F1=0; SO_F2=0; SO_F3=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  SO_F1=$((SO_F1+1)); them_file "$f"
done < <(git diff --name-only "$RANGE" 2>/dev/null)

while IFS= read -r f; do
  [ -z "$f" ] && continue
  SO_F2=$((SO_F2+1)); them_file "$f"
done < <(git diff --name-only HEAD 2>/dev/null)

while IFS= read -r f; do
  [ -z "$f" ] && continue
  SO_F3=$((SO_F3+1)); them_file "$f"; FILES_MOI+=("$f")
done < <(git ls-files --others --exclude-standard 2>/dev/null)

# Nội dung file mới, mỗi dòng gắn '+' cho khớp định dạng diff.
# Bỏ qua file >512KB (ảnh, bản đóng gói) — chỉ soi tên chúng, không soi ruột.
noi_dung_moi() {
  local f sz
  for f in "${FILES_MOI[@]:-}"; do
    [ -f "$f" ] || continue
    printf '%s' "$f" | grep -qE "$TU_SOI" && continue
    case "$1" in
      code) case "$f" in *.py|*.js|*.ts|*.jsx|*.tsx|*.vue|*.json|*.sql|*.html|*.sh|*.toml|*.yaml|*.yml) ;; *) continue ;; esac ;;
      js)   case "$f" in *.js|*.ts|*.jsx|*.tsx|*.vue) ;; *) continue ;; esac ;;
      py)   case "$f" in *.py) ;; *) continue ;; esac ;;
      json) case "$f" in *.json) ;; *) continue ;; esac ;;
    esac
    sz=$(wc -c <"$f" 2>/dev/null | tr -d ' ')
    [ -n "$sz" ] && [ "$sz" -gt 524288 ] && continue
    sed 's/^/+/' "$f" 2>/dev/null || true
  done
}

# Dòng thêm mới của cả ba tầng, theo từng nhóm file.
BO_TU_SOI=':(exclude).claude/skills/soi-code/*'
gom() {
  local nhom="$1"; shift
  {
    if [ "$#" -eq 0 ]; then
      git diff "$RANGE" -- . "$BO_TU_SOI" 2>/dev/null
      git diff HEAD    -- . "$BO_TU_SOI" 2>/dev/null
    else
      git diff "$RANGE" -- "$@" "$BO_TU_SOI" 2>/dev/null
      git diff HEAD    -- "$@" "$BO_TU_SOI" 2>/dev/null
    fi
  } | grep -E '^\+' | grep -vE '^\+\+\+' || true
  noi_dung_moi "$nhom"
}

THEM=$(gom all)
THEM_CODE=$(gom code '*.py' '*.js' '*.ts' '*.jsx' '*.tsx' '*.vue' '*.json' '*.sql' '*.html' '*.sh' '*.toml' '*.yaml' '*.yml')
THEM_JS=$(gom js   '*.js' '*.ts' '*.jsx' '*.tsx' '*.vue')
THEM_PY=$(gom py   '*.py')
THEM_JSON=$(gom json '*.json')

# Dòng BỊ XÓA trong định nghĩa bảng — chỉ dùng cho C22.
XOA_JSON=$({ git diff "$RANGE" -- '*.json' 2>/dev/null; git diff HEAD -- '*.json' 2>/dev/null; } \
           | grep -E '^-' | grep -vE '^---' || true)

SO_FILE=${#FILES[@]}
SO_DONG=$(printf '%s\n' "$THEM" | grep -c . || true)

# ───────────────────────────── hàm quét ─────────────────────────────

# scan <mã cổng> <tên cổng> <regex> <ghi chú> [phạm vi: code|all|js|py|json]
# Mặc định "code" — chỉ soi file mã nguồn. Tài liệu .md nói về "lương", "giá vốn"
# không phải là code làm lộ lương. Chỉ cổng lộ-khóa và rác mới soi "all".
# js/py/json để tránh báo nhầm: frappe.db.get_value trong .py là ĐÚNG,
# trong .js là SAI — cùng một chuỗi, hai kết luận ngược nhau.
scan() {
  local ma="$1" ten="$2" pat="$3" ghichu="${4:-}" pham_vi="${5:-code}"
  local n loc nguon

  case "$pham_vi" in
    all)  nguon="$THEM" ;;
    js)   nguon="$THEM_JS" ;;
    py)   nguon="$THEM_PY" ;;
    json) nguon="$THEM_JSON" ;;
    *)    nguon="$THEM_CODE" ;;
  esac

  n=$(printf '%s\n' "$nguon" | grep -cEi -- "$pat" 2>/dev/null || true)
  n=${n:-0}

  echo ""
  echo "──── $ma · $ten"
  if [ "$n" -eq 0 ]; then
    echo "     sạch — không có dấu hiệu trong dòng thêm mới"
    return 0
  fi

  echo "     ⚑ $n dòng THÊM MỚI khớp mẫu — cần xem ngữ cảnh"
  [ -n "$ghichu" ] && echo "     cách đọc: $ghichu"

  # grep thường (không phải git grep) — vì file mới chưa add thì git grep không thấy
  case "$pham_vi" in
    all)  [ ${#FILES_TON[@]}  -gt 0 ] && loc=$(grep -nEi -- "$pat" "${FILES_TON[@]}"  2>/dev/null | head -25 || true) ;;
    js)   [ ${#FILES_JS[@]}   -gt 0 ] && loc=$(grep -nEi -- "$pat" "${FILES_JS[@]}"   2>/dev/null | head -25 || true) ;;
    py)   [ ${#FILES_PY[@]}   -gt 0 ] && loc=$(grep -nEi -- "$pat" "${FILES_PY[@]}"   2>/dev/null | head -25 || true) ;;
    json) [ ${#FILES_JSON[@]} -gt 0 ] && loc=$(grep -nEi -- "$pat" "${FILES_JSON[@]}" 2>/dev/null | head -25 || true) ;;
    *)    [ ${#FILES_CODE[@]} -gt 0 ] && loc=$(grep -nEi -- "$pat" "${FILES_CODE[@]}" 2>/dev/null | head -25 || true) ;;
  esac

  if [ -n "${loc:-}" ]; then
    echo "     vị trí trong bản hiện tại:"
    printf '%s\n' "$loc" | sed 's/^/       /'
  fi
  loc=""
  return 0
}

# ───────────────────────────── A. Bối cảnh ─────────────────────────────

echo "════════════════════════════════════════════════════════════"
echo " MÁY QUÉT /soi-code — Thuần Việt Platform"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "A. BỐI CẢNH"
echo "   nhánh hiện tại : $NHANH"
echo "   so với gốc     : $BASE"
echo "   kho (remote)   :"
git remote -v 2>/dev/null | sed 's/^/     /' || echo "     (không có remote)"

echo ""
echo "   PHẠM VI SOI — cả ba tầng ($SO_FILE file, $SO_DONG dòng thêm):"
echo "     1. commit đã có       : $SO_F1 file"
echo "     2. sửa chưa commit    : $SO_F2 file"
echo "     3. file mới chưa add  : $SO_F3 file"

echo ""
echo "   commit sẽ vào gốc:"
git log --oneline "$BASE..HEAD" 2>/dev/null | head -20 | sed 's/^/     /' || true

echo ""
echo "   file đổi (đã commit):"
git diff --stat "$RANGE" 2>/dev/null | tail -40 | sed 's/^/     /' || true

if [ "$SO_F3" -gt 0 ]; then
  echo ""
  echo "   file mới CHƯA ADD (soi luôn, vì sắp thành một phần của kho):"
  printf '%s\n' "${FILES_MOI[@]:-}" | head -40 | sed 's/^/     /'
fi

# Cảnh báo nền
echo ""
echo "B. CẢNH BÁO NỀN"

if [ "$NHANH" = "main" ] || [ "$NHANH" = "master" ]; then
  echo "   🔴 ĐANG ĐỨNG NGAY TRÊN NHÁNH GỐC ($NHANH) — phải tạo nhánh tên/việc rồi làm lại"
else
  echo "   ✓ đang ở nhánh riêng"
fi

if ! printf '%s' "$NHANH" | grep -qE '^[a-z0-9]+/[a-z0-9._-]+$'; then
  echo "   ⚠ tên nhánh \"$NHANH\" không theo mẫu tên/việc (vd duc/gui-su-kien-capi)"
fi

if ! git remote -v 2>/dev/null | grep -q 'nem-thuan-viet'; then
  echo "   🔴 remote KHÔNG thuộc org nem-thuan-viet — code này không có đường lên nhà mới"
fi

if git remote -v 2>/dev/null | grep -qE 'ntv-fb(\.git)?( |$)'; then
  echo "   ⚠ remote là kho CŨ 'ntv-fb' (gạch ngang). Kho đang dùng là 'ntv_fb' (gạch dưới)"
fi

if [ $((SO_F2 + SO_F3)) -gt 0 ]; then
  echo "   ⚠ có $SO_F2 file sửa dở + $SO_F3 file mới CHƯA COMMIT — đang soi luôn,"
  echo "     nhưng verdict chỉ có giá trị sau khi commit đúng những thứ này"
fi

if [ "$SO_DONG" -gt 2000 ]; then
  echo "   ⚠ khối rất lớn ($SO_DONG dòng thêm) — độ tin của lần soi này thấp hơn, nên tách nhỏ"
fi
if [ "$SO_DONG" -eq 0 ]; then
  echo "   ⚠ không có dòng thêm mới nào ở cả ba tầng — chưa sửa gì, hoặc so sai nhánh gốc"
fi

# File nặng
echo ""
echo "   file nặng (>1MB) trong lần đổi này:"
NANG=0
for f in "${FILES_TON[@]:-}"; do
  sz=$(wc -c <"$f" 2>/dev/null | tr -d ' ')
  if [ -n "$sz" ] && [ "$sz" -gt 1048576 ]; then
    echo "     ⚠ $f  ($((sz/1024)) KB)"
    NANG=1
  fi
done
[ "$NANG" -eq 0 ] && echo "     (không có)"

# ═════════════════════════ C. NHÓM NGUY HIỂM ═════════════════════════

echo ""
echo "C. NHÓM NGUY HIỂM — mất tiền · lộ dữ liệu · sai số · hỏng sổ · sập hệ"
echo "   (⚑ = có dấu hiệu, KHÔNG có nghĩa là chắc chắn sai)"

scan "C1" "Lộ khóa · mật khẩu · token" \
  '(api[_-]?key|secret|passwd|password|token|bearer|authorization|private[_-]?key|client[_-]?secret|access[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}' \
  "đọc từ biến môi trường / Kho Khóa Nền = ĐÚNG; chuỗi thật viết thẳng = 🔴 và phải XOAY KHÓA" \
  all

echo ""
echo "──── C1b · File nhạy cảm được thêm vào"
NHAY=$(printf '%s\n' "${FILES[@]:-}" | grep -Ei '(\.env|\.pem|\.p12|\.key|credentials|service[_-]?account|id_rsa)' || true)
if [ -n "$NHAY" ]; then
  echo "     ⚑ có file nhạy cảm trong lần đổi này:"
  printf '%s\n' "$NHAY" | sed 's/^/       /'
  echo "     cách đọc: .env.example chỉ được chứa placeholder rỗng. Có giá trị thật = 🔴 xoay khóa"
else
  echo "     sạch — không thêm file nhạy cảm"
fi

echo ""
echo "──── C2 · Rác build · rác iCloud"
# Lưu ý: bản nhân đôi iCloud có dạng "tên 3" — có thể là FILE hoặc THƯ MỤC giữa đường dẫn,
# nên phải khớp cả khi theo sau là dấu / chứ không chỉ ở cuối chuỗi.
RAC=$(printf '%s\n' "${FILES[@]:-}" | grep -Ei '(node_modules/|/dist/|\.pyc$|\.DS_Store|\.log$|[a-zA-Z0-9] [0-9]+(/|\.|$))' || true)
if [ -n "$RAC" ]; then
  echo "     ⚑ file rác lọt vào lần đổi này:"
  printf '%s\n' "$RAC" | sed 's/^/       /'
  echo "     cách đọc: tên kết thúc bằng ' 3' là bản nhân đôi iCloud — xóa; rác build thì thêm .gitignore"
else
  echo "     sạch — không có file rác"
fi

scan "C3" "Đụng master data dùng chung" \
  '(doctype/(item|employee|company|cost_center|team)|"doctype":[[:space:]]*"(Item|Employee|Company|Cost Center)")' \
  "app kênh CẤM đẻ bản riêng — phải gọi ntv.api.master_data"

if [ "$APP_NAME_HOOK" = "ntv" ]; then
  echo ""
  echo "──── C3b · Đọc thẳng DocType nền (bỏ qua cửa ntv.api.master_data)"
  echo "     (app_name = \"ntv\" — đây là app NỀN, được đọc thẳng ERPNext, không áp cổng này)"
else
  scan "C3b" "Đọc thẳng DocType nền (bỏ qua cửa ntv.api.master_data)" \
    'frappe\.(get_doc|get_all|get_list|get_cached_doc|new_doc|db\.get_value|db\.exists|db\.count)\([[:space:]]*["'"'"'](Item|Item Group|Brand|UOM|Employee|Company|Cost Center|Customer|Supplier|Warehouse|Territory|Mode of Payment)["'"'"']' \
    "app kênh phải gọi ntv.api.master_data.*, KHÔNG frappe.get_doc/get_all/db.get_value thẳng vào DocType nền — kể cả chỉ ĐỌC (HIEN-PHAP-KIEN-TRUC-APP.md §4)" \
    py
fi

scan "C5" "Cửa API mở ra ngoài" \
  '(@frappe\.whitelist|allow_guest)' \
  "mỗi hàm whitelist phải có gác quyền bên trong; allow_guest=True phải là cố ý"

scan "C5b" "Trả về dữ liệu nhạy cảm" \
  '(salary|payroll|ctc|bank_ac|valuation_rate|gross_profit|lương|giá vốn)' \
  "lộ ra API/màn hình không gác quyền = 🔴"

scan "C6" "Xóa hàng loạt · việc nặng" \
  '(delete_doc|TRUNCATE|DELETE[[:space:]]+FROM|bulk_update|\.save\(\)|scheduler_events|cron)' \
  "vòng lặp ghi/xóa nghìn bản ghi không chạy nền = 🔴 (đã nghẽn hệ thống 7 tiếng)"

scan "C7" "Đụng tiền thật" \
  '(campaign|budget|bid|payment|thanh[_ ]?toan|invoice.*submit|charge|refund)' \
  "code TỰ ĐỘNG bật ads / chi tiền không qua nấc duyệt = 🔴"

scan "C9a" "🔴 Ghi tay vào sổ cái / sổ kho" \
  '(GL Entry|Stock Ledger Entry|tabGL Entry|tabStock Ledger Entry|tabBin)' \
  "hai sổ này là hệ quả tự sinh — CHỈ ĐỌC. Có lệnh ghi = 🔴 chặn cứng"

scan "C9b" "Ghi thẳng xuống bảng (bỏ qua validate)" \
  '(db\.set_value|db_set|frappe\.db\.sql\([^)]*(UPDATE|INSERT|DELETE))' \
  "lên bản ghi docstatus=1 = 🔴 (phải Cancel→Amend). Field kỹ thuật thì được"

scan "C9c" "Chứng từ: trạng thái · lùi ngày · đánh số" \
  '(docstatus|posting_date|set_posting_time|naming_series|amended_from|\.cancel\(\)|\.submit\(\))' \
  "lùi ngày làm ERP tính lại giá vốn toàn bộ về sau — ghi rõ trong báo cáo"

scan "C9d" "Công ty · cost center" \
  '(get_user_default\(["'"'"']Company|frappe\.defaults.*[Cc]ompany|Cost Center)' \
  "lấy company mặc định = đánh bạc; báo cáo thiếu lọc company = trộn sổ 3 pháp nhân"

scan "C10a" "Bỏ qua phân quyền" \
  'ignore_permissions' \
  "chỉ chấp nhận trong job nền, và phải có comment giải thích ngay cạnh"

scan "C10b" "Phá transaction · N+1 · việc nặng trong hook" \
  '(frappe\.db\.commit|for .*in .*:.*frappe\.get_doc|frappe\.get_doc\(.*\) *$)' \
  "commit giữa request = 🟡; lặp get_doc nghìn lần = 🟡, đổi sang get_all"

scan "C10c" "SQL nối chuỗi (nguy cơ injection)" \
  '(frappe\.db\.sql\([[:space:]]*f["'"'"']|%[[:space:]]*\(|\+[[:space:]]*["'"'"'][[:space:]]*(SELECT|WHERE|FROM))' \
  "phải dùng frappe.qb hoặc tham số hóa %(x)s"

scan "C10d" "Fixture · custom field" \
  '(custom_field|property_setter|fixtures|__islocal)' \
  "sửa tay trên site là deploy sau MẤT SẠCH; fixture thiếu __islocal thì import câm"

scan "C10e" "Múi giờ (kho Postgres chạy UTC)" \
  '(::date|DATE\(|date_trunc)' \
  "cắt ngày phải AT TIME ZONE 'Asia/Ho_Chi_Minh' — POS từng lệch 35,3%"

# ═════════════════════════ D. CHẠY PHÁT CHẾT NGAY ═════════════════════════
# Nguồn: .claude/skills/frappe-agent-validator/references/checklists.md (mục Fatal Errors)

echo ""
echo "D. CHẠY PHÁT CHẾT NGAY — code trông đúng, chạy là dừng"

echo ""
echo "──── C11 · Server Script: nạp thư viện / gọi sai biến"
# Server Script chạy trong hộp cát: CẤM mọi import, và biến là `doc` chứ không phải `self`.
# Chỉ soi file NÀO là Server Script — .py thường thì import là bình thường.
SS_FILES=()
for f in "${FILES_TON[@]:-}"; do
  case "$f" in
    *server_script*|*Server?Script*) SS_FILES+=("$f") ;;
    *.json) grep -qi '"doctype"[[:space:]]*:[[:space:]]*"Server Script"' "$f" 2>/dev/null && SS_FILES+=("$f") ;;
  esac
done
if [ ${#SS_FILES[@]} -gt 0 ]; then
  SS_HIT=$(grep -nE '(^|\\n|["[:space:]])(import[[:space:]]+[a-z]|from[[:space:]]+[a-z_.]+[[:space:]]+import)|\bself\.' "${SS_FILES[@]}" 2>/dev/null | head -25 || true)
  if [ -n "$SS_HIT" ]; then
    echo "     ⚑ Server Script có lệnh nạp thư viện hoặc dùng \`self\` — hộp cát chặn, chạy là chết"
    echo "     cách đọc: import json → frappe.parse_json() · nowdate → frappe.utils.nowdate() · self → doc"
    printf '%s\n' "$SS_HIT" | sed 's/^/       /'
  else
    echo "     sạch — ${#SS_FILES[@]} file Server Script, không có import và không dùng self"
  fi
else
  echo "     (không có file Server Script trong lần đổi này)"
fi

scan "C12" "Trình duyệt gọi hàm của máy chủ" \
  'frappe\.db\.(get_value|set_value|sql|get_all|get_list|delete)' \
  "trong .py là ĐÚNG. Trong .js thì trình duyệt KHÔNG có hàm này — phải đi qua frappe.call()" \
  js

scan "C14" "Trỏ nhầm màn hình đang mở" \
  '\bcur_frm\b' \
  "mở nhiều tab là ghi nhầm tab — không báo lỗi, chỉ sai âm thầm. Phải dùng tham số frm" \
  js

scan "C15" "Cách viết bản cũ đã bỏ (v16)" \
  '(override_doctype_class|frappe\.provide)' \
  "v16 dùng extend_doctype_class. Chạy được hôm nay, chết khi nâng cấp" \
  py

scan "C20" "Tên kỹ thuật không phải tiếng Anh" \
  '"(fieldname|name|module)"[[:space:]]*:[[:space:]]*"[^"]*[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ]' \
  "luật nhà: tên kỹ thuật = tiếng Anh, chỉ NHÃN hiển thị mới tiếng Việt có dấu" \
  json

scan "C25" "Ô chọn-được lại để gõ tay" \
  '"fieldtype"[[:space:]]*:[[:space:]]*"Data"' \
  "luật nhà: chọn-được thì phải Link/Select. Data chỉ dùng cho thứ THẬT SỰ gõ tự do" \
  json

# ═════════════════════════ E. IM LẶNG KHÔNG CHẠY ═════════════════════════
# Nhóm nguy nhất: không báo lỗi, không ai biết, chỉ lộ khi đã quyết trên số cũ.

echo ""
echo "E. IM LẶNG KHÔNG CHẠY — nguy nhất, vì không ai được báo"

scan "C16" "Lỗi chết câm (nuốt lỗi rồi báo thành công)" \
  '(except[^:]*:[[:space:]]*(pass|continue|return|None)|except[[:space:]]*:|catch[[:space:]]*\([^)]*\)[[:space:]]*\{[[:space:]]*\}|catch[[:space:]]*\{[[:space:]]*\}|\.catch\([[:space:]]*\(\)[[:space:]]*=>[[:space:]]*\{?[[:space:]]*\}?\))' \
  "bắt lỗi rồi bỏ qua = 🔴. Phải frappe.log_error() + báo ra ngoài. Sync đã chết kiểu này: hết hạn token, vẫn trả 'thành công'"

echo ""
echo "     ↑ lưu ý: grep chỉ thấy khi 'pass' nằm CÙNG DÒNG với except."
echo "       Nếu diff có bất kỳ 'except'/'catch' nào, người soi phải đọc tay xem có nuốt lỗi không."

scan "C17" "Tên sự kiện bám sai (Frappe im lặng không gọi)" \
  '["'"'"'](on_save|after_save|before_update|after_update|on_delete|before_cancel_doc|on_validate)["'"'"']' \
  "tên sai thì Frappe KHÔNG báo lỗi, chỉ lặng lẽ không chạy. Tên đúng: validate · before_save · on_update · on_submit · on_cancel · on_trash · after_insert" \
  py

scan "C13" "Lấy kết quả sai cách khi gọi máy chủ" \
  '(let|const|var)[[:space:]]+[a-zA-Z_$][a-zA-Z0-9_$]*[[:space:]]*=[[:space:]]*frappe\.call[[:space:]]*\(' \
  "frappe.call trả về Promise — gán thẳng là LUÔN nhận rỗng, tưởng 'không có dữ liệu'. Phải await hoặc callback" \
  js

scan "C18" "Sửa đè mà có thể quên giữ phần gốc" \
  '(extend_doctype_class|override_whitelisted_methods|override_doctype_dashboards)' \
  "v16: MỌI hàm ghi đè BẮT BUỘC gọi super(). Thiếu là mất logic gốc ERPNext, không ai báo" \
  py

echo ""
echo "──── C21 · Bản vá viết xong nhưng chưa khai báo"
# Patch không khai trong patches.txt thì không chạy lúc nâng cấp — âm thầm bỏ qua.
PATCH_MOI=$(printf '%s\n' "${FILES[@]:-}" | grep -E '(^|/)patches/.*\.py$' | grep -v '__init__' || true)
if [ -n "$PATCH_MOI" ]; then
  THIEU=""
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    # đổi đường dẫn thành đường dẫn module: a/b/c.py → a.b.c
    modp=$(printf '%s' "$p" | sed 's|\.py$||; s|/|.|g')
    ten=$(basename "$p" .py)
    if ! grep -rq "$ten" --include='patches.txt' . 2>/dev/null; then
      THIEU="$THIEU
       $p   (không thấy \"$ten\" trong patches.txt nào)"
    fi
  done <<< "$PATCH_MOI"
  if [ -n "$THIEU" ]; then
    echo "     ⚑ bản vá CHƯA khai báo — sẽ không chạy lúc nâng cấp:"
    printf '%s\n' "$THIEU"
  else
    echo "     ✓ mọi bản vá trong lần đổi này đều có tên trong patches.txt"
  fi
else
  echo "     (không có bản vá mới trong lần đổi này)"
fi

# ═════════════════════════ F. VỠ DỮ LIỆU CŨ ═════════════════════════

echo ""
echo "F. VỠ DỮ LIỆU CŨ — không lùi lại được"

echo ""
echo "──── C22 · Xóa cột / đổi cách đánh số trên bảng đã có dữ liệu"
echo "     (cổng DUY NHẤT soi dòng BỊ XÓA — vì ở đây xóa mới là cái nguy)"
XOA_HIT=$(printf '%s\n' "$XOA_JSON" | grep -Ei '"(fieldname|autoname|naming_rule)"[[:space:]]*:' || true)
if [ -n "$XOA_HIT" ]; then
  SO_XOA=$(printf '%s\n' "$XOA_HIT" | grep -c . || true)
  echo "     ⚑ $SO_XOA dòng định nghĩa cột/cách-đánh-số BỊ XÓA hoặc BỊ ĐỔI:"
  printf '%s\n' "$XOA_HIT" | head -20 | sed 's/^/       /'
  echo "     cách đọc: bảng CHƯA có dữ liệu thật thì OK. ĐÃ có dữ liệu → 🔴, bản ghi cũ hỏng vĩnh viễn."
  echo "               Đếm trước khi quyết: bench --site <site> execute frappe.db.count --args '[\"<DocType>\"]'"
else
  echo "     sạch — không xóa cột, không đổi cách đánh số"
fi

# ═════════════════════════ G. LUẬT NHÀ ═════════════════════════

echo ""
echo "G. LUẬT NHÀ NTV"

scan "C19" "Viết cứng tên hệ thống vào code" \
  '(--site[[:space:]]+(ntv|nguoithuanviet)|erpnext-demo-backend-1|ntv-thu-backend-1|localhost:80(80|91)|platform\.(nem|nguoithuanviet))' \
  "đúng ở máy anh Bình, SAI trên bản thật. Script vận hành thì được; code trong app thì không"

echo ""
echo "──── C23 · Đóng gói thiếu cờ chip"
DOCKER_F=$(printf '%s\n' "${FILES_TON[@]:-}" | grep -Ei '(dockerfile|containerfile|.*build.*\.sh$|.*dong-goi.*\.sh$)' || true)
if [ -n "$DOCKER_F" ]; then
  THIEU_CHIP=""
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    if grep -qE '(docker|podman)[[:space:]]+(buildx[[:space:]]+)?build' "$d" 2>/dev/null; then
      grep -qE '\-\-platform[= ]+linux/amd64' "$d" 2>/dev/null || THIEU_CHIP="$THIEU_CHIP
       $d"
    fi
  done <<< "$DOCKER_F"
  if [ -n "$THIEU_CHIP" ]; then
    echo "     ⚑ có lệnh đóng gói mà KHÔNG thấy --platform=linux/amd64:"
    printf '%s\n' "$THIEU_CHIP"
    echo "     cách đọc: Mac là chip ARM, máy chủ là Intel. Thiếu cờ này = desk chết trên máy chủ"
  else
    echo "     ✓ mọi lệnh đóng gói đều có --platform=linux/amd64"
  fi
else
  echo "     (không đụng file đóng gói trong lần đổi này)"
fi

scan "C24" "Sửa thẳng trong máy ảo (viết trên cát)" \
  '(docker[[:space:]]+cp|\.pth\b|docker[[:space:]]+exec[^|]*(vi |vim |nano |tee |cat[[:space:]]*>))' \
  "sửa trong container = MẤT SẠCH khi đóng gói lại. Cài app bằng docker cp/.pth = desk lỗi 500"

# Cổng 4 — kiểm file thật, không grep diff
echo ""
echo "──── C4 · pyproject.toml khai phiên bản Frappe"
if [ -f pyproject.toml ]; then
  if grep -q 'tool.bench.frappe-dependencies' pyproject.toml 2>/dev/null; then
    echo "     ✓ có khai:"
    grep -A3 'tool.bench.frappe-dependencies' pyproject.toml | sed 's/^/       /'
  else
    echo "     🔴 THIẾU [tool.bench.frappe-dependencies] — Frappe Cloud sẽ từ chối dựng app này"
    echo "       thêm vào pyproject.toml:"
    echo "         [tool.bench.frappe-dependencies]"
    echo "         frappe = \">=16.0.0,<17.0.0\""
  fi
else
  echo "     (không có pyproject.toml ở thư mục gốc — bỏ qua nếu đây không phải app Frappe)"
fi

# ───────────────────────────── H. Việc còn lại của người ─────────────────────────────

cat <<'HET'

════════════════════════════════════════════════════════════
 MÁY QUÉT XONG. Năm việc máy KHÔNG làm được, người phải làm:
════════════════════════════════════════════════════════════
 1. Xem ngữ cảnh từng dấu hiệu ⚑ ở trên — grep không hiểu code.
 2. Đọc references/luat-erp.md nếu có đụng chứng từ · sổ sách · kho · master data.
 3. Bốn thứ grep KHÔNG bắt được, phải đọc tay (nguồn: frappe-agent-validator):
      · sửa self.x trong on_update (không lưu, mất im lặng)
      · gọi self.save() trong lifecycle (vòng lặp vô tận)
      · ngữ nghĩa transaction: validate/before_* có rollback, on_update/on_* KHÔNG
      · DocType JSON đủ chưa: module có trong modules.txt, Link có options, đủ permission
 4. CHẠY THỬ THẬT — xem references/chay-thu.md. Không có bằng chứng chạy được thì không cho 🟢.
 5. Phán verdict + soạn báo cáo dán vào Pull Request + GHI MỘT DÒNG vào NHAT-KY-SOI.md.
════════════════════════════════════════════════════════════
HET

exit 0
