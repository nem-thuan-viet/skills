/* dieu-huong-thanh-trai.js — dán đoạn này vào CUỐI script của khối đầu tiên trên bàn (trước run()).
   Làm 3 việc: (1) bấm mục thanh trái có dạng /desk/<bàn>#<id> thì trượt tới khối/section trong shadow DOM,
   không tải lại trang; (2) tô ô đang chọn trên thanh trái; (3) cuộn tay tới đâu thì ô đó sáng.
   Mục thanh trái: Workspace Sidebar Item type Link, link_type URL, url '/desk/<slug bàn>#<id>'.
   Đã kiểm trên Frappe 16 (03–05/09/2026). Bẫy đã cắn ghi ở từng chỗ. */

// ---- 1) khai báo: hash → phần tử mục tiêu ----
// Section trong cùng khối: đặt id trên <section id="sec-..."> rồi dùng thẳng '#sec-...'.
// Khối khác (shadow root khác): đặt id lên div gốc của khối đó (ví dụ <div class="kd" id="ghi-chu">) → cũng dùng thẳng.
// HASH_MAP chỉ cần khi muốn trỏ tới HOST của khối khác qua một phần tử bên trong nó.
const HASH_MAP = { '#top': '#tiles-thang' /*, '#okr': '#okr-body', '#ads-ngay': '#tbl2' */ };
// Thứ tự các mốc để tô ô sáng khi cuộn tay: 'selector' hoặc 'selector:#hash' khi selector nằm trong khối khác.
const SPY = ['#tiles-thang:#top', '#sec-bang', '#sec-xem' /*, '#okr-body:#okr', '#tbl2:#ads-ngay', '#ghi-chu' */];
const LAST_HASH = '#sec-xem'; // mốc cuối trang: chạm đáy thì sáng ô này (khối cuối không bao giờ lên tới vạch)

function findTarget(h) {
  const hosts = [...document.querySelectorAll('*')].filter((e) => e.shadowRoot);
  if (HASH_MAP[h]) return hosts.find((e) => e.shadowRoot.querySelector(HASH_MAP[h])) || null;
  for (const e of hosts) { const el = e.shadowRoot.querySelector(h); if (el) return el; }
  return null;
}
function targetY(target) {
  // BẪY: phần cuộn của desk Frappe 16 là .main-section, KHÔNG phải window.
  const sc = document.querySelector('.main-section') || document.scrollingElement;
  // BẪY: .page-head không dính (bottom âm khi cuộn) → chỉ dùng chiều cao của nó làm khoảng trừ.
  const head = document.querySelector('.page-head'); const headH = (head && head.getBoundingClientRect().height) || 60;
  const y = target.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop - headH - 16;
  return { sc, y: Math.max(0, Math.min(y, sc.scrollHeight - sc.clientHeight)) };
}
function scrollToHash(h) {
  h = h || location.hash; if (!h || h === '#') return;
  const target = findTarget(h); if (!target) return;
  const first = targetY(target); const sc0 = first.sc;
  // BẪY: scrollTo({behavior:'smooth'}) không chạy trên .main-section; tab ẩn thì requestAnimationFrame không chạy.
  if (document.hidden || (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches)) { sc0.scrollTop = first.y; return; }
  const fromY = sc0.scrollTop, dist0 = first.y - fromY, dur = Math.min(900, Math.max(350, Math.abs(dist0) * 0.45)), t0 = performance.now();
  if (window.__kdScrollAnim) cancelAnimationFrame(window.__kdScrollAnim);
  const easeOut = (t) => 1 - Math.pow(1 - t, 3); // nhanh lúc đầu, chậm dần về đích
  const step = (now) => {
    const t = Math.min(1, (now - t0) / dur);
    const cur = targetY(findTarget(h) || target); // đo lại đích mỗi khung: khối khác có thể đang tải làm trang dài ra
    cur.sc.scrollTop = fromY + (cur.y - fromY) * easeOut(t);
    if (t < 1) window.__kdScrollAnim = requestAnimationFrame(step);
    else { window.__kdScrollAnim = null; setTimeout(() => { const fin = targetY(findTarget(h) || target); if (Math.abs(fin.sc.scrollTop - fin.y) > 4) fin.sc.scrollTop = fin.y; }, 250); }
  };
  window.__kdScrollAnim = requestAnimationFrame(step);
}
// ---- 2) tô ô đang chọn (Frappe không làm nữa vì ta chặn click của nó) ----
function setActive(hash) {
  const hit = [...document.querySelectorAll('.sidebar-item-container a.item-anchor')].find((a) => (a.getAttribute('href') || '').endsWith(hash));
  if (!hit) return;
  document.querySelectorAll('.standard-sidebar-item.active-sidebar').forEach((el) => el.classList.remove('active-sidebar'));
  const item = hit.closest('.standard-sidebar-item'); if (item) item.classList.add('active-sidebar');
}
// ---- 3) cuộn tay → ô sáng theo ----
let spyTimer = null;
function spy() {
  const sc = document.querySelector('.main-section'); if (!sc) return;
  const head = document.querySelector('.page-head'); const line = ((head && head.getBoundingClientRect().height) || 60) + 40;
  const hosts = [...document.querySelectorAll('*')].filter((e) => e.shadowRoot);
  let best = null, bestTop = -Infinity;
  for (const sp of SPY) {
    const [sel, hashName] = sp.split(':'); const hash = hashName || sel;
    let el = null; for (const h of hosts) { el = h.shadowRoot.querySelector(sel); if (el) break; }
    if (!el) continue;
    const top = (hashName ? el.getRootNode().host : el).getBoundingClientRect().top;
    if (top <= line && top > bestTop) { bestTop = top; best = hash; }
  }
  if (!best) best = '#top';
  if (sc.scrollTop + sc.clientHeight >= sc.scrollHeight - 8) best = LAST_HASH;
  if (best !== window.__kdSpyLast) { window.__kdSpyLast = best; setActive(best); }
}
if (!window.__kdHashNav) {
  window.__kdHashNav = true;
  document.addEventListener('click', (e) => {
    const a = e.target.closest && e.target.closest('a[href*="#"]'); if (!a) return;
    const u = new URL(a.getAttribute('href'), location.origin);
    if (u.pathname === location.pathname && u.hash) { e.preventDefault(); e.stopPropagation(); e.stopImmediatePropagation(); history.replaceState(null, '', u.hash); window.__kdSpyLast = u.hash; setActive(u.hash); scrollToHash(u.hash); }
  }, true);
  window.addEventListener('hashchange', () => { setActive(location.hash); scrollToHash(); });
  const attachSpy = () => { const sc = document.querySelector('.main-section'); if (!sc || sc.__kdSpy) return; sc.__kdSpy = true; sc.addEventListener('scroll', () => { if (spyTimer) return; spyTimer = setTimeout(() => { spyTimer = null; if (!window.__kdScrollAnim) spy(); }, 120); }, { passive: true }); };
  attachSpy(); setTimeout(attachSpy, 2000);
}
setTimeout(() => { setActive(location.hash || '#top'); }, 600);
setTimeout(() => scrollToHash(), 400); setTimeout(() => scrollToHash(), 1500); // vào trang bằng link có #… thì trượt sẵn
