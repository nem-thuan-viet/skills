import frappe

def doanh_thu(tu_ngay):
    return frappe.db.sql(f"SELECT posting_date::date, SUM(grand_total) FROM `tabSales Invoice` WHERE posting_date > '{tu_ngay}'")
