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