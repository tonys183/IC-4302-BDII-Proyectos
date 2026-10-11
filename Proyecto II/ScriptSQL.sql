-- ==================================================
-- Funciones transaccionales
-- ==================================================

-- 1. Insertar un nuevo cliente
CREATE OR REPLACE FUNCTION insertarCliente(
    p_store_id customer.store_id%TYPE,
    p_first_name customer.first_name%TYPE,
    p_last_name customer.last_name%TYPE,
    p_email customer.email%TYPE,
    p_address address.address%TYPE,
    p_address2 address.address2%TYPE,
    p_district address.district%TYPE,
    p_city_id address.city_id%TYPE,
    p_postal_code address.postal_code%TYPE,
    p_phone address.phone%TYPE,
    p_activebool customer.activebool%TYPE DEFAULT true
) RETURNS customer.customer_id%TYPE AS $$
DECLARE
    v_address_id address.address_id%TYPE;
    v_customer_id customer.customer_id%TYPE;
BEGIN
    INSERT INTO address (address, address2, district, city_id, postal_code, phone)
    VALUES (p_address, p_address2, p_district, p_city_id, p_postal_code, p_phone)
    RETURNING address_id INTO v_address_id;

    INSERT INTO customer (store_id, first_name, last_name, email, address_id, activebool, create_date)
    VALUES (p_store_id, p_first_name, p_last_name, p_email, v_address_id, p_activebool, NOW())
    RETURNING customer_id INTO v_customer_id;
    
    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql;


-- 2. Registrar un alquiler
CREATE OR REPLACE FUNCTION registrarAlquiler(
    p_film_title film.title%TYPE,
    p_customer_first_name customer.first_name%TYPE,
    p_customer_last_name customer.last_name%TYPE,
    p_staff_first_name staff.first_name%TYPE,
    p_staff_last_name staff.last_name%TYPE
) RETURNS rental.rental_id%TYPE AS $$
DECLARE
    v_film_id film.film_id%TYPE;
    v_inventory_id inventory.inventory_id%TYPE;
    v_rental_id rental.rental_id%TYPE;
    v_store_id customer.store_id%TYPE;
    v_customer_id customer.customer_id%TYPE;
    v_staff_id staff.staff_id%TYPE;
BEGIN
    SELECT customer_id INTO v_customer_id FROM customer
    WHERE first_name ILIKE p_customer_first_name AND last_name ILIKE p_customer_last_name
    LIMIT 1;

    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ningún cliente con el nombre % %', p_customer_first_name, p_customer_last_name;
    END IF;

    SELECT staff_id INTO v_staff_id FROM staff
    WHERE first_name ILIKE p_staff_first_name AND last_name ILIKE p_staff_last_name
    LIMIT 1;

    IF v_staff_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ningún empleado con el nombre % %', p_staff_first_name, p_staff_last_name;
    END IF;

    SELECT film_id INTO v_film_id FROM film
    WHERE title ILIKE p_film_title
    LIMIT 1;

    IF v_film_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna película con el título %', p_film_title;
    END IF;

    SELECT store_id INTO v_store_id FROM customer WHERE customer_id = v_customer_id;

    SELECT inventory_id INTO v_inventory_id FROM inventory
    WHERE film_id = v_film_id AND store_id = v_store_id
    AND inventory_in_stock(inventory_id)
    LIMIT 1;

    IF v_inventory_id IS NULL THEN
        RAISE EXCEPTION 'No hay copias disponibles de la película "%" en la tienda del cliente.', p_film_title;
    END IF;

    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
    VALUES (NOW(), v_inventory_id, v_customer_id, v_staff_id)
    RETURNING rental_id INTO v_rental_id;

    RETURN v_rental_id;
END;
$$ LANGUAGE plpgsql;


-- 3. Registrar una devolución
CREATE OR REPLACE FUNCTION registrarDevolucion(
    p_film_title film.title%TYPE,
    p_customer_first_name customer.first_name%TYPE,
    p_customer_last_name customer.last_name%TYPE,
    p_rental_date DATE
) RETURNS void AS $$
DECLARE
    v_rental_id rental.rental_id%TYPE;
    v_customer_id customer.customer_id%TYPE;
    v_film_id film.film_id%TYPE;
BEGIN
    SELECT customer_id INTO v_customer_id FROM customer
    WHERE first_name ILIKE p_customer_first_name AND last_name ILIKE p_customer_last_name
    LIMIT 1;

    IF v_customer_id IS NULL THEN
        RAISE EXCEPTION 'Cliente "% %" no encontrado.', p_customer_first_name, p_customer_last_name;
    END IF;

    SELECT film_id INTO v_film_id FROM film
    WHERE title ILIKE p_film_title
    LIMIT 1;

    IF v_film_id IS NULL THEN
        RAISE EXCEPTION 'Película "%" no encontrada.', p_film_title;
    END IF;

    SELECT r.rental_id INTO v_rental_id FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE i.film_id = v_film_id AND r.customer_id = v_customer_id
    AND r.rental_date::date = p_rental_date
    AND r.return_date IS NULL
    LIMIT 1;

    IF v_rental_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró un alquiler pendiente para la película "%" por el cliente "% %" en la fecha %.', p_film_title, p_customer_first_name, p_customer_last_name, p_rental_date;
    END IF;

    UPDATE rental SET return_date = NOW()
    WHERE rental_id = v_rental_id;
