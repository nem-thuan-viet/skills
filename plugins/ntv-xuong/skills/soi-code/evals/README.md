# Bộ test máy quét

```bash
bash .claude/skills/soi-code/evals/chay-test.sh
```

Thoát 0 = đạt hết. Thoát 1 = có ca trượt, in ra đường dẫn kết quả đầy đủ và repo giả để soi.

## Vì sao cần

Một cổng báo **"sạch"** có hai nghĩa khác hẳn nhau:

1. Code thật sự sạch — cổng làm đúng việc.
2. **Mẫu tìm bị sai nên không bao giờ khớp** — cổng đã chết mà không ai biết.

Nhìn kết quả quét thì hai cái này giống hệt nhau. Đã cắn thật ngày 04/08: cổng `cur_frm`
để nhầm phạm vi sang phía máy chủ (`py`) trong khi `cur_frm` là chuyện phía trình duyệt
(`js`) — nó sẽ **vĩnh viễn không kêu**, kể cả có lỗi. Phát hiện được là do tình cờ đọc lại,
không phải do có gì bắt.

Bộ test này phân biệt hai nghĩa đó bằng số.

## Hai lượt, đều cần như nhau

**Lượt A — file có lỗi cài sẵn, cổng PHẢI KÊU.** Mỗi cổng một lỗi thật.
Cổng im ở đây = cổng chết.

**Lượt B — file viết đúng, cổng PHẢI IM.** Bắt cổng kêu bừa và cổng sai phạm vi
(`frappe.db.get_value` trong `.py` là ĐÚNG, trong `.js` là SAI — cùng một chuỗi,
hai kết luận ngược nhau).

Lượt B quan trọng ngang lượt A: **cổng kêu nhầm bị người ta tắt còn nhanh hơn cổng bỏ sót.**
Bị kêu oan ba lần là thôi không gõ `/soi-code` nữa.

Cả hai lượt đều để file ở dạng **chưa commit**, nên đồng thời kiểm luôn việc máy quét có
soi đủ ba tầng không — đúng cái lỗi đã sửa ngày 04/08 (trước đó chỉ nhìn commit đã có
nên báo sạch giả).

## Cấu trúc

```
evals/
├── chay-test.sh    — dựng hai repo git tạm, chạy quét, chấm từng ca
├── mau/            — file CÓ LỖI cài sẵn (lượt A)
└── mau-sach/       — file VIẾT ĐÚNG (lượt B)
```

Repo tạm dựng bằng `mktemp -d`, xóa khi đạt hết. Trượt thì giữ lại để soi.

## Thêm cổng mới thì làm gì

1. Thêm cổng vào `scripts/quet.sh`.
2. Nhét một lỗi thật vào `mau/` — viết như code thật, đừng viết mỗi dòng regex khớp.
3. Nếu cổng dễ kêu bừa: thêm bản viết ĐÚNG vào `mau-sach/`.
4. Thêm dòng `phai_keu` (và `phai_im` nếu có) vào `chay-test.sh`.
5. Chạy lại.

## Kiểm chính bộ test

Bộ test luôn xanh thì vô dụng — phải chắc nó **đỏ được**. Cách kiểm: phá một cổng có chủ
đích rồi chạy lại, nó phải đỏ đúng chỗ. Đã kiểm 04/08 bằng hai phép phá:

| Phá gì | Bắt ở đâu |
|---|---|
| Đổi phạm vi `C14` về `py` | Lượt A — *"có lỗi mà cổng im"* |
| Nới mẫu `C16` cho khớp mọi chữ `except` | Lượt B — *"kêu nhầm"* |

Làm lại phép này mỗi khi sửa lớn `chay-test.sh`.
