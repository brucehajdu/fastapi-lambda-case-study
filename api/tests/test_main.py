from fastapi.testclient import TestClient
from api.app.main import app
import random
import string
import pytest

client = TestClient(app)

invalid_item_ids = [
    "testing",
    b'100',
    list(range(100)),
    dict(),
    None,
    3.14159,
    -1
]

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello, World!"}

def test_read_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"message": "Healthy!"}

def test_read_items():
    for i in range(100):
        val = random.randint(0,1048576)
        q = ''.join(random.choices(string.ascii_letters,k=32))
        response = client.get(f"/items/{val}?q={q}")
        assert response.status_code == 200
        assert response.json() == {"item_id": val, "q": q}

@pytest.mark.parametrize("val", invalid_item_ids)
def test_invalid_input_for_item_id(val):
    response = client.get(f"/items/{val}")
    assert response.status_code == 422
