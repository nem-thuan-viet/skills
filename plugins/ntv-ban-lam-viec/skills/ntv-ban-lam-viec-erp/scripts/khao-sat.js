/* khao-sat.js — các đoạn CHỈ ĐỌC để khảo sát nguồn số trước khi vẽ/dựng. Chạy trong Console tab desk đã đăng nhập.
   Kết quả dài: in ra console hoặc đổ vào trang bằng dump() để copy. */

const enc = encodeURIComponent;
const g = (u) => fetch(u, { headers: { 'X-Requested-With': 'XMLHttpRequest' } }).then((r) => r.json()).then((j) => j.message !== undefined ? j.message : j.data);
const dump = (o) => { document.open(); document.write('<pre style="white-space:pre-wrap;font:11px monospace"></pre>'); document.close(); document.querySelector('pre').textContent = JSON.stringify(o, null, 1); };

// 1) Danh sách field của một DocType (bỏ Section/Column/Tab Break)
async function fields(dt) {
  const r = await fetch('/api/method/frappe.desk.form.load.getdoctype?doctype=' + enc(dt)).then((r) => r.json());
  return (r.docs || [])[0].fields.filter((f) => !['Section Break', 'Column Break', 'Tab Break', 'HTML'].includes(f.fieldtype)).map((f) => f.fieldname + ':' + f.fieldtype + (f.options ? '(' + f.options.replace(/\n/g, '/') + ')' : ''));
}

// 2) Số dòng + ngày cuối có số (phát hiện bảng ngưng cập nhật)
async function health(dt, dateField) {
  const n = await g('/api/method/frappe.client.get_count?doctype=' + enc(dt));
  const last = await g('/api/resource/' + enc(dt) + '?fields=' + enc(JSON.stringify([{ MAX: dateField }, { MIN: dateField }])));
  return { rows: n, first: last[0]['MIN(`' + dateField + '`)'], last: last[0]['MAX(`' + dateField + '`)'] };
}

// 3) Giá trị distinct + tổng theo một cột (group_by)
async function groupBy(dt, col, sumCol, filters) {
  const f = [col, { COUNT: 'name' }]; if (sumCol) f.push({ SUM: sumCol });
  const rows = await g('/api/resource/' + enc(dt) + '?fields=' + enc(JSON.stringify(f)) + '&group_by=' + enc(col) + '&filters=' + enc(JSON.stringify(filters || [])) + '&limit_page_length=500');
  return rows.map((r) => ({ [col]: r[col], n: r['COUNT(`name`)'], sum: sumCol ? r['SUM(`' + sumCol + '`)'] : undefined }));
}

// 4) Thử một API method của app (kết quả trong .message)
async function api(path, params) { return g('/api/method/' + path + '?' + new URLSearchParams(params || {})); }

// 5) Tìm DocType theo tên/module
async function findDoctype(like) { return g('/api/resource/DocType?fields=["name","module","istable","issingle"]&filters=' + enc(JSON.stringify([['name', 'like', '%' + like + '%']])) + '&limit_page_length=100'); }

// 6) Danh sách whitelisted method mà giao diện SPA của một app đang gọi (mò tên hàm bridge)
async function apiPathsInBundle(indexUrl) {
  const idx = await fetch(indexUrl).then((r) => r.text());
  const js = [...idx.matchAll(/src="([^"]+\.js)"/g)].map((m) => m[1])[0];
  const b = await fetch(js.startsWith('/') ? js : indexUrl.replace(/[^/]+$/, '') + js).then((r) => r.text());
  return [...new Set([...b.matchAll(/\/api\/(?:method|eshop)\/[a-zA-Z0-9_./\-]+/g)].map((m) => m[0]))];
}

// ---- ví dụ ----
// dump({ f: await fields('eShop Invoice'), h: await health('FB Insight Daily', 'day'), k: await groupBy('eShop Invoice', 'sale_channel', 'actual_amount', [['report_date', '>=', '2026-08-01']]) });
// dump(await api('ntv_eshop.api.bridge.staff', { from: '2026-08-01', to: '2026-08-31' }));
// dump(await apiPathsInBundle('/assets/ntv_eshop/eshop-ui/index.html'));
