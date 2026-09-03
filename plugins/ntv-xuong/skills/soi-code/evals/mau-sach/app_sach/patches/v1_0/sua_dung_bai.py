import frappe

def execute():
    frappe.reload_doc("app_sach", "doctype", "ok")