END;
$$ LANGUAGE plpgsql;


-- 4. Buscar una película
CREATE OR REPLACE FUNCTION buscarPelicula(
    p_titulo_busqueda film.title%TYPE
) RETURNS TABLE(film_id film.film_id%TYPE, title film.title%TYPE, release_year film.release_year%TYPE, rental_rate film.rental_rate%TYPE, rating film.rating%TYPE) AS $$
BEGIN
    RETURN QUERY
    SELECT f.film_id, f.title, f.release_year, f.rental_rate, f.rating FROM film f
    WHERE f.title ILIKE '%' || p_titulo_busqueda || '%';
END;
$$ LANGUAGE plpgsql;


-- ==================================================
-- Creación de Roles & Usuarios
-- ==================================================

CREATE ROLE "EMP";
CREATE ROLE "ADMIN";
CREATE ROLE video NOINHERIT NOLOGIN;
CREATE USER empleado1 WITH PASSWORD 'emple123' IN ROLE "EMP";
CREATE USER administrador1 WITH PASSWORD 'admin123' IN ROLE "ADMIN";

-- Permisos para video
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO video;
GRANT SELECT ON TABLE film, customer, staff, inventory, rental, address, city TO video;
GRANT INSERT ON TABLE customer, address, rental TO video;
GRANT UPDATE ON TABLE rental TO video;

-- Permisos para empleado1
GRANT EXECUTE ON FUNCTION registrarAlquiler(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, staff.first_name%TYPE, staff.last_name%TYPE) TO "EMP";
GRANT EXECUTE ON FUNCTION registrarDevolucion(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, DATE) TO "EMP";
GRANT EXECUTE ON FUNCTION buscarPelicula(film.title%TYPE) TO "EMP";

-- Permisos para administrador1
GRANT "EMP" TO "ADMIN";
GRANT EXECUTE ON FUNCTION insertarCliente(customer.store_id%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, customer.email%TYPE, address.address%TYPE, address.address2%TYPE, address.district%TYPE, address.city_id%TYPE, address.postal_code%TYPE, address.phone%TYPE, customer.activebool%TYPE) TO "ADMIN";

-- Asignación de propietarios a las funciones
ALTER FUNCTION insertarCliente(customer.store_id%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, customer.email%TYPE, address.address%TYPE, address.address2%TYPE, address.district%TYPE, address.city_id%TYPE, address.postal_code%TYPE, address.phone%TYPE, customer.activebool%TYPE) OWNER TO video;
ALTER FUNCTION registrarAlquiler(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, staff.first_name%TYPE, staff.last_name%TYPE) OWNER TO video;
ALTER FUNCTION registrarDevolucion(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, DATE) OWNER TO video;
ALTER FUNCTION buscarPelicula(film.title%TYPE) OWNER TO video;

-- Asignación de propietarios a las tablas
SELECT 'ALTER TABLE ' || schemaname || '.' || tablename || ' OWNER TO video;'
FROM pg_tables
WHERE schemaname IN ('public', 'datamart');

-- Asignación de propietarios a las secuencias
SELECT 'ALTER SEQUENCE ' || sequence_schema || '.' || sequence_name || ' OWNER TO video;'
FROM information_schema.sequences
WHERE sequence_schema IN ('public', 'datamart');

-- Asignación de propietarios a las funciones/procedimientos
SELECT
    CASE p.prokind
        WHEN 'f' THEN 'ALTER FUNCTION '
        WHEN 'p' THEN 'ALTER PROCEDURE '
        WHEN 'a' THEN 'ALTER AGGREGATE '
    END || n.nspname || '.' || p.proname || '(' || oidvectortypes(p.proargtypes) || ') OWNER TO video;'
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('public', 'datamart');

-- Definición de seguridad para las funciones
ALTER FUNCTION insertarCliente(customer.store_id%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, customer.email%TYPE, address.address%TYPE, address.address2%TYPE, address.district%TYPE, address.city_id%TYPE, address.postal_code%TYPE, address.phone%TYPE, customer.activebool%TYPE) SECURITY DEFINER;
ALTER FUNCTION registrarAlquiler(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, staff.first_name%TYPE, staff.last_name%TYPE) SECURITY DEFINER;
ALTER FUNCTION registrarDevolucion(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, DATE) SECURITY DEFINER;
ALTER FUNCTION buscarPelicula(film.title%TYPE) SECURITY DEFINER;

