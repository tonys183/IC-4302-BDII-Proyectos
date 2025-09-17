/*=== ENTIDADES FUERTES ===*/
--- Insert User ---
INSERT INTO Library_User (username, password, role) VALUES ('gael.ruiz', '$2a$10$uUFd4xKh3d51UYG7tEQ/ues7TWdXhXUOpIzr14olteK/89kcEKYci', 'ADMIN');
INSERT INTO Library_User (username, password, role) VALUES ('anthony.segura', '$2a$10$ONqRkS.SNJMr1AERLIHlguAMn0.AvvFipl9f8IcZ2xytlP50S4B5S', 'ADMIN');
INSERT INTO Library_User (username, password, role) VALUES ('saul.pacheco', '$2a$10$KvycGTnb4KNrLoTBjOrmWeXQY/a2pcxEaci8TZK/OjnbmZDmUc1si', 'ADMIN');
INSERT INTO Library_User (username, password, role) VALUES ('lucia.garcia', '$2a$10$8YDkxBE52yG133hydXg99O4Xxf4ZkBlKlyDWIDsOV.NE8PNVW0eZq', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('miguel.hernandez', '$2a$10$WFXaeby92XuJqAeTjHGkkumRwMkMYSXZLPcCWX9EUtPfsWZb7cIX.', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('sofia.cruz', '$2a$10$paNFsNz32hEjXZX/MHG0yeRAkpuVvOuX6FSqkTxeRf30DQD98qAv.', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('diego.jimenez', '$2a$10$SQ/x95FeYRgLQ.yBgTL31OZshNWZLKKSTog6g5504tVVjptokxBbi', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('maria.ortiz', '$2a$10$YA/a7FdcyGOuq6XNP/ddzOcEE4JzwA1cRWSajADzRFRN1TQP5O7N2', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('fernando.ramirez', '$2a$10$h.jVQairCGcjFNoevwXq.ewzzyyL53GGUZvBLoIKrd08yp93Q/CS.', 'CLIENT');
INSERT INTO Library_User (username, password, role) VALUES ('paola.vega', '$2a$10$Avy/EEvA5eRO81Ie0MxgROTn0DDNYCNUaNpkUNbeP65GrLbH46RjC', 'CLIENT');

--- Insert Client ---
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Gael', 'Ruiz', 'Ñurinda', '88881234', 'gael.ruiz@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'gael.ruiz'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Anthony', 'Segura', 'Paniagua', '88882345', 'anthony.segura@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'anthony.segura'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Saúl', 'Pacheco', 'Cubillo', '88883456', 'saul.pacheco@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'saul.pacheco'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Lucía', 'García', 'Vargas', '88884567', 'lucia.garcia@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'lucia.garcia'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Miguel', 'Hernández', 'Pacheco', '88885678', 'miguel.hernandez@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'miguel.hernandez'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Sofía', 'Cruz', 'Rojas', '88886789', 'sofia.cruz@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'sofia.cruz'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Diego', 'Jiménez', 'Flores', '88887890', 'diego.jimenez@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'diego.jimenez'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('María', 'Ortiz', 'Castro', '88888901', 'maria.ortiz@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'maria.ortiz'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Fernando', 'Ramírez', 'Soto', '88889012', 'fernando.ramirez@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'fernando.ramirez'));
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email, user_id) VALUES ('Paola', 'Vega', 'Méndez', '88890123', 'paola.vega@gmail.com', (SELECT user_id FROM Library_User WHERE username = 'paola.vega'));

--- Insert Publisher ---
INSERT INTO Publisher (publisher_name) VALUES ('Penguin Books');
INSERT INTO Publisher (publisher_name) VALUES ('HarperCollins');
INSERT INTO Publisher (publisher_name) VALUES ('Random House');
INSERT INTO Publisher (publisher_name) VALUES ('Alfaguara');
INSERT INTO Publisher (publisher_name) VALUES ('Vintage Español');
INSERT INTO Publisher (publisher_name) VALUES ('Editorial Planeta');
INSERT INTO Publisher (publisher_name) VALUES ('Bloomsbury');
INSERT INTO Publisher (publisher_name) VALUES ('Seix Barral');
INSERT INTO Publisher (publisher_name) VALUES ('Knopf Doubleday');
INSERT INTO Publisher (publisher_name) VALUES ('Debolsillo');

--- Insert Author ---
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Gabriel', 'García', 'Márquez');
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('George', 'Orwell', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Miguel', 'de Cervantes', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Carlos', 'Ruiz', 'Zafón');
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Julio', 'Cortázar', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('J.K.', 'Rowling', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Juan', 'Rulfo', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Jorge Luis', 'Borges', NULL);
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Mario', 'Vargas', 'Llosa');
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Isabel', 'Allende', NULL);

--- Insert Genre ---
INSERT INTO Genre (genre_name) VALUES ('Realismo Mágico');
INSERT INTO Genre (genre_name) VALUES ('Distopía');
INSERT INTO Genre (genre_name) VALUES ('Clásico');
INSERT INTO Genre (genre_name) VALUES ('Misterio');
INSERT INTO Genre (genre_name) VALUES ('Romance');
INSERT INTO Genre (genre_name) VALUES ('Experimental');
INSERT INTO Genre (genre_name) VALUES ('Fantasía');
INSERT INTO Genre (genre_name) VALUES ('Realismo');
INSERT INTO Genre (genre_name) VALUES ('Cuento');
INSERT INTO Genre (genre_name) VALUES ('Novela Social');
INSERT INTO Genre (genre_name) VALUES ('Metaficción');

--- Insert Supplies ---
INSERT INTO Supply (supply_name, stock) VALUES ('Cuadernos', 50);
INSERT INTO Supply (supply_name, stock) VALUES ('Lápices', 100);
INSERT INTO Supply (supply_name, stock) VALUES ('Borradores', 75);
INSERT INTO Supply (supply_name, stock) VALUES ('Marcadores', 60);
INSERT INTO Supply (supply_name, stock) VALUES ('Resaltadores', 40);
INSERT INTO Supply (supply_name, stock) VALUES ('Carpetas', 30);
INSERT INTO Supply (supply_name, stock) VALUES ('Reglas', 80);
INSERT INTO Supply (supply_name, stock) VALUES ('Tijeras', 25);
INSERT INTO Supply (supply_name, stock) VALUES ('Pegamento', 45);
INSERT INTO Supply (supply_name, stock) VALUES ('Colores', 90);

--- Insert Status ---
INSERT INTO Status (status_name) VALUES ('Completado');
INSERT INTO Status (status_name) VALUES ('Pendiente');
INSERT INTO Status (status_name) VALUES ('Cancelado');

--- Insert ServiceType ---
INSERT INTO ServiceType (type_name) VALUES ('Fotocopiado');
INSERT INTO ServiceType (type_name) VALUES ('Impresión');
INSERT INTO ServiceType (type_name) VALUES ('Encuadernación');
INSERT INTO ServiceType (type_name) VALUES ('Entrega a domicilio');
INSERT INTO ServiceType (type_name) VALUES ('Reserva de productos');

--- Insert Service ---
BEGIN
    DECLARE
    temp Service.service_id%TYPE;
    BEGIN
    temp := pkg_modifications.insert_service('Fotocopiado blanco y negro', 'Fotocopiado');
    temp := pkg_modifications.insert_service('Fotocopiado a color', 'Fotocopiado');
    temp := pkg_modifications.insert_service('Impresión blanco y negro', 'Impresión');
    temp := pkg_modifications.insert_service('Impresión a color', 'Impresión');
    temp := pkg_modifications.insert_service('Encuadernación térmica', 'Encuadernación');
    temp := pkg_modifications.insert_service('Entrega local', 'Entrega a domicilio');
    temp := pkg_modifications.insert_service('Entrega nacional', 'Entrega a domicilio');
    temp := pkg_modifications.insert_service('Reserva de libros', 'Reserva de productos');
    temp := pkg_modifications.insert_service('Reserva de útiles escolares', 'Reserva de productos');
    END;
END;

--- Insert Book ---
BEGIN
    DECLARE
        temp Book.book_id%TYPE;
    BEGIN
        temp := pkg_modifications.insert_book('1984', '9780451524935', 'Signet Classics');
        temp := pkg_modifications.insert_book('Don Quijote de la Mancha', '9788420412146', 'Alfaguara');
        temp := pkg_modifications.insert_book('El Amor en los Tiempos del Cólera', '9780307389732', 'Vintage Español');
        temp := pkg_modifications.insert_book('Harry Potter y la Piedra Filosofal', '9780747532743', 'Bloomsbury');
        temp := pkg_modifications.insert_book('Pedro Páramo', '9788437600468', 'Ediciones Era');
        temp := pkg_modifications.insert_book('La Sombra del Viento', '9788408172177', 'Planeta');
        temp := pkg_modifications.insert_book('Ficciones', '9780679410430', 'Knopf');
        temp := pkg_modifications.insert_book('La Ciudad y los Perros', '9788420437484', 'Seix Barral');
        temp := pkg_modifications.insert_book('El Aleph', '9788420633121', 'Debolsillo');
        temp := pkg_modifications.insert_book('Cien Años de Soledad', '9780307474728', 'Editorial Sudamericana');
    END;
END;

BEGIN
    --- Link Authors to Books ---
    pkg_modifications.add_author_to_book('George', 'Orwell', NULL, '1984');
    pkg_modifications.add_author_to_book('Miguel', 'de Cervantes', NULL, 'Don Quijote de la Mancha');
    pkg_modifications.add_author_to_book('Carlos', 'Ruiz', 'Zafón', 'La Sombra del Viento');
    pkg_modifications.add_author_to_book('Gabriel', 'García', 'Márquez', 'El Amor en los Tiempos del Cólera');
    pkg_modifications.add_author_to_book('J.K.', 'Rowling', NULL, 'Harry Potter y la Piedra Filosofal');
    pkg_modifications.add_author_to_book('Juan', 'Rulfo', NULL, 'Pedro Páramo');
    pkg_modifications.add_author_to_book('Jorge', 'Luis', 'Borges', 'Ficciones');
    pkg_modifications.add_author_to_book('Mario', 'Vargas', 'Llosa', 'La Ciudad y los Perros');
    pkg_modifications.add_author_to_book('Jorge', 'Luis', 'Borges', 'El Aleph');
    pkg_modifications.add_author_to_book('Gabriel', 'García', 'Márquez', 'Cien Años de Soledad');

    --- Link Genres to Books ---
    pkg_modifications.add_genre_to_book('Distopía', '1984');
    pkg_modifications.add_genre_to_book('Clásico', 'Don Quijote de la Mancha');
    pkg_modifications.add_genre_to_book('Misterio', 'La Sombra del Viento');
    pkg_modifications.add_genre_to_book('Romance', 'El Amor en los Tiempos del Cólera');
    pkg_modifications.add_genre_to_book('Clásico', 'El Amor en los Tiempos del Cólera');
    pkg_modifications.add_genre_to_book('Fantasía', 'Harry Potter y la Piedra Filosofal');
    pkg_modifications.add_genre_to_book('Clásico', 'Pedro Páramo');
    pkg_modifications.add_genre_to_book('Realismo', 'Pedro Páramo');
    pkg_modifications.add_genre_to_book('Metaficción', 'Ficciones');
    pkg_modifications.add_genre_to_book('Cuento', 'Ficciones');
    pkg_modifications.add_genre_to_book('Novela Social', 'La Ciudad y los Perros');
    pkg_modifications.add_genre_to_book('Metaficción', 'El Aleph');
    pkg_modifications.add_genre_to_book('Cuento', 'El Aleph');
    pkg_modifications.add_genre_to_book('Realismo Mágico', 'Cien Años de Soledad');
END;


/*=== TABLAS TRANSCACIONALES ===*/
--- Insert CustomerOrder ---
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-01','YYYY-MM-DD'), 1, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-02','YYYY-MM-DD'), 2, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-03','YYYY-MM-DD'), 3, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-04','YYYY-MM-DD'), 4, 3);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-05','YYYY-MM-DD'), 5, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-06','YYYY-MM-DD'), 6, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-07','YYYY-MM-DD'), 7, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-08','YYYY-MM-DD'), 8, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-09','YYYY-MM-DD'), 9, 3);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-10','YYYY-MM-DD'), 10, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-11','YYYY-MM-DD'), 1, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-12','YYYY-MM-DD'), 2, 3);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-13','YYYY-MM-DD'), 3, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-14','YYYY-MM-DD'), 4, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-15','YYYY-MM-DD'), 5, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-16','YYYY-MM-DD'), 6, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-17','YYYY-MM-DD'), 7, 3);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-18','YYYY-MM-DD'), 8, 1);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-19','YYYY-MM-DD'), 9, 2);
INSERT INTO CustomerOrder (order_date, client_id, status_id) VALUES (TO_DATE('2025-09-20','YYYY-MM-DD'), 10, 3);

