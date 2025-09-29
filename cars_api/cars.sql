CREATE DATABASE IF NOT EXISTS carsdb;
USE carsdb;

CREATE TABLE IF NOT EXISTS cars (
	id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	brand VARCHAR(50) NOT NULL,
	model VARCHAR(50) NOT NULL,
	year INT NOT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO cars (brand, model, year) VALUES
('Volksvagen', 'Golf', 2020),
('Volksvagen', 'Polo', 2019),
('Volksvagen', 'Tiguan', 2022),
('Volksvagen', 'T-Cross', 2022);
