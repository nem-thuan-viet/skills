import frappe

def dong_bo():
    try:
        return goi_api_ngoai()
    except ConnectionError as e:
        frappe.log_error(f"Sync Shopee thất bại: {e}", "app_sach.dong_bo")
        frappe.throw("Không nối được Shopee. Kiểm tra token rồi chạy lại.")
