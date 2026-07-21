import os
import pytest
import requests

API_URL = os.environ.get("API_URL", "").rstrip("/")
# Auth token is provided via environment variable
AUTH_TOKEN = os.environ.get("AUTH_TOKEN")

# Skip when API_URL or AUTH_TOKEN is not set (keeps local and CI runs green)
pytestmark = pytest.mark.skipif(
    not API_URL or not AUTH_TOKEN,
    reason="API_URL or AUTH_TOKEN not set"
)

def test_live_api_crud_lifecycle():
    print(f"\nTesting live API at: {API_URL}")

    # Authorization header for the JWT-protected write routes
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}"
    }

    # 1. Create
    create_payload = {"title": "Live Integration Test", "content": "Testing CRUD lifecycle"}
    create_resp = requests.post(f"{API_URL}/notes", json=create_payload, headers=headers)
    assert create_resp.status_code == 201

    note_id = create_resp.json().get("id")
    assert note_id is not None

    # 2. Get
    get_resp = requests.get(f"{API_URL}/notes/{note_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["title"] == "Live Integration Test"

    # 3. Update
    update_payload = {"title": "Updated Live Test"}
    update_resp = requests.put(f"{API_URL}/notes/{note_id}", json=update_payload, headers=headers)
    assert update_resp.status_code == 200
    assert update_resp.json()["title"] == "Updated Live Test"

    # 4. Delete
    delete_resp = requests.delete(f"{API_URL}/notes/{note_id}", headers=headers)
    assert delete_resp.status_code == 204

    # 5. Verify the item is really gone
    get_deleted_resp = requests.get(f"{API_URL}/notes/{note_id}", headers=headers)
    assert get_deleted_resp.status_code == 404
