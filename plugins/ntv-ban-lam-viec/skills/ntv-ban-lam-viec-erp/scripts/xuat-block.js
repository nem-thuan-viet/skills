/* xuat-block.js — xuất HTML/CSS/JS của một Custom HTML Block ra màn hình để copy lưu vào thư mục dự án
   (bản ghi trên ERP ai sửa nhầm là mất). Chạy trong Console tab desk. Chỉ đọc. */
(async () => {
  const TEN_KHOI = 'TEN Khối';
  const d = (await fetch('/api/resource/Custom%20HTML%20Block/' + encodeURIComponent(TEN_KHOI)).then((r) => r.json())).data;
  if (!d) { console.error('Không thấy khối', TEN_KHOI); return; }
  document.open(); document.write('<pre style="white-space:pre-wrap;font:11px monospace"></pre>'); document.close();
  document.querySelector('pre').textContent = '=====HTML=====\n' + d.html + '\n=====CSS=====\n' + d.style + '\n=====JS=====\n' + d.script;
  // Lưu thành 3 file: <Tên>/1-HTML.html · 2-Style.css · 3-Script.js
})();

/* Liệt kê khối + workspace đang dùng chúng:
(async () => {
  const ws = (await fetch('/api/resource/Workspace?fields=["name","public","for_user"]&limit_page_length=500').then(r => r.json())).data;
  const out = [];
  for (const w of ws) { const d = (await fetch('/api/resource/Workspace/' + encodeURIComponent(w.name)).then(r => r.json())).data; if (d.custom_blocks?.length) out.push(w.name + ' → ' + d.custom_blocks.map(c => c.custom_block_name).join(', ')); }
  console.log(out.join('\n'));
})();
*/
