--- Mostrar a los clientes que hayan gastado más de 4000 en supplies ---
SELECT c.first_name, c.last_name1, s.supply_name, od.quantity, od.total_detail FROM OrderDetail od
INNER JOIN Supply s ON od.supply_id = s.supply_id
INNER JOIN CustomerOrder o ON od.order_id = o.order_id
INNER JOIN Client c ON o.client_id = c.client_id
WHERE od.total_detail >= 4000 AND od.supply_id IS NOT NULL;

--- Mostrar a todos los clientes, y los libros que han comprado, pueden ser 0 ---
SELECT c.first_name, c.last_name1, COUNT(od.book_id) AS buyed_books FROM OrderDetail od
RIGHT JOIN CustomerOrder o ON od.order_id = o.order_id AND od.book_id IS NOT NULL
RIGHT JOIN Client c ON o.client_id = c.client_id
GROUP BY c.client_id, c.first_name, c.last_name1;

--- Mostrar todos los libros, y sus ventas totales en orden de mayor a menor ---
SELECT b.book_id, b.book_name, b.ISBN, a.author_name, p.publisher_name, COUNT(od.book_id) AS selled_books FROM Book b
LEFT JOIN OrderDetail od ON b.book_id = od.book_id
LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
LEFT JOIN Author a ON ba.author_id = a.author_id
LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
GROUP BY b.book_id, b.book_name, b.ISBN, a.author_name, p.publisher_name
ORDER BY selled_books DESC;



--- *** PROCEDIMEINTOS *** ---
--- Mostrar la venta de un libro en especifico ---
CREATE OR REPLACE PROCEDURE findSoldBook(p_ISBN_name IN VARCHAR2)
IS
    v_book_id Book.book_id%TYPE;
    v_book_name Book.book_name%TYPE;
    v_ISBN Book.ISBN%TYPE;
    v_author_name Author.author_name%TYPE;
    v_publisher_name Publisher.publisher_name%TYPE;
    v_selled_books NUMBER;

BEGIN

    SELECT b.book_id, b.book_name, b.ISBN, a.author_name, p.publisher_name,
    COUNT(od.book_id) AS selled_books
    INTO v_book_id, v_book_name, v_ISBN, v_author_name, v_publisher_name, v_selled_books
    FROM Book b
    LEFT JOIN OrderDetail od ON b.book_id = od.book_id
    LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
    LEFT JOIN Author a ON ba.author_id = a.author_id
    LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
    WHERE b.ISBN = p_ISBN_name
    GROUP BY b.book_id, b.book_name, b.ISBN, a.author_name, p.publisher_name;

    DBMS_OUTPUT.PUT_LINE('Book ID: ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('Book Name: ' || v_book_name);
    DBMS_OUTPUT.PUT_LINE('ISBN: ' || v_ISBN);
    DBMS_OUTPUT.PUT_LINE('Author: ' || v_author_name);
    DBMS_OUTPUT.PUT_LINE('Publisher: ' || v_publisher_name);
    DBMS_OUTPUT.PUT_LINE('Books Sold: ' || v_selled_books);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No book found with ISBN: ' || p_ISBN_name);
    WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Multiple books found with the same ISBN');
    WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END findSoldBook;
/


---
CREATE OR REPLACE PROCEDURE findClientByName(p_full_name IN VARCHAR2)
IS
    v_client_id Client.client_id%TYPE;
    v_first_name Client.first_name%TYPE;
    v_last_name1 Client.last_name1%TYPE;
    v_last_name2 Client.last_name2%TYPE;
    v_buyed_books NUMBER;
BEGIN

    SELECT c.client_id, c.first_name, c.last_name1, c.last_name2,
    COUNT(od.book_id) AS buyed_books
    INTO v_client_id, v_first_name, v_last_name1, v_last_name2, v_buyed_books
    FROM Client c
    LEFT JOIN CustomerOrder o ON c.client_id = o.client_id
    LEFT JOIN OrderDetail od ON o.order_id = od.order_id
    WHERE (c.first_name || ' ' || c.last_name1 || ' ' || NVL(c.last_name2, '')) LIKE '%' || p_full_name || '%'
    GROUP BY c.client_id, c.first_name, c.last_name1, c.last_name2;

    DBMS_OUTPUT.PUT_LINE('Client ID: ' || v_client_id);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_first_name || ' ' || v_last_name1 || ' ' || NVL(v_last_name2, ''));
    DBMS_OUTPUT.PUT_LINE('Books Purchased: ' || v_buyed_books);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No client found with name containing: ' || p_full_name);
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('Multiple clients found with similar names');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END findClientByName;
/