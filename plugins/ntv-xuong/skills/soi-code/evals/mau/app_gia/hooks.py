app_name = "app_gia"

override_doctype_class = {"Sales Invoice": "app_gia.overrides.SIcu"}

extend_doctype_class = {"Sales Order": "app_gia.overrides.SOmoi"}

doc_events = {
    "Sales Invoice": {
        "on_save": "app_gia.so_sach.ghi_so",
        "after_update": "app_gia.so_sach.ghi_so"
    }
}
