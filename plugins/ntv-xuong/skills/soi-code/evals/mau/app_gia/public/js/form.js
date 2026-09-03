frappe.ui.form.on('Sales Invoice', {
  refresh: function (frm) {
    const kq = frappe.call({ method: 'app_gia.api_ho.lay_nhan_su' });
    const ten = frappe.db.get_value('Customer', frm.doc.customer, 'customer_name');
    cur_frm.set_value('remarks', ten);
  }
});
