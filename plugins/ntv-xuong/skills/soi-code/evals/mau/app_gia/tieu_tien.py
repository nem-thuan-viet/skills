import frappe

def bat_quang_cao(campaign_id):
    budget = 5000000
    return {"campaign": campaign_id, "daily_budget": budget, "status": "ACTIVE"}
