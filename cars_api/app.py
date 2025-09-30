from flask import Flask, request, jsonify
from flask_mysqldb import MySQL
import os

app = Flask(__name__)

# Configuración MySQL desde variables de entorno
app.config['MYSQL_USER'] = os.environ['MYSQL_USER']
app.config['MYSQL_PASSWORD'] = os.environ['MYSQL_PASSWORD']
app.config['MYSQL_HOST'] = os.environ['MYSQL_HOST']
app.config['MYSQL_DB'] = os.environ['MYSQL_DB']
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'
mysql = MySQL(app)


@app.route('/create-table')
def create_table():
    cursor = mysql.connection.cursor()
    cursor.execute(''' CREATE TABLE IF NOT EXISTS cars (id INT NOT NULL AUTO_INCREMENT,
                                                        brand VARCHAR(50) NOT NULL,
                                                        model VARCHAR(50) NOT NULL,
                                                        year INT NOT NULL, PRIMARY KEY (id)) ''')
    mysql.connection.commit()
    cursor.close()
    return 'Tabla cars creada', 201

# GET /cars → obtener todos los coches
@app.route('/cars', methods=['GET'])
def get_cars():
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT * FROM cars")
        cars = cursor.fetchall()
        cursor.close()
        return jsonify(cars)

# POST /cars → crear un nuevo coche
@app.route('/cars', methods=['POST'])
def add_car():
        data = request.get_json()
        brand = data.get("brand")
        model = data.get("model")
        year = data.get("year")

        if not brand or not model or not year:
            return jsonify({"error": "Missing fields"}), 400

        cursor = mysql.connection.cursor()
        cursor.execute(
            "INSERT INTO cars (brand, model, year) VALUES (%s, %s, %s)",
            (brand, model, year))
        mysql.connection.commit()
        new_id = cursor.lastrowid
        cursor.close()

        return jsonify({"id": new_id, "brand": brand, "model": model, "year": year}), 201

# PUT /cars/{id} → actualizar coche existente
@app.route('/cars/<int:car_id>', methods=['PUT'])
def update_car(car_id):
        data = request.get_json()
        brand = data.get("brand")
        model = data.get("model")
        year = data.get("year")

        cursor = mysql.connection.cursor()
        cursor.execute(
            "UPDATE cars SET brand=%s, model=%s, year=%s WHERE id=%s",
            (brand, model, year, car_id))
        mysql.connection.commit()

        if cursor.rowcount == 0: 
            cursor.close()
            return jsonify({"error": "Car not found"}), 404

        cursor.close()
        return jsonify({"id": car_id, "brand": brand, "model": model, "year": year})