-- Revocación de todos los permisos para el public
REVOKE ALL ON FUNCTION insertarCliente(customer.store_id%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, customer.email%TYPE, address.address%TYPE, address.address2%TYPE, address.district%TYPE, address.city_id%TYPE, address.postal_code%TYPE, address.phone%TYPE, customer.activebool%TYPE) FROM PUBLIC;
REVOKE ALL ON FUNCTION registrarAlquiler(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, staff.first_name%TYPE, staff.last_name%TYPE) FROM PUBLIC;
REVOKE ALL ON FUNCTION registrarDevolucion(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, DATE) FROM PUBLIC;
REVOKE ALL ON FUNCTION buscarPelicula(film.title%TYPE) FROM PUBLIC;



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


-- ==================================================
-- Procedimientos para el Datamart
-- ==================================================

-- Poblar dim_time
CREATE OR REPLACE PROCEDURE poblarDimTime() LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO datamart.dim_time (full_date, day, month, year)
    SELECT
        DISTINCT(rental_date::date) AS full_date,
        EXTRACT(DAY FROM rental_date) AS day,
        EXTRACT(MONTH FROM rental_date) AS month,
        EXTRACT(YEAR FROM rental_date) AS year
    FROM public.rental r;
END;
$$;

-- Poblar dim_address
CREATE OR REPLACE PROCEDURE poblarDimAddress() LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO datamart.dim_address (address_id, country, city)
    SELECT a.address_id, co.country, ci.city FROM public.address a
    JOIN public.city ci ON a.city_id = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id;
END;
$$;

-- Poblar dim_store
CREATE OR REPLACE PROCEDURE poblarDimStore() LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO datamart.dim_store (store_id)
    SELECT s.store_id FROM public.store s;
END;
$$;

-- Poblar dim_film
CREATE OR REPLACE PROCEDURE poblarDimFilm() LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO datamart.dim_film (film_id, title, categories, language_name, actors_names)
    WITH film_categories AS (
        SELECT fc.film_id, STRING_AGG(c.name, ', ' ORDER BY c.name) as categories
        FROM public.film_category fc
        JOIN public.category c ON fc.category_id = c.category_id
        GROUP BY fc.film_id
    ),
    film_actors AS (
        SELECT fa.film_id, STRING_AGG(a.first_name || ' ' || a.last_name, ', ' ORDER BY a.actor_id) as actors
        FROM public.film_actor fa
        JOIN public.actor a ON fa.actor_id = a.actor_id
        GROUP BY fa.film_id
    )
    SELECT f.film_id, f.title, fc.categories, l.name AS language_name, fa.actors AS actors_names
    FROM public.film f
    JOIN public.language l ON f.language_id = l.language_id
    LEFT JOIN film_categories fc ON f.film_id = fc.film_id
    LEFT JOIN film_actors fa ON f.film_id = fa.film_id;
END;
$$;

-- Poblar fact_rents
CREATE OR REPLACE PROCEDURE poblarFactRents() LANGUAGE plpgsql AS $$
BEGIN
    WITH rental_payments AS (
        SELECT rental_id, SUM(amount) as total_amount FROM public.payment
        GROUP BY rental_id
    )
    INSERT INTO datamart.fact_rents (address_sk, film_sk, store_sk, time_sk, total_amount, rental_count)
    SELECT da.address_sk, df.film_sk, ds.store_sk, dt.time_sk, SUM(rp.total_amount) as total_amount, COUNT(r.rental_id) AS rental_count
    FROM public.rental r
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.customer c ON r.customer_id = c.customer_id
    JOIN rental_payments rp ON r.rental_id = rp.rental_id
    JOIN datamart.dim_address da ON c.address_id = da.address_id
    JOIN datamart.dim_film df ON i.film_id = df.film_id
    JOIN datamart.dim_store ds ON i.store_id = ds.store_id
    JOIN datamart.dim_time dt ON r.rental_date::date = dt.full_date
    GROUP BY da.address_sk, df.film_sk, ds.store_sk, dt.time_sk;
END;
$$;

-- 6. Procedimiento para ejecutar el ETL completo
CREATE OR REPLACE PROCEDURE ejecutarETLCompleto() LANGUAGE plpgsql AS $$
BEGIN
    TRUNCATE TABLE datamart.fact_rents, datamart.dim_time, datamart.dim_address, datamart.dim_store, datamart.dim_film RESTART IDENTITY CASCADE;
    CALL poblarDimTime();
    CALL poblarDimAddress();
    CALL poblarDimStore();
    CALL poblarDimFilm();
    CALL poblarFactRents();
END;
$$;


-- ==================================================
-- Configuración replicación
-- ==================================================

-- Configuración WAL level
ALTER SYSTEM SET wal_level = logical;
SELECT pg_reload_conf();

-- Publicación datos del Datamart
CREATE PUBLICATION pub_dw FOR ALL TABLES;

-- Creación de la base de datos OLAP
CREATE DATABASE dvdrentalOLAP;

-- Suscripción a la publicación
CREATE SUBSCRIPTION sub_dw
CONNECTION 'host=localhost port=5432 dbname=dvdrental 
user=postgres password=*****'
PUBLICATION pub_dw
WITH (copy_data = true, create_slot = false);

-- Creación del slot de replicación
SELECT pg_create_logical_replication_slot('sub_dw', 'pgoutput'); 