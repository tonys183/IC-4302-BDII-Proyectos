--- Paquete - Operaciones de Modificación ---
CREATE OR REPLACE PACKAGE pkg_modifications AS
    PROCEDURE delete_order(p_order_id in NUMBER);
    PROCEDURE update_order_quantity(p_order_id in NUMBER, new_quantity in NUMBER);

    FUNCTION insert_book (
    p_book_name IN Book.book_name%TYPE,
    p_ISBN IN Book.ISBN%TYPE,
    p_publisher_id IN Book.publisher_id%TYPE
    );

END pkg_modifications;
/

CREATE OR REPLACE PACKAGE BODY pkg_modifications AS

    PROCEDURE delete_order(p_order_id IN NUMBER) IS
        v_status_name Status.status_name%TYPE;
        BEGIN
            SELECT s.status_name
            INTO v_status_name
            FROM CustomerOrder co
            JOIN Status s ON co.status_id = s.status_id
            WHERE co.order_id = p_order_id;

            IF v_status_name != 'Pending' THEN
                DBMS_OUTPUT.PUT_LINE('Cannot delete order with status: ' || v_status_name);
                RETURN;
            END IF;

            DELETE FROM OrderDetail WHERE order_id = p_order_id;
            DELETE FROM CustomerOrder WHERE order_id = p_order_id;

            COMMIT;

            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    DBMS_OUTPUT.PUT_LINE('No order found with ID: ' || p_order_id);
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END delete_order;

    ---
    PROCEDURE update_order_quantity(p_order_id in NUMBER, new_quantity in NUMBER) IS
            v_status_name Status.status_name%TYPE;
    BEGIN
        SELECT s.status_name
        INTO v_status_name
        FROM CustomerOrder co
                 JOIN Status s ON co.status_id = s.status_id
        WHERE co.order_id = p_order_id;

        IF v_status_name != 'Pending' THEN
                        DBMS_OUTPUT.PUT_LINE('Cannot update order with status: ' || v_status_name);
                        RETURN;
        END IF;

        UPDATE OrderDetail SET quantity = new_quantity WHERE order_id = p_order_id;

        COMMIT;

        EXCEPTION
                WHEN NO_DATA_FOUND THEN
                        DBMS_OUTPUT.PUT_LINE('No order found with ID: ' || p_order_id);
                WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END update_order_quantity;


    ---
   FUNCTION insert_book(
    p_book_name IN Book.book_name%TYPE,
    p_ISBN IN Book.ISBN%TYPE,
    p_publisher_id IN Book.publisher_id%TYPE
    ) RETURN Book.book_id%TYPE IS
        v_book_id Book.book_id%TYPE;
    BEGIN
        INSERT INTO Book (book_name, ISBN, publisher_id)
        VALUES (p_book_name, p_ISBN, p_publisher_id)
            RETURNING book_id INTO v_book_id;

        RETURN v_book_id;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('ISBN already exists: ' || p_ISBN);
                RETURN NULL;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error inserting book: ' || SQLERRM);
        RETURN NULL;
    END insert_book;



END pkg_modifications;
/

--- Paquete - Consultas ---
CREATE OR REPLACE PACKAGE pkg_queries AS
    PROCEDURE showBookDetails;
    FUNCTION getOrderCountByUser(user_mail IN VARCHAR2) RETURN NUMBER;
END pkg_queries;
/

CREATE OR REPLACE PACKAGE BODY pkg_queries AS

    PROCEDURE showBookDetails IS
BEGIN
        FOR book IN (
            SELECT b.book_id, b.book_name, b.ISBN, a.author_name, p.publisher_name
            FROM Book b
            LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
            LEFT JOIN Author a ON ba.author_id = a.author_id
            LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
            ORDER BY b.book_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Book ID: ' || book.book_id);
            DBMS_OUTPUT.PUT_LINE('Book Name: ' || book.book_name);
            DBMS_OUTPUT.PUT_LINE('ISBN: ' || book.ISBN);
            DBMS_OUTPUT.PUT_LINE('Author: ' || book.author_name);
            DBMS_OUTPUT.PUT_LINE('Publisher: ' || book.publisher_name);
            DBMS_OUTPUT.PUT_LINE('-----------------------------');
        END LOOP;
END showBookDetails;

    FUNCTION getOrderCountByUser(user_mail IN VARCHAR2) RETURN NUMBER
    IS
    v_order_count NUMBER;

BEGIN
    SELECT COUNT(*)
    INTO v_order_count
    FROM CustomerOrder co
    JOIN Client c ON co.client_id = c.client_id
    WHERE c.email = user_mail;

    RETURN v_order_count;

    EXCEPTION
            WHEN NO_DATA_FOUND THEN
            RETURN 0;
END getOrderCountByUser;

END pkg_queries;
/
