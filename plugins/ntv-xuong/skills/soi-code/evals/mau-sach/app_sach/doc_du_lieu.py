import frappe

def lay_ten_khach(ma_khach: str) -> str:
    """Đọc qua cửa hẹp của app nền `ntv`, không đọc thẳng DocType Customer."""
    if "ntv" not in frappe.get_installed_apps():
        return ""
    try:
        return frappe.get_attr("ntv.api.master_data.get_customer_name")(ma_khach)
    except Exception:
        frappe.log_error(title="mat day toi ntv", message=frappe.get_traceback())
        return ""
