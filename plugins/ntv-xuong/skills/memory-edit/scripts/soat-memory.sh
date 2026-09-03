#!/usr/bin/env bash
# Soát kho memory của repo hiện tại — chỉ ĐỌC, không sửa gì.
# Dùng: bash .claude/skills/memory-edit/scripts/soat-memory.sh [đường-dẫn-thư-mục-memory]
set -uo pipefail

DIR="${1:-}"
if [ -z "$DIR" ]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  DIR="$HOME/.claude/projects/$(echo "$ROOT" | sed 's#/#-#g')/memory"
fi

[ -d "$DIR" ] || { echo "❌ Không thấy thư mục memory: $DIR"; exit 1; }
cd "$DIR" || exit 1
echo "📁 $DIR"

# --- 1. Mục lục còn cách giới hạn bao xa (200 dòng / 25KB) ---
echo ""
echo "=== 1. MEMORY.md so với giới hạn nạp ==="
if [ -f MEMORY.md ]; then
  L=$(wc -l < MEMORY.md | tr -d ' '); B=$(wc -c < MEMORY.md | tr -d ' ')
  KB=$((B / 1024))
  printf "   %s dòng / 200   ·   %s KB / 25 KB\n" "$L" "$KB"
  [ "$L" -gt 200 ] && echo "   🔴 VƯỢT dòng — phần sau dòng 200 KHÔNG được nạp"
  [ "$B" -gt 25600 ] && echo "   🔴 VƯỢT dung lượng — phần vượt KHÔNG được nạp"
  [ "$L" -gt 160 ] && [ "$L" -le 200 ] && echo "   🟡 Sắp chạm trần, nên gộp bớt dòng"
else
  echo "   🔴 Chưa có MEMORY.md — phiên sau sẽ không biết kho này tồn tại"
fi

# --- 2. Đếm theo loại ---
echo ""
echo "=== 2. Số file theo loại ==="
for t in project feedback user reference; do
  printf "   %-10s %3d\n" "$t" "$(grep -l "type: $t" ./*.md 2>/dev/null | wc -l | tr -d ' ')"
done
NOTYPE=$(grep -L "type:" ./*.md 2>/dev/null | grep -v 'MEMORY.md' | tr '\n' ' ')
[ -n "$NOTYPE" ] && echo "   ⚠️  Thiếu dòng type: $NOTYPE"

# --- 3. project/feedback thiếu Why / How to apply ---
echo ""
echo "=== 3. File project|feedback THIẾU **Why:** hoặc **How to apply:** ==="
MISS=0
for f in *.md; do
  [ "$f" = "MEMORY.md" ] && continue
  grep -q "type: project\|type: feedback" "$f" 2>/dev/null || continue
  W=""; H=""
  grep -q '\*\*Why:\*\*' "$f" || W="Why"
  grep -q '\*\*How to apply:\*\*' "$f" || H="How-to-apply"
  if [ -n "$W$H" ]; then
    printf "   %-46s thiếu: %s %s\n" "$f" "$W" "$H"
    MISS=$((MISS + 1))
  fi
done
[ "$MISS" -eq 0 ] && echo "   ✅ Không thiếu file nào" || echo "   → $MISS file cần bổ sung"

# --- 4. Thiếu description (dòng quyết định file có được mở hay không) ---
echo ""
echo "=== 4. File thiếu 'description:' trong frontmatter ==="
NODESC=$(grep -L "description:" ./*.md 2>/dev/null | grep -v 'MEMORY.md' | tr '\n' ' ')
[ -n "$NODESC" ] && echo "   🔴 $NODESC" || echo "   ✅ Đủ cả"

# --- 5. Cụm nghi trùng chủ đề (theo từ chung trong tên file) ---
echo ""
echo "=== 5. Cụm NGHI TRÙNG chủ đề — cần kiểm tay ==="
STOP=" bay luat ntv app cong memory datbot api cho moi nha van gia doi kho tu "
for f in *.md; do
  [ "$f" = "MEMORY.md" ] && continue
  for tok in $(echo "${f%.md}" | tr '-' ' '); do
    [ ${#tok} -ge 4 ] || continue
    case "$STOP" in *" $tok "*) continue ;; esac
    echo "$tok|$f"
  done
done | sort -u | awk -F'|' '
  { list[$1] = list[$1] " " $2; n[$1]++ }
  END { for (t in n) if (n[t] >= 2) printf "   %-14s →%s\n", t, list[t] }
' | sort || echo "   (không có)"

# --- 6. File phình to (dấu hiệu nhồi nhiều việc vào 1 tờ) ---
echo ""
echo "=== 6. 5 file lớn nhất — soát xem có nhồi nhiều sự thật vào 1 tờ không ==="
for f in *.md; do
  [ "$f" = "MEMORY.md" ] && continue
  printf "%6d %s\n" "$(wc -c < "$f" | tr -d ' ')" "$f"
done | sort -rn | head -5 | awk '{ printf "   %5.1f KB  %s\n", $1/1024, $2 }'

echo ""
echo "✅ Soát xong — chỉ đọc, chưa sửa gì. Xử lý theo .claude/skills/memory-edit/SKILL.md"
