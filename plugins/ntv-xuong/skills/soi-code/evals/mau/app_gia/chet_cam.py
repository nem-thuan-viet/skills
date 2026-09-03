import frappe, requests

def dong_bo():
    try:
        r = requests.get("https://api.shopee.vn/orders", timeout=30)
        return r.json()
    except Exception: pass
