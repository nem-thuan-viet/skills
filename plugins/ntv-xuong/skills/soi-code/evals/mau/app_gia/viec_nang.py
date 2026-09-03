import frappe

def don_du_lieu():
    for ten in frappe.get_all("Sales Invoice", pluck="name"):
        frappe.delete_doc("Sales Invoice", ten)
        frappe.db.commit()
