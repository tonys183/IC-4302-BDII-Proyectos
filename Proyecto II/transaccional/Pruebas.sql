-- ==========================
-- Pruebas de las funciones
-- ==========================

SELECT insertarCliente(
    p_store_id := 1::smallint,
    p_first_name := 'Juan'::varchar,
    p_last_name := 'Perez'::varchar,
    p_email := 'juan.perez@example.com'::varchar,
    p_address := '47 MySakila Drive'::varchar,
    p_address2 := NULL::varchar,
    p_district := 'Alberta'::varchar,
    p_city_id := 300::smallint,
    p_postal_code := '12345'::varchar,
    p_phone := '555123456'::varchar,
    p_activebool := true
);
SELECT * FROM customer WHERE first_name = 'Juan' AND last_name = 'Perez';

-- 2. Función registrar_alquiler
SELECT registrarAlquiler(
    p_film_title := 'AGENT TRUMAN'::varchar,
    p_customer_first_name := 'MARY'::varchar,
    p_customer_last_name := 'SMITH'::varchar,
    p_staff_first_name := 'Mike'::varchar,
    p_staff_last_name := 'Hillyer'::varchar
);
SELECT r.rental_id, f.title, c.first_name || ' ' || c.last_name AS customer_name, r.rental_date FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
ORDER BY r.rental_date DESC;

-- 3. Función registrar_devolucion
SELECT registrarDevolucion(
    p_film_title := 'AGENT TRUMAN'::varchar,
    p_customer_first_name := 'MARY'::varchar,
    p_customer_last_name := 'SMITH'::varchar,
    p_rental_date := CURRENT_DATE
);
SELECT r.rental_id, r.rental_date, r.return_date FROM rental r
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
ORDER BY r.rental_date DESC;

-- 4. Función buscar_pelicula
SELECT * FROM buscarPelicula('Attraction Newton'::varchar);


-- ============================
-- Pruebas de roles & permisos
-- ============================

DO $$
BEGIN
    RAISE NOTICE '--- Probando rol ADMIN (administrador1) ---';

    -- 1.1 Prueba de insertar_nuevo_cliente (Debería funcionar)
    RAISE NOTICE 'Probando insertar_nuevo_cliente...';
    PERFORM insertarCliente(
        p_store_id := 2::smallint,
        p_first_name := 'Ana'::varchar,
        p_last_name := 'Gomez'::varchar,
        p_email := 'ana.gomez@example.com'::varchar,
        p_address := '123 Test Street'::varchar,
        p_address2 := NULL::varchar,
        p_district := 'Test District'::varchar,
        p_city_id := 100::smallint,
        p_postal_code := '54321'::varchar,
        p_phone := '555987654'::varchar
    );
    RAISE NOTICE '-> ÉXITO: administrador1 puede insertar clientes.';

    -- 1.2 Prueba de registrar_alquiler (Debería funcionar)
    RAISE NOTICE 'Probando registrar_alquiler...';
    PERFORM registrarAlquiler(
        p_film_title := 'ACADEMY DINOSAUR'::varchar,
        p_customer_first_name := 'MARY'::varchar,
        p_customer_last_name := 'SMITH'::varchar,
        p_staff_first_name := 'Mike'::varchar,
        p_staff_last_name := 'Hillyer'::varchar
    );
    RAISE NOTICE '-> ÉXITO: administrador1 puede registrar alquileres.';

    -- 1.3 Prueba de acceso directo a tablas (Debería fallar)
    RAISE NOTICE 'Probando acceso directo a la tabla customer...';
    BEGIN
        PERFORM * FROM customer LIMIT 1;
        RAISE EXCEPTION 'FALLO EN LA PRUEBA: administrador1 NO debería poder leer la tabla customer directamente.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE '-> ERROR: administrador1 no tiene permisos para leer la tabla customer directamente.';
    END;
END $$;


DO $$
BEGIN
    RAISE NOTICE '--- Probando rol EMP (empleado1) ---';

    -- 2.1 Prueba de buscar_pelicula (Debería funcionar)
    RAISE NOTICE 'Probando buscar_pelicula...';
    PERFORM buscarPelicula('LOVE'::varchar);
    RAISE NOTICE '-> ÉXITO: empleado1 puede buscar películas.';

    -- 2.2 Prueba de registrar_devolucion (Debería funcionar)
    RAISE NOTICE 'Probando registrar_devolucion...';
    PERFORM registrarDevolucion(
        p_film_title := 'ACADEMY DINOSAUR'::varchar,
        p_customer_first_name := 'MARY'::varchar,
        p_customer_last_name := 'SMITH'::varchar,
        p_rental_date := CURRENT_DATE
    );
    RAISE NOTICE '-> ÉXITO: empleado1 puede registrar devoluciones.';

    -- 2.3 Prueba de insertar_nuevo_cliente (Debería fallar)
    RAISE NOTICE 'Probando insertar_nuevo_cliente...';
    BEGIN
        PERFORM insertarCliente(
            p_store_id := 2::smallint, p_first_name := 'Test'::varchar, p_last_name := 'User'::varchar,
            p_email := 'test@example.com'::varchar, p_address := 'Test'::varchar, p_address2 := NULL::varchar,
            p_district := 'Test'::varchar, p_city_id := 1::smallint, p_postal_code := '1'::varchar, p_phone := '1'::varchar
        );
        RAISE EXCEPTION 'FALLO EN LA PRUEBA: empleado1 NO debería poder insertar clientes.';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE '-> ÉXITO: A empleado1 se le denegó correctamente el permiso para insertar clientes.';
    END;
END $$;