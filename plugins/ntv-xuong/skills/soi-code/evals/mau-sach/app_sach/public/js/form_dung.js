frappe.ui.form.on('Sales Order', {
  refresh: async function (frm) {
    const kq = await frappe.call({ method: 'app_sach.api.lay_ten' });
    frm.set_value('remarks', kq.message);
    frm.refresh_field('remarks');
  }
});
