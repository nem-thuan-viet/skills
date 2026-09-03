import frappe

def ghi_so(ten):
    frappe.get_doc({"doctype": "GL Entry", "account": "131"}).insert(ignore_permissions=True)
    frappe.db.set_value("Sales Invoice", ten, "docstatus", 1)
    cty = frappe.defaults.get_user_default("Company")
    return cty