--- Insert OrderDetail ---
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (1, 1, 1, 15.50, TO_DATE('2025-09-01','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (1, 2, 5, 0.50, TO_DATE('2025-09-01','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (2, 3, 1, 20.00, TO_DATE('2025-09-02','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (3, 5, 1, 20.00, TO_DATE('2025-09-03','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, service_id, quantity, unit_price, date_detail) VALUES (3, 3, 1, 5.00, TO_DATE('2025-09-03','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (4, 1, 3, 1.50, TO_DATE('2025-09-04','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (4, 5, 2, 2.00, TO_DATE('2025-09-04','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (5, 10, 1, 18.00, TO_DATE('2025-09-05','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (6, 3, 4, 0.75, TO_DATE('2025-09-06','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, service_id, quantity, unit_price, date_detail) VALUES (7, 4, 1, 10.00, TO_DATE('2025-09-07','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (8, 2, 1, 25.00, TO_DATE('2025-09-08','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (9, 6, 2, 3.00, TO_DATE('2025-09-09','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (10, 4, 1, 16.50, TO_DATE('2025-09-10','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, service_id, quantity, unit_price, date_detail) VALUES (11, 5, 2, 2.00, TO_DATE('2025-09-11','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (12, 3, 1, 22.00, TO_DATE('2025-09-12','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (13, 4, 3, 1.50, TO_DATE('2025-09-13','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (14, 6, 1, 19.00, TO_DATE('2025-09-14','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (15, 7, 2, 1.00, TO_DATE('2025-09-15','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (16, 11, 1, 21.00, TO_DATE('2025-09-16','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, service_id, quantity, unit_price, date_detail) VALUES (17, 2, 1, 0.50, TO_DATE('2025-09-17','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (18, 9, 1, 14.00, TO_DATE('2025-09-18','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, supply_id, quantity, unit_price, date_detail) VALUES (19, 8, 1, 2.50, TO_DATE('2025-09-19','YYYY-MM-DD'));
INSERT INTO OrderDetail (order_id, book_id, quantity, unit_price, date_detail) VALUES (20, 8, 2, 17.00, TO_DATE('2025-09-20','YYYY-MM-DD'));

COMMIT;