DROP TABLE IF EXISTS datamart.fact_rents;
DROP TABLE IF EXISTS datamart.dim_address;
DROP TABLE IF EXISTS datamart.dim_film;
DROP TABLE IF EXISTS datamart.dim_store;
DROP TABLE IF EXISTS datamart.dim_time;

-- ==================================================
-- Creación del Datamart
-- ==================================================

-- Esquema Datamart
CREATE SCHEMA IF NOT EXISTS datamart;

-- Dim Address
CREATE TABLE datamart.dim_address (
    address_sk SERIAL PRIMARY KEY,
    address_id INT,
    country VARCHAR(50),
    city VARCHAR(50)
);

-- Dim Film
CREATE TABLE datamart.dim_film (
    film_sk SERIAL PRIMARY KEY,
    film_id INT,
    title VARCHAR(255),
    categories TEXT,
    language_name VARCHAR(50),
    actors_names TEXT
);

-- Dim Store
CREATE TABLE datamart.dim_store (
    store_sk SERIAL PRIMARY KEY,
    store_id INT
);

-- Dim Time
CREATE TABLE datamart.dim_time (
    time_sk SERIAL PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    year INT
);

-- Fact Table: Rents 
CREATE TABLE datamart.fact_rents (
    address_sk INT REFERENCES datamart.dim_address(address_sk),
    film_sk INT REFERENCES datamart.dim_film(film_sk),
    store_sk INT REFERENCES datamart.dim_store(store_sk),
    time_sk INT REFERENCES datamart.dim_time(time_sk),
    rental_count INT DEFAULT 1,
    total_amount NUMERIC(5, 2),
    PRIMARY KEY (address_sk, film_sk, store_sk, time_sk)
);