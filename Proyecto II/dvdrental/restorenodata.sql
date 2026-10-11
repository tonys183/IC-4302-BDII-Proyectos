--
-- PostgreSQL database dump
--

\restrict Iy5qYjbKQVfJLxYxPrS9WETcymGmZYBc9bgpNeraeEaVmbZkZX0psk4sWty4LW7

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: datamart; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA datamart;


ALTER SCHEMA datamart OWNER TO postgres;

--
-- Name: mpaa_rating; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17'
);


ALTER TYPE public.mpaa_rating OWNER TO postgres;

--
-- Name: year; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN public.year AS integer
	CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));


ALTER DOMAIN public.year OWNER TO postgres;

--
-- Name: _group_concat(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public._group_concat(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE
  WHEN $2 IS NULL THEN $1
  WHEN $1 IS NULL THEN $2
  ELSE $1 || ', ' || $2
END
$_$;


ALTER FUNCTION public._group_concat(text, text) OWNER TO postgres;

--
-- Name: buscarpelicula(character varying); Type: FUNCTION; Schema: public; Owner: video
--

CREATE FUNCTION public.buscarpelicula(p_titulo_busqueda character varying) RETURNS TABLE(film_id integer, title character varying, release_year public.year, rental_rate numeric, rating public.mpaa_rating)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT f.film_id, f.title, f.release_year, f.rental_rate, f.rating FROM film f
    WHERE f.title ILIKE '%' || p_titulo_busqueda || '%';
END;
$$;


ALTER FUNCTION public.buscarpelicula(p_titulo_busqueda character varying) OWNER TO video;

--
-- Name: etl_populate_dim_address(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_populate_dim_address()
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO datamart.dim_address (address_id, country, city)
    SELECT
        a.address_id,
        co.country,
        ci.city
    FROM public.address a
    JOIN public.city ci ON a.city_id = ci.city_id
    JOIN public.country co ON ci.country_id = co.country_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM datamart.dim_address da
        WHERE da.address_id = a.address_id
    );
END;
$$;


ALTER PROCEDURE public.etl_populate_dim_address() OWNER TO postgres;

--
-- Name: etl_populate_dim_film(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_populate_dim_film()
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO datamart.dim_film (film_id, title, categories, language_name, actors_names)
    WITH film_categories AS (
        SELECT
            fc.film_id,
            STRING_AGG(c.name, ', ' ORDER BY c.name) as categories
        FROM public.film_category fc
        JOIN public.category c ON fc.category_id = c.category_id
        GROUP BY fc.film_id
    ),
    film_actors AS (
        SELECT
            fa.film_id,
            STRING_AGG(a.first_name || ' ' || a.last_name, ', ' ORDER BY a.actor_id) as actors
        FROM public.film_actor fa
        JOIN public.actor a ON fa.actor_id = a.actor_id
        GROUP BY fa.film_id
    )
    SELECT
        f.film_id,
        f.title,
        fc.categories,
        l.name AS language_name,
        fa.actors AS actors_names
    FROM public.film f
    JOIN public.language l ON f.language_id = l.language_id
    LEFT JOIN film_categories fc ON f.film_id = fc.film_id
    LEFT JOIN film_actors fa ON f.film_id = fa.film_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM datamart.dim_film df
        WHERE df.film_id = f.film_id
    );
END;
$$;


ALTER PROCEDURE public.etl_populate_dim_film() OWNER TO postgres;

--
-- Name: etl_populate_dim_store(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_populate_dim_store()
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO datamart.dim_store (store_id)
    SELECT
        s.store_id
    FROM public.store s
    WHERE NOT EXISTS (
        SELECT 1
        FROM datamart.dim_store ds
        WHERE ds.store_id = s.store_id
    );
END;
$$;


ALTER PROCEDURE public.etl_populate_dim_store() OWNER TO postgres;

--
-- Name: etl_populate_dim_time(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_populate_dim_time()
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO datamart.dim_time (full_date, day, month, year)
    SELECT
        DISTINCT(rental_date::date) AS full_date,
        EXTRACT(DAY FROM rental_date) AS day,
        EXTRACT(MONTH FROM rental_date) AS month,
        EXTRACT(YEAR FROM rental_date) AS year
    FROM public.rental r
    WHERE NOT EXISTS (
        SELECT 1
        FROM datamart.dim_time dt
        WHERE dt.full_date = r.rental_date::date
    );
END;
$$;


ALTER PROCEDURE public.etl_populate_dim_time() OWNER TO postgres;

--
-- Name: etl_populate_fact_rents(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_populate_fact_rents()
    LANGUAGE plpgsql
    AS $$
BEGIN
    TRUNCATE TABLE datamart.fact_rents;

    WITH rental_payments AS (
        SELECT
            rental_id,
            SUM(amount) as total_amount
        FROM public.payment
        GROUP BY rental_id
    )
    INSERT INTO datamart.fact_rents (address_sk, film_sk, store_sk, time_sk, total_amount, rental_count)
    SELECT
        da.address_sk,
        df.film_sk,
        ds.store_sk,
        dt.time_sk,
        SUM(rp.total_amount) as total_amount,
        COUNT(r.rental_id) AS rental_count
    FROM public.rental r
    JOIN public.inventory i ON r.inventory_id = i.inventory_id
    JOIN public.customer c ON r.customer_id = c.customer_id
    JOIN rental_payments rp ON r.rental_id = rp.rental_id
    JOIN datamart.dim_address da ON c.address_id = da.address_id
    JOIN datamart.dim_film df ON i.film_id = df.film_id
    JOIN datamart.dim_store ds ON i.store_id = ds.store_id
    JOIN datamart.dim_time dt ON r.rental_date::date = dt.full_date
    GROUP BY
        da.address_sk,
        df.film_sk,
        ds.store_sk,
        dt.time_sk;
END;
$$;


ALTER PROCEDURE public.etl_populate_fact_rents() OWNER TO postgres;

--
-- Name: etl_run_full_load(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.etl_run_full_load()
    LANGUAGE plpgsql
    AS $$
BEGIN
    CALL etl_populate_dim_time();
    CALL etl_populate_dim_address();
    CALL etl_populate_dim_store();
    CALL etl_populate_dim_film();
    CALL etl_populate_fact_rents();
END;
$$;


ALTER PROCEDURE public.etl_run_full_load() OWNER TO postgres;

--
-- Name: film_in_stock(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
     SELECT inventory_id
     FROM inventory
     WHERE film_id = $1
     AND store_id = $2
     AND inventory_in_stock(inventory_id);
$_$;


ALTER FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) OWNER TO postgres;

--
-- Name: film_not_in_stock(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
    SELECT inventory_id
    FROM inventory
    WHERE film_id = $1
    AND store_id = $2
    AND NOT inventory_in_stock(inventory_id);
$_$;


ALTER FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) OWNER TO postgres;

--
-- Name: get_customer_balance(integer, timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp without time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
       --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(IF((rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval),
        ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)),0)),0) INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END
$$;


ALTER FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp without time zone) OWNER TO postgres;

--
-- Name: insertarcliente(smallint, character varying, character varying, character varying, character varying, character varying, character varying, smallint, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: video
--

CREATE FUNCTION public.insertarcliente(p_store_id smallint, p_first_name character varying, p_last_name character varying, p_email character varying, p_address character varying, p_address2 character varying, p_district character varying, p_city_id smallint, p_postal_code character varying, p_phone character varying, p_activebool boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION public.insertarcliente(p_store_id smallint, p_first_name character varying, p_last_name character varying, p_email character varying, p_address character varying, p_address2 character varying, p_district character varying, p_city_id smallint, p_postal_code character varying, p_phone character varying, p_activebool boolean) OWNER TO video;

--
-- Name: inventory_held_by_customer(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.inventory_held_by_customer(p_inventory_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN

  SELECT customer_id INTO v_customer_id
  FROM rental
  WHERE return_date IS NULL
  AND inventory_id = p_inventory_id;

  RETURN v_customer_id;
END $$;


ALTER FUNCTION public.inventory_held_by_customer(p_inventory_id integer) OWNER TO postgres;

--
-- Name: inventory_in_stock(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.inventory_in_stock(p_inventory_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rentals INTEGER;
    v_out     INTEGER;
BEGIN
    -- AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    -- FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT count(*) INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
      RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO v_out
    FROM inventory LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
    AND rental.return_date IS NULL;

    IF v_out > 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END $$;


ALTER FUNCTION public.inventory_in_stock(p_inventory_id integer) OWNER TO postgres;

--
-- Name: last_day(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.last_day(timestamp without time zone) RETURNS date
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE
    WHEN EXTRACT(MONTH FROM $1) = 12 THEN
      (((EXTRACT(YEAR FROM $1) + 1) operator(pg_catalog.||) '-01-01')::date - INTERVAL '1 day')::date
    ELSE
      ((EXTRACT(YEAR FROM $1) operator(pg_catalog.||) '-' operator(pg_catalog.||) (EXTRACT(MONTH FROM $1) + 1) operator(pg_catalog.||) '-01')::date - INTERVAL '1 day')::date
    END
$_$;


ALTER FUNCTION public.last_day(timestamp without time zone) OWNER TO postgres;

--
-- Name: last_updated(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;


ALTER FUNCTION public.last_updated() OWNER TO postgres;

--
-- Name: registraralquiler(character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: video
--

CREATE FUNCTION public.registraralquiler(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_staff_first_name character varying, p_staff_last_name character varying) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
        RAISE EXCEPTION 'No se encontr├│ ning├║n cliente con el nombre % %', p_customer_first_name, p_customer_last_name;
    END IF;

    SELECT staff_id INTO v_staff_id FROM staff
    WHERE first_name ILIKE p_staff_first_name AND last_name ILIKE p_staff_last_name
    LIMIT 1;

    IF v_staff_id IS NULL THEN
        RAISE EXCEPTION 'No se encontr├│ ning├║n empleado con el nombre % %', p_staff_first_name, p_staff_last_name;
    END IF;

    SELECT film_id INTO v_film_id FROM film
    WHERE title ILIKE p_film_title
    LIMIT 1;

    IF v_film_id IS NULL THEN
        RAISE EXCEPTION 'No se encontr├│ ninguna pel├¡cula con el t├¡tulo %', p_film_title;
    END IF;

    SELECT store_id INTO v_store_id FROM customer WHERE customer_id = v_customer_id;

    SELECT inventory_id INTO v_inventory_id FROM inventory
    WHERE film_id = v_film_id AND store_id = v_store_id
    AND inventory_in_stock(inventory_id)
    LIMIT 1;

    IF v_inventory_id IS NULL THEN
        RAISE EXCEPTION 'No hay copias disponibles de la pel├¡cula "%" en la tienda del cliente.', p_film_title;
    END IF;

    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
    VALUES (NOW(), v_inventory_id, v_customer_id, v_staff_id)
    RETURNING rental_id INTO v_rental_id;

    RETURN v_rental_id;
END;
$$;


ALTER FUNCTION public.registraralquiler(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_staff_first_name character varying, p_staff_last_name character varying) OWNER TO video;

--
-- Name: registrardevolucion(character varying, character varying, character varying, date); Type: FUNCTION; Schema: public; Owner: video
--

CREATE FUNCTION public.registrardevolucion(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_rental_date date) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
        RAISE EXCEPTION 'Pel├¡cula "%" no encontrada.', p_film_title;
    END IF;

    SELECT r.rental_id INTO v_rental_id FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE i.film_id = v_film_id AND r.customer_id = v_customer_id
    AND r.rental_date::date = p_rental_date
    AND r.return_date IS NULL
    LIMIT 1;

    IF v_rental_id IS NULL THEN
        RAISE EXCEPTION 'No se encontr├│ un alquiler pendiente para la pel├¡cula "%" por el cliente "% %" en la fecha %.', p_film_title, p_customer_first_name, p_customer_last_name, p_rental_date;
    END IF;

    UPDATE rental SET return_date = NOW()
    WHERE rental_id = v_rental_id;
END;
$$;


ALTER FUNCTION public.registrardevolucion(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_rental_date date) OWNER TO video;

--
-- Name: customer_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_customer_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    customer_id integer DEFAULT nextval('public.customer_customer_id_seq'::regclass) NOT NULL,
    store_id smallint NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    email character varying(50),
    address_id smallint NOT NULL,
    activebool boolean DEFAULT true NOT NULL,
    create_date date DEFAULT ('now'::text)::date NOT NULL,
    last_update timestamp without time zone DEFAULT now(),
    active integer
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- Name: rewards_report(integer, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric) RETURNS SETOF public.customer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
rr RECORD;
tmpSQL TEXT;
BEGIN

    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases parameter must be > 0';
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        RAISE EXCEPTION 'Minimum monthly dollar amount purchased parameter must be > $0.00';
    END IF;

    last_month_start := CURRENT_DATE - '3 month'::interval;
    last_month_start := to_date((extract(YEAR FROM last_month_start) || '-' || extract(MONTH FROM last_month_start) || '-01'),'YYYY-MM-DD');
    last_month_end := LAST_DAY(last_month_start);

    /*
    Create a temporary storage area for Customer IDs.
    */
    CREATE TEMPORARY TABLE tmpCustomer (customer_id INTEGER NOT NULL PRIMARY KEY);

    /*
    Find all customers meeting the monthly purchase requirements
    */

    tmpSQL := 'INSERT INTO tmpCustomer (customer_id)
        SELECT p.customer_id
        FROM payment AS p
        WHERE DATE(p.payment_date) BETWEEN '||quote_literal(last_month_start) ||' AND '|| quote_literal(last_month_end) || '
        GROUP BY customer_id
        HAVING SUM(p.amount) > '|| min_dollar_amount_purchased || '
        AND COUNT(customer_id) > ' ||min_monthly_purchases ;

    EXECUTE tmpSQL;

    /*
    Output ALL customer information of matching rewardees.
    Customize output as needed.
    */
    FOR rr IN EXECUTE 'SELECT c.* FROM tmpCustomer AS t INNER JOIN customer AS c ON t.customer_id = c.customer_id' LOOP
        RETURN NEXT rr;
    END LOOP;

    /* Clean up */
    tmpSQL := 'DROP TABLE tmpCustomer';
    EXECUTE tmpSQL;

RETURN;
END
$_$;


ALTER FUNCTION public.rewards_report(min_monthly_purchases integer, min_dollar_amount_purchased numeric) OWNER TO postgres;

--
-- Name: group_concat(text); Type: AGGREGATE; Schema: public; Owner: postgres
--

CREATE AGGREGATE public.group_concat(text) (
    SFUNC = public._group_concat,
    STYPE = text
);


ALTER AGGREGATE public.group_concat(text) OWNER TO postgres;

--
-- Name: dim_address; Type: TABLE; Schema: datamart; Owner: postgres
--

CREATE TABLE datamart.dim_address (
    address_sk integer NOT NULL,
    address_id integer,
    country character varying(50),
    city character varying(50)
);


ALTER TABLE datamart.dim_address OWNER TO postgres;

--
-- Name: dim_address_address_sk_seq; Type: SEQUENCE; Schema: datamart; Owner: postgres
--

CREATE SEQUENCE datamart.dim_address_address_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE datamart.dim_address_address_sk_seq OWNER TO postgres;

--
-- Name: dim_address_address_sk_seq; Type: SEQUENCE OWNED BY; Schema: datamart; Owner: postgres
--

ALTER SEQUENCE datamart.dim_address_address_sk_seq OWNED BY datamart.dim_address.address_sk;


--
-- Name: dim_film; Type: TABLE; Schema: datamart; Owner: postgres
--

CREATE TABLE datamart.dim_film (
    film_sk integer NOT NULL,
    film_id integer,
    title character varying(255),
    categories text,
    language_name character varying(50),
    actors_names text
);


ALTER TABLE datamart.dim_film OWNER TO postgres;

--
-- Name: dim_film_film_sk_seq; Type: SEQUENCE; Schema: datamart; Owner: postgres
--

CREATE SEQUENCE datamart.dim_film_film_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE datamart.dim_film_film_sk_seq OWNER TO postgres;

--
-- Name: dim_film_film_sk_seq; Type: SEQUENCE OWNED BY; Schema: datamart; Owner: postgres
--

ALTER SEQUENCE datamart.dim_film_film_sk_seq OWNED BY datamart.dim_film.film_sk;


--
-- Name: dim_store; Type: TABLE; Schema: datamart; Owner: postgres
--

CREATE TABLE datamart.dim_store (
    store_sk integer NOT NULL,
    store_id integer
);


ALTER TABLE datamart.dim_store OWNER TO postgres;

--
-- Name: dim_store_store_sk_seq; Type: SEQUENCE; Schema: datamart; Owner: postgres
--

CREATE SEQUENCE datamart.dim_store_store_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE datamart.dim_store_store_sk_seq OWNER TO postgres;

--
-- Name: dim_store_store_sk_seq; Type: SEQUENCE OWNED BY; Schema: datamart; Owner: postgres
--

ALTER SEQUENCE datamart.dim_store_store_sk_seq OWNED BY datamart.dim_store.store_sk;


--
-- Name: dim_time; Type: TABLE; Schema: datamart; Owner: postgres
--

CREATE TABLE datamart.dim_time (
    time_sk integer NOT NULL,
    full_date date,
    day integer,
    month integer,
    year integer
);


ALTER TABLE datamart.dim_time OWNER TO postgres;

--
-- Name: dim_time_time_sk_seq; Type: SEQUENCE; Schema: datamart; Owner: postgres
--

CREATE SEQUENCE datamart.dim_time_time_sk_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE datamart.dim_time_time_sk_seq OWNER TO postgres;

--
-- Name: dim_time_time_sk_seq; Type: SEQUENCE OWNED BY; Schema: datamart; Owner: postgres
--

ALTER SEQUENCE datamart.dim_time_time_sk_seq OWNED BY datamart.dim_time.time_sk;


--
-- Name: fact_rents; Type: TABLE; Schema: datamart; Owner: postgres
--

CREATE TABLE datamart.fact_rents (
    address_sk integer NOT NULL,
    film_sk integer NOT NULL,
    store_sk integer NOT NULL,
    time_sk integer NOT NULL,
    rental_count integer DEFAULT 1,
    total_amount numeric(5,2)
);


ALTER TABLE datamart.fact_rents OWNER TO postgres;

--
-- Name: actor_actor_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.actor_actor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.actor_actor_id_seq OWNER TO postgres;

--
-- Name: actor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.actor (
    actor_id integer DEFAULT nextval('public.actor_actor_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.actor OWNER TO postgres;

--
-- Name: category_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.category_category_id_seq OWNER TO postgres;

--
-- Name: category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.category (
    category_id integer DEFAULT nextval('public.category_category_id_seq'::regclass) NOT NULL,
    name character varying(25) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.category OWNER TO postgres;

--
-- Name: film_film_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.film_film_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.film_film_id_seq OWNER TO postgres;

--
-- Name: film; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.film (
    film_id integer DEFAULT nextval('public.film_film_id_seq'::regclass) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    release_year public.year,
    language_id smallint NOT NULL,
    rental_duration smallint DEFAULT 3 NOT NULL,
    rental_rate numeric(4,2) DEFAULT 4.99 NOT NULL,
    length smallint,
    replacement_cost numeric(5,2) DEFAULT 19.99 NOT NULL,
    rating public.mpaa_rating DEFAULT 'G'::public.mpaa_rating,
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    special_features text[],
    fulltext tsvector NOT NULL
);


ALTER TABLE public.film OWNER TO postgres;

--
-- Name: film_actor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.film_actor (
    actor_id smallint NOT NULL,
    film_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.film_actor OWNER TO postgres;

--
-- Name: film_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.film_category (
    film_id smallint NOT NULL,
    category_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.film_category OWNER TO postgres;

--
-- Name: actor_info; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.actor_info AS
 SELECT a.actor_id,
    a.first_name,
    a.last_name,
    public.group_concat(DISTINCT (((c.name)::text || ': '::text) || ( SELECT public.group_concat((f.title)::text) AS group_concat
           FROM ((public.film f
             JOIN public.film_category fc_1 ON ((f.film_id = fc_1.film_id)))
             JOIN public.film_actor fa_1 ON ((f.film_id = fa_1.film_id)))
          WHERE ((fc_1.category_id = c.category_id) AND (fa_1.actor_id = a.actor_id))
          GROUP BY fa_1.actor_id))) AS film_info
   FROM (((public.actor a
     LEFT JOIN public.film_actor fa ON ((a.actor_id = fa.actor_id)))
     LEFT JOIN public.film_category fc ON ((fa.film_id = fc.film_id)))
     LEFT JOIN public.category c ON ((fc.category_id = c.category_id)))
  GROUP BY a.actor_id, a.first_name, a.last_name;


ALTER VIEW public.actor_info OWNER TO postgres;

--
-- Name: address_address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.address_address_id_seq OWNER TO postgres;

--
-- Name: address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.address (
    address_id integer DEFAULT nextval('public.address_address_id_seq'::regclass) NOT NULL,
    address character varying(50) NOT NULL,
    address2 character varying(50),
    district character varying(20) NOT NULL,
    city_id smallint NOT NULL,
    postal_code character varying(10),
    phone character varying(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.address OWNER TO postgres;

--
-- Name: city_city_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.city_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.city_city_id_seq OWNER TO postgres;

--
-- Name: city; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.city (
    city_id integer DEFAULT nextval('public.city_city_id_seq'::regclass) NOT NULL,
    city character varying(50) NOT NULL,
    country_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.city OWNER TO postgres;

--
-- Name: country_country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.country_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.country_country_id_seq OWNER TO postgres;

--
-- Name: country; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country (
    country_id integer DEFAULT nextval('public.country_country_id_seq'::regclass) NOT NULL,
    country character varying(50) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.country OWNER TO postgres;

--
-- Name: customer_list; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.customer_list AS
 SELECT cu.customer_id AS id,
    (((cu.first_name)::text || ' '::text) || (cu.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
        CASE
            WHEN cu.activebool THEN 'active'::text
            ELSE ''::text
        END AS notes,
    cu.store_id AS sid
   FROM (((public.customer cu
     JOIN public.address a ON ((cu.address_id = a.address_id)))
     JOIN public.city ON ((a.city_id = city.city_id)))
     JOIN public.country ON ((city.country_id = country.country_id)));


ALTER VIEW public.customer_list OWNER TO postgres;

--
-- Name: film_list; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    public.group_concat((((actor.first_name)::text || ' '::text) || (actor.last_name)::text)) AS actors
   FROM ((((public.category
     LEFT JOIN public.film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN public.film ON ((film_category.film_id = film.film_id)))
     JOIN public.film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN public.actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;


ALTER VIEW public.film_list OWNER TO postgres;

--
-- Name: inventory_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventory_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_inventory_id_seq OWNER TO postgres;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventory (
    inventory_id integer DEFAULT nextval('public.inventory_inventory_id_seq'::regclass) NOT NULL,
    film_id smallint NOT NULL,
    store_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.inventory OWNER TO postgres;

--
-- Name: language_language_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.language_language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.language_language_id_seq OWNER TO postgres;

--
-- Name: language; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.language (
    language_id integer DEFAULT nextval('public.language_language_id_seq'::regclass) NOT NULL,
    name character(20) NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.language OWNER TO postgres;

--
-- Name: nicer_but_slower_film_list; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.nicer_but_slower_film_list AS
 SELECT film.film_id AS fid,
    film.title,
    film.description,
    category.name AS category,
    film.rental_rate AS price,
    film.length,
    film.rating,
    public.group_concat((((upper("substring"((actor.first_name)::text, 1, 1)) || lower("substring"((actor.first_name)::text, 2))) || upper("substring"((actor.last_name)::text, 1, 1))) || lower("substring"((actor.last_name)::text, 2)))) AS actors
   FROM ((((public.category
     LEFT JOIN public.film_category ON ((category.category_id = film_category.category_id)))
     LEFT JOIN public.film ON ((film_category.film_id = film.film_id)))
     JOIN public.film_actor ON ((film.film_id = film_actor.film_id)))
     JOIN public.actor ON ((film_actor.actor_id = actor.actor_id)))
  GROUP BY film.film_id, film.title, film.description, category.name, film.rental_rate, film.length, film.rating;


ALTER VIEW public.nicer_but_slower_film_list OWNER TO postgres;

--
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_payment_id_seq OWNER TO postgres;

--
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    payment_id integer DEFAULT nextval('public.payment_payment_id_seq'::regclass) NOT NULL,
    customer_id smallint NOT NULL,
    staff_id smallint NOT NULL,
    rental_id integer NOT NULL,
    amount numeric(5,2) NOT NULL,
    payment_date timestamp without time zone NOT NULL
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- Name: rental_rental_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rental_rental_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rental_rental_id_seq OWNER TO postgres;

--
-- Name: rental; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rental (
    rental_id integer DEFAULT nextval('public.rental_rental_id_seq'::regclass) NOT NULL,
    rental_date timestamp without time zone NOT NULL,
    inventory_id integer NOT NULL,
    customer_id smallint NOT NULL,
    return_date timestamp without time zone,
    staff_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.rental OWNER TO postgres;

--
-- Name: sales_by_film_category; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sales_by_film_category AS
 SELECT c.name AS category,
    sum(p.amount) AS total_sales
   FROM (((((public.payment p
     JOIN public.rental r ON ((p.rental_id = r.rental_id)))
     JOIN public.inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN public.film f ON ((i.film_id = f.film_id)))
     JOIN public.film_category fc ON ((f.film_id = fc.film_id)))
     JOIN public.category c ON ((fc.category_id = c.category_id)))
  GROUP BY c.name
  ORDER BY (sum(p.amount)) DESC;


ALTER VIEW public.sales_by_film_category OWNER TO postgres;

--
-- Name: staff_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_staff_id_seq OWNER TO postgres;

--
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    staff_id integer DEFAULT nextval('public.staff_staff_id_seq'::regclass) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45) NOT NULL,
    address_id smallint NOT NULL,
    email character varying(50),
    store_id smallint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    username character varying(16) NOT NULL,
    password character varying(40),
    last_update timestamp without time zone DEFAULT now() NOT NULL,
    picture bytea
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- Name: store_store_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.store_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.store_store_id_seq OWNER TO postgres;

--
-- Name: store; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.store (
    store_id integer DEFAULT nextval('public.store_store_id_seq'::regclass) NOT NULL,
    manager_staff_id smallint NOT NULL,
    address_id smallint NOT NULL,
    last_update timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.store OWNER TO postgres;

--
-- Name: sales_by_store; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sales_by_store AS
 SELECT (((c.city)::text || ','::text) || (cy.country)::text) AS store,
    (((m.first_name)::text || ' '::text) || (m.last_name)::text) AS manager,
    sum(p.amount) AS total_sales
   FROM (((((((public.payment p
     JOIN public.rental r ON ((p.rental_id = r.rental_id)))
     JOIN public.inventory i ON ((r.inventory_id = i.inventory_id)))
     JOIN public.store s ON ((i.store_id = s.store_id)))
     JOIN public.address a ON ((s.address_id = a.address_id)))
     JOIN public.city c ON ((a.city_id = c.city_id)))
     JOIN public.country cy ON ((c.country_id = cy.country_id)))
     JOIN public.staff m ON ((s.manager_staff_id = m.staff_id)))
  GROUP BY cy.country, c.city, s.store_id, m.first_name, m.last_name
  ORDER BY cy.country, c.city;


ALTER VIEW public.sales_by_store OWNER TO postgres;

--
-- Name: staff_list; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.staff_list AS
 SELECT s.staff_id AS id,
    (((s.first_name)::text || ' '::text) || (s.last_name)::text) AS name,
    a.address,
    a.postal_code AS "zip code",
    a.phone,
    city.city,
    country.country,
    s.store_id AS sid
   FROM (((public.staff s
     JOIN public.address a ON ((s.address_id = a.address_id)))
     JOIN public.city ON ((a.city_id = city.city_id)))
     JOIN public.country ON ((city.country_id = country.country_id)));


ALTER VIEW public.staff_list OWNER TO postgres;

--
-- Name: dim_address address_sk; Type: DEFAULT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_address ALTER COLUMN address_sk SET DEFAULT nextval('datamart.dim_address_address_sk_seq'::regclass);


--
-- Name: dim_film film_sk; Type: DEFAULT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_film ALTER COLUMN film_sk SET DEFAULT nextval('datamart.dim_film_film_sk_seq'::regclass);


--
-- Name: dim_store store_sk; Type: DEFAULT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_store ALTER COLUMN store_sk SET DEFAULT nextval('datamart.dim_store_store_sk_seq'::regclass);


--
-- Name: dim_time time_sk; Type: DEFAULT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_time ALTER COLUMN time_sk SET DEFAULT nextval('datamart.dim_time_time_sk_seq'::regclass);


--
-- Name: dim_address dim_address_pkey; Type: CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_address
    ADD CONSTRAINT dim_address_pkey PRIMARY KEY (address_sk);


--
-- Name: dim_film dim_film_pkey; Type: CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_film
    ADD CONSTRAINT dim_film_pkey PRIMARY KEY (film_sk);


--
-- Name: dim_store dim_store_pkey; Type: CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_store
    ADD CONSTRAINT dim_store_pkey PRIMARY KEY (store_sk);


--
-- Name: dim_time dim_time_pkey; Type: CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.dim_time
    ADD CONSTRAINT dim_time_pkey PRIMARY KEY (time_sk);


--
-- Name: fact_rents fact_rents_pkey; Type: CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.fact_rents
    ADD CONSTRAINT fact_rents_pkey PRIMARY KEY (address_sk, film_sk, store_sk, time_sk);


--
-- Name: actor actor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.actor
    ADD CONSTRAINT actor_pkey PRIMARY KEY (actor_id);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (address_id);


--
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (category_id);


--
-- Name: city city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT city_pkey PRIMARY KEY (city_id);


--
-- Name: country country_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country
    ADD CONSTRAINT country_pkey PRIMARY KEY (country_id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customer_id);


--
-- Name: film_actor film_actor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_pkey PRIMARY KEY (actor_id, film_id);


--
-- Name: film_category film_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_pkey PRIMARY KEY (film_id, category_id);


--
-- Name: film film_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film
    ADD CONSTRAINT film_pkey PRIMARY KEY (film_id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (inventory_id);


--
-- Name: language language_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language
    ADD CONSTRAINT language_pkey PRIMARY KEY (language_id);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- Name: rental rental_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_pkey PRIMARY KEY (rental_id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staff_id);


--
-- Name: store store_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_id);


--
-- Name: film_fulltext_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX film_fulltext_idx ON public.film USING gist (fulltext);


--
-- Name: idx_actor_last_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_actor_last_name ON public.actor USING btree (last_name);


--
-- Name: idx_fk_address_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_address_id ON public.customer USING btree (address_id);


--
-- Name: idx_fk_city_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_city_id ON public.address USING btree (city_id);


--
-- Name: idx_fk_country_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_country_id ON public.city USING btree (country_id);


--
-- Name: idx_fk_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_customer_id ON public.payment USING btree (customer_id);


--
-- Name: idx_fk_film_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_film_id ON public.film_actor USING btree (film_id);


--
-- Name: idx_fk_inventory_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_inventory_id ON public.rental USING btree (inventory_id);


--
-- Name: idx_fk_language_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_language_id ON public.film USING btree (language_id);


--
-- Name: idx_fk_rental_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_rental_id ON public.payment USING btree (rental_id);


--
-- Name: idx_fk_staff_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_staff_id ON public.payment USING btree (staff_id);


--
-- Name: idx_fk_store_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fk_store_id ON public.customer USING btree (store_id);


--
-- Name: idx_last_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_last_name ON public.customer USING btree (last_name);


--
-- Name: idx_store_id_film_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_store_id_film_id ON public.inventory USING btree (store_id, film_id);


--
-- Name: idx_title; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_title ON public.film USING btree (title);


--
-- Name: idx_unq_manager_staff_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unq_manager_staff_id ON public.store USING btree (manager_staff_id);


--
-- Name: idx_unq_rental_rental_date_inventory_id_customer_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_unq_rental_rental_date_inventory_id_customer_id ON public.rental USING btree (rental_date, inventory_id, customer_id);


--
-- Name: film film_fulltext_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER film_fulltext_trigger BEFORE INSERT OR UPDATE ON public.film FOR EACH ROW EXECUTE FUNCTION tsvector_update_trigger('fulltext', 'pg_catalog.english', 'title', 'description');


--
-- Name: actor last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.actor FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: address last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.address FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: category last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.category FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: city last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.city FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: country last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.country FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: customer last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.customer FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: film last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: film_actor last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film_actor FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: film_category last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.film_category FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: inventory last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.inventory FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: language last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.language FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: rental last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.rental FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: staff last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: store last_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_updated BEFORE UPDATE ON public.store FOR EACH ROW EXECUTE FUNCTION public.last_updated();


--
-- Name: fact_rents fact_rents_address_sk_fkey; Type: FK CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.fact_rents
    ADD CONSTRAINT fact_rents_address_sk_fkey FOREIGN KEY (address_sk) REFERENCES datamart.dim_address(address_sk);


--
-- Name: fact_rents fact_rents_film_sk_fkey; Type: FK CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.fact_rents
    ADD CONSTRAINT fact_rents_film_sk_fkey FOREIGN KEY (film_sk) REFERENCES datamart.dim_film(film_sk);


--
-- Name: fact_rents fact_rents_store_sk_fkey; Type: FK CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.fact_rents
    ADD CONSTRAINT fact_rents_store_sk_fkey FOREIGN KEY (store_sk) REFERENCES datamart.dim_store(store_sk);


--
-- Name: fact_rents fact_rents_time_sk_fkey; Type: FK CONSTRAINT; Schema: datamart; Owner: postgres
--

ALTER TABLE ONLY datamart.fact_rents
    ADD CONSTRAINT fact_rents_time_sk_fkey FOREIGN KEY (time_sk) REFERENCES datamart.dim_time(time_sk);


--
-- Name: customer customer_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: film_actor film_actor_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.actor(actor_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: film_actor film_actor_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_actor
    ADD CONSTRAINT film_actor_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: film_category film_category_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.category(category_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: film_category film_category_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film_category
    ADD CONSTRAINT film_category_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: film film_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.film
    ADD CONSTRAINT film_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language(language_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: address fk_address_city; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES public.city(city_id);


--
-- Name: city fk_city; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.city
    ADD CONSTRAINT fk_city FOREIGN KEY (country_id) REFERENCES public.country(country_id);


--
-- Name: inventory inventory_film_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_film_id_fkey FOREIGN KEY (film_id) REFERENCES public.film(film_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: payment payment_rental_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental(rental_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: payment payment_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: rental rental_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: rental rental_inventory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_inventory_id_fkey FOREIGN KEY (inventory_id) REFERENCES public.inventory(inventory_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: rental rental_staff_id_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rental
    ADD CONSTRAINT rental_staff_id_key FOREIGN KEY (staff_id) REFERENCES public.staff(staff_id);


--
-- Name: staff staff_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: store store_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_address_id_fkey FOREIGN KEY (address_id) REFERENCES public.address(address_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: store store_manager_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_manager_staff_id_fkey FOREIGN KEY (manager_staff_id) REFERENCES public.staff(staff_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: FUNCTION buscarpelicula(p_titulo_busqueda character varying); Type: ACL; Schema: public; Owner: video
--

REVOKE ALL ON FUNCTION public.buscarpelicula(p_titulo_busqueda character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.buscarpelicula(p_titulo_busqueda character varying) TO "EMP";


--
-- Name: FUNCTION insertarcliente(p_store_id smallint, p_first_name character varying, p_last_name character varying, p_email character varying, p_address character varying, p_address2 character varying, p_district character varying, p_city_id smallint, p_postal_code character varying, p_phone character varying, p_activebool boolean); Type: ACL; Schema: public; Owner: video
--

REVOKE ALL ON FUNCTION public.insertarcliente(p_store_id smallint, p_first_name character varying, p_last_name character varying, p_email character varying, p_address character varying, p_address2 character varying, p_district character varying, p_city_id smallint, p_postal_code character varying, p_phone character varying, p_activebool boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION public.insertarcliente(p_store_id smallint, p_first_name character varying, p_last_name character varying, p_email character varying, p_address character varying, p_address2 character varying, p_district character varying, p_city_id smallint, p_postal_code character varying, p_phone character varying, p_activebool boolean) TO "ADMIN";


--
-- Name: FUNCTION registraralquiler(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_staff_first_name character varying, p_staff_last_name character varying); Type: ACL; Schema: public; Owner: video
--

REVOKE ALL ON FUNCTION public.registraralquiler(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_staff_first_name character varying, p_staff_last_name character varying) FROM PUBLIC;
GRANT ALL ON FUNCTION public.registraralquiler(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_staff_first_name character varying, p_staff_last_name character varying) TO "EMP";


--
-- Name: FUNCTION registrardevolucion(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_rental_date date); Type: ACL; Schema: public; Owner: video
--

REVOKE ALL ON FUNCTION public.registrardevolucion(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_rental_date date) FROM PUBLIC;
GRANT ALL ON FUNCTION public.registrardevolucion(p_film_title character varying, p_customer_first_name character varying, p_customer_last_name character varying, p_rental_date date) TO "EMP";


--
-- Name: SEQUENCE customer_customer_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.customer_customer_id_seq TO video;


--
-- Name: TABLE customer; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.customer TO video;


--
-- Name: SEQUENCE actor_actor_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.actor_actor_id_seq TO video;


--
-- Name: SEQUENCE category_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.category_category_id_seq TO video;


--
-- Name: SEQUENCE film_film_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.film_film_id_seq TO video;


--
-- Name: TABLE film; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.film TO video;


--
-- Name: SEQUENCE address_address_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.address_address_id_seq TO video;


--
-- Name: TABLE address; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.address TO video;


--
-- Name: SEQUENCE city_city_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.city_city_id_seq TO video;


--
-- Name: TABLE city; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.city TO video;


--
-- Name: SEQUENCE country_country_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.country_country_id_seq TO video;


--
-- Name: SEQUENCE inventory_inventory_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.inventory_inventory_id_seq TO video;


--
-- Name: TABLE inventory; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.inventory TO video;


--
-- Name: SEQUENCE language_language_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.language_language_id_seq TO video;


--
-- Name: SEQUENCE payment_payment_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.payment_payment_id_seq TO video;


--
-- Name: SEQUENCE rental_rental_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.rental_rental_id_seq TO video;


--
-- Name: TABLE rental; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.rental TO video;


--
-- Name: SEQUENCE staff_staff_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.staff_staff_id_seq TO video;


--
-- Name: TABLE staff; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.staff TO video;


--
-- Name: SEQUENCE store_store_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT USAGE ON SEQUENCE public.store_store_id_seq TO video;


--
-- PostgreSQL database dump complete
--

\unrestrict Iy5qYjbKQVfJLxYxPrS9WETcymGmZYBc9bgpNeraeEaVmbZkZX0psk4sWty4LW7

