import os

os.environ['MYSQL_USER'] = 'test_user'
os.environ['MYSQL_PASSWORD'] = 'test_pass'
os.environ['MYSQL_HOST'] = 'localhost'
os.environ['MYSQL_DB'] = 'test_db'

import pytest
from cars_api.app import app

# ------------------ Fixture de Flask client ------------------
@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

# ------------------ Fixture de datos y mocks para GET ------------------
@pytest.fixture
def fake_mysql_get(monkeypatch):
    fake_cars = [
        {"id": 1, "brand": "Volkswagen", "model": "Golf", "year": 2020},
        {"id": 2, "brand": "Volkswagen", "model": "T-cross", "year": 2021}
    ]

    class FakeCursor:
        def execute(self, query):
            return None
        def fetchall(self):
            return fake_cars
        def close(self):
            pass

    class FakeConnection:
        def cursor(self):
            return FakeCursor()

    monkeypatch.setattr("cars_api.app.mysql", type("FakeMySQL", (), {"connection": FakeConnection()}))

# ------------------ Fixture de datos y mocks para POST ------------------
@pytest.fixture
def fake_mysql_post(monkeypatch):
    class FakeCursor:
        def execute(self, query, params):
            self.lastrowid = 42  # ID simulado
        def close(self):
            pass

    class FakeConnection:
        def __init__(self):
            self.cursor_obj = FakeCursor()
        def cursor(self):
            return self.cursor_obj
        def commit(self):
            return None

    monkeypatch.setattr("cars_api.app.mysql", type("FakeMySQL", (), {"connection": FakeConnection()}))

# ------------------ Tests GET ------------------
def test_get_cars_returns_list(client, fake_mysql_get):
    response = client.get("/cars")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    assert len(data) == 2
    assert data[0]["brand"] == "Volkswagen"
    assert data[1]["model"] == "T-cross"

# ------------------ Tests POST ------------------
def test_add_car_returns_created(client, fake_mysql_post):
    payload = {"brand": "Ford", "model": "Focus", "year": 2019}
    response = client.post("/cars", json=payload)
    assert response.status_code == 201
    data = response.get_json()
    assert data["id"] == 42
    assert data["brand"] == "Ford"
    assert data["model"] == "Focus"
    assert data["year"] == 2019

