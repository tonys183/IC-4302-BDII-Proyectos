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
INSERT INTO Library_User (username, password) VALUES ('tonyseg', '$2a$10$yHD/RKGZIxAODSVK.RgREuhkt3DJZLgptbEZ3FxHwiat.VR9caJE2');


--- Test ---
INSERT INTO Publisher (publisher_name)
VALUES ('Penguin Books');

INSERT INTO Book (book_name, ISBN, publisher_id)
VALUES ('Cien Años de Soledad', '9780307474728', 1);

INSERT INTO Author (author_name)
VALUES ('Gabriel García Márquez');

INSERT INTO Book_Author (book_id, author_id)
VALUES (1, 1);

INSERT INTO Genre (genre_name)
VALUES ('Realismo Mágico');

INSERT INTO Genre_Book (genre_id, book_id)
VALUES (1, 1);
