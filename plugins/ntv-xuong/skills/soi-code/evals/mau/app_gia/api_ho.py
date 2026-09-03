import frappe

@frappe.whitelist(allow_guest=True)
def lay_nhan_su():
    return frappe.get_all("Employee", fields=["employee_name", "salary", "valuation_rate"])
