import pytest
from cars_api.app import app


@pytest.fixture
def client(monkeypatch):
    """Configura el cliente de pruebas de Flask sin tocar MySQL real."""

    # Mock de cursor y conexión
    class MockCursor:
        def __init__(self):
            self.data = []
            self.lastrowid = 1
            self.rowcount = 1

        def execute(self, query, params=None):
            if "INSERT" in query:
                self.lastrowid += 1
            elif "SELECT" in query:
                self.data = [{"id": 1, "brand": "Volksvagen", "model": "Golf", "year": 2020}]
            elif "UPDATE" in query and params[-1] != 1:  # id inexistente
                self.rowcount = 0

        def fetchall(self):
            return self.data

        def close(self):
            pass

    class MockConnection:
        def cursor(self):
            return MockCursor()
        def commit(self):
            pass

    class MockMySQL:
        def __init__(self, app):
            self.connection = MockConnection()

    # Parchar mysql en la app
    monkeypatch.setattr("app.mysql", MockMySQL(app))

    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_get_cars(client):
    """Debe devolver lista de coches"""
    response = client.get("/cars")
    assert response.status_code == 200
    data = response.get_json()
    assert isinstance(data, list)
    assert data[0]["brand"] == "Toyota"


def test_add_car(client):
    """Debe crear un coche nuevo"""
    response = client.post("/cars", json={"brand": "Honda", "model": "Civic", "year": 2022})
    assert response.status_code == 201
    data = response.get_json()
    assert data["brand"] == "Honda"


def test_add_car_missing_fields(client):
    """Debe fallar si faltan campos"""
    response = client.post("/cars", json={"brand": "Ford"})
    assert response.status_code == 400
    data = response.get_json()
    assert "error" in data


def test_update_car_success(client):
    """Debe actualizar un coche existente"""
    response = client.put("/cars/1", json={"brand": "Mazda", "model": "3", "year": 2021})
    assert response.status_code == 200
    data = response.get_json()
    assert data["id"] == 1


def test_update_car_not_found(client):
    """Debe devolver 404 si el coche no existe"""
    response = client.put("/cars/999", json={"brand": "Tesla", "model": "X", "year": 2023})
    assert response.status_code == 404
    data = response.get_json()
    assert "error" in data

