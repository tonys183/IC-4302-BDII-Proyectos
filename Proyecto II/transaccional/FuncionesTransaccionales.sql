DROP FUNCTION IF EXISTS insertarCliente(customer.store_id%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, customer.email%TYPE, address.address%TYPE, address.address2%TYPE, address.district%TYPE, address.city_id%TYPE, address.postal_code%TYPE, address.phone%TYPE, customer.activebool%TYPE);
DROP FUNCTION IF EXISTS registrarAlquiler(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, staff.first_name%TYPE, staff.last_name%TYPE);
DROP FUNCTION IF EXISTS registrarDevolucion(film.title%TYPE, customer.first_name%TYPE, customer.last_name%TYPE, DATE);
DROP FUNCTION IF EXISTS buscarPelicula(film.title%TYPE);

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