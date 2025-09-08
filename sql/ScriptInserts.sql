--- Insert Client ---
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Gael', 'Ruiz', 'Ñurinda', '88881234', 'gael.ruiz@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Anthony', 'Segura', 'Paniagua', '88882345', 'anthony.segura@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Saúl', 'Pacheco', 'Cubillo', '88883456', 'saul.pacheco@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Lucía', 'García', 'Vargas', '88884567', 'lucia.garcia@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Miguel', 'Hernández', 'Pacheco', '88885678', 'miguel.hernandez@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Sofía', 'Cruz', 'Rojas', '88886789', 'sofia.cruz@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Diego', 'Jiménez', 'Flores', '88887890', 'diego.jimenez@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('María', 'Ortiz', 'Castro', '88888901', 'maria.ortiz@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Fernando', 'Ramírez', 'Soto', '88889012', 'fernando.ramirez@email.com');
INSERT INTO Client (first_name, last_name1, last_name2, phone_number, email) VALUES ('Paola', 'Vega', 'Méndez', '88890123', 'paola.vega@email.com');


--- Insert User ---
INSERT INTO Library_User (username, password) VALUES ('tonyseg', '$2a$10$ONqRkS.SNJMr1AERLIHlguAMn0.AvvFipl9f8IcZ2xytlP50S4B5S');


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
INSERT INTO Author (first_name, last_name1, last_name2) VALUES ('Jorge Luis', 'Borges', NULL);

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


--- Test ---
INSERT INTO Book (book_name, ISBN, publisher_id) VALUES ('Cien Años de Soledad', '9780307474728', 1);
INSERT INTO Book_Author (book_id, author_id) VALUES (1, 1);
INSERT INTO Genre_Book (genre_id, book_id) VALUES (1, 1);

COMMIT;