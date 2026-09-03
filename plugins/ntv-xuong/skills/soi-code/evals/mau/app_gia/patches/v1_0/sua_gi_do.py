import frappe

def execute():
    frappe.db.sql("UPDATE `tabItem` SET disabled = 0")
