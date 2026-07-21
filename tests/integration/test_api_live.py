import os
import pytest
import requests

API_URL = os.environ.get("API_URL", "").rstrip("/")
# Tokenni env var orqali qabul qilamiz
AUTH_TOKEN = os.environ.get("AUTH_TOKEN")

# Agar URL yoki Token berilmasa, testni o'tkazib yuboramiz (CI/CD'da qizil bo'lmasligi uchun)
pytestmark = pytest.mark.skipif(
    not API_URL or not AUTH_TOKEN, 
    reason="API_URL or AUTH_TOKEN not set"
)

def test_live_api_crud_lifecycle():
    print(f"\nTesting live API at: {API_URL}")
    
    # Barcha so'rovlar uchun avtorizatsiya sarlavhasi
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}"
    }
    
    # 1. Create (Yaratish)
    create_payload = {"title": "Live Integration Test", "content": "Testing CRUD lifecycle"}
    create_resp = requests.post(f"{API_URL}/notes", json=create_payload, headers=headers)
    assert create_resp.status_code == 201
    
    note_id = create_resp.json().get("id")
    assert note_id is not None

    # 2. Get (O'qish)
    get_resp = requests.get(f"{API_URL}/notes/{note_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["title"] == "Live Integration Test"

    # 3. Update (Yangilash)
    update_payload = {"title": "Updated Live Test"}
    update_resp = requests.put(f"{API_URL}/notes/{note_id}", json=update_payload, headers=headers)
    assert update_resp.status_code == 200
    assert update_resp.json()["title"] == "Updated Live Test"

    # 4. Delete (O'chirish)
    delete_resp = requests.delete(f"{API_URL}/notes/{note_id}", headers=headers)
    assert delete_resp.status_code == 204

    # 5. Verify Delete (Haqiqatan ham o'chganini tekshirish)
    get_deleted_resp = requests.get(f"{API_URL}/notes/{note_id}", headers=headers)
    assert get_deleted_resp.status_code == 404