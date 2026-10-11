REVOKE "EMP" FROM "ADMIN";
DROP USER IF EXISTS empleado1;
DROP USER IF EXISTS administrador1;
DROP OWNED BY "ADMIN", "EMP", video;
DROP ROLE IF EXISTS "ADMIN";
DROP ROLE IF EXISTS "EMP";
DROP ROLE IF EXISTS video;

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