/*=== PACKAGE MODIFICATIONS ===*/
    CREATE OR REPLACE PACKAGE pkg_modifications AS
    PROCEDURE delete_order(p_order_id in NUMBER);
    PROCEDURE update_order_quantity(p_order_id in NUMBER, new_quantity in NUMBER);
    PROCEDURE add_author_to_book(
        p_first_name IN VARCHAR2,
        p_last_name1 IN VARCHAR2,
        p_last_name2 IN VARCHAR2,
        p_book_name IN VARCHAR2
       );
    PROCEDURE add_genre_to_book(
        p_genre_name IN VARCHAR2,
        p_book_name IN VARCHAR2
    );
    FUNCTION insert_book (
        p_book_name IN Book.book_name%TYPE,
        p_ISBN IN Book.ISBN%TYPE,
        p_publisher_name IN publisher.publisher_name%TYPE
    ) RETURN Book.book_id%TYPE;
END pkg_modifications;
/

CREATE OR REPLACE PACKAGE BODY pkg_modifications AS

    --- Delete order ---
    PROCEDURE delete_order(p_order_id IN NUMBER) IS
        v_status_name Status.status_name%TYPE;
    BEGIN
    SELECT s.status_name INTO v_status_name FROM CustomerOrder co
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

    --- Update order quantity ---
    PROCEDURE update_order_quantity(p_order_id in NUMBER, new_quantity in NUMBER) IS
            v_status_name Status.status_name%TYPE;
    BEGIN
    SELECT s.status_name
    INTO v_status_name FROM CustomerOrder co
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

    --- Insert book ---
    FUNCTION insert_book(
        p_book_name       IN Book.book_name%TYPE,
        p_ISBN            IN Book.ISBN%TYPE,
        p_publisher_name  IN Publisher.publisher_name%TYPE
    ) RETURN Book.book_id%TYPE IS
        v_book_id       Book.book_id%TYPE;
        v_publisher_id  Publisher.publisher_id%TYPE;
    BEGIN
        BEGIN
            SELECT publisher_id
            INTO v_publisher_id
            FROM Publisher
            WHERE publisher_name = p_publisher_name;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Si no existe, lo insertamos
                INSERT INTO Publisher (publisher_name)
                VALUES (p_publisher_name)
                RETURNING publisher_id INTO v_publisher_id;
                DBMS_OUTPUT.PUT_LINE('Nuevo publisher insertado: ' || p_publisher_name);
        END;

        INSERT INTO Book (book_name, ISBN, publisher_id)
        VALUES (p_book_name, p_ISBN, v_publisher_id)
        RETURNING book_id INTO v_book_id;
        RETURN v_book_id;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('ISBN ya existe: ' || p_ISBN);
        RETURN NULL;
        WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error insertando libro: ' || SQLERRM);
        RETURN NULL;
    END insert_book;


    --- Link Author to Book ---
    PROCEDURE add_author_to_book(
        p_first_name IN VARCHAR2,
        p_last_name1 IN VARCHAR2,
        p_last_name2 IN VARCHAR2,
        p_book_name IN VARCHAR2)
        IS
        v_author_id Author.author_id%TYPE;
        v_book_id Book.book_id%TYPE;
    BEGIN
        SELECT book_id INTO v_book_id FROM Book
        WHERE book_name = p_book_name;

        BEGIN
        SELECT author_id INTO v_author_id FROM Author
        WHERE first_name = p_first_name AND last_name1 = p_last_name1
        AND (last_name2 = p_last_name2 OR (last_name2 IS NULL AND p_last_name2 IS NULL));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO Author (first_name, last_name1, last_name2)
                VALUES (p_first_name, p_last_name1, p_last_name2)
                RETURNING author_id INTO v_author_id;
        END;

        BEGIN
        INSERT INTO Book_Author (book_id, author_id)
        VALUES (v_book_id, v_author_id);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END;

    --- Link Genre to Book ---
    PROCEDURE add_genre_to_book(
        p_genre_name IN VARCHAR2,
        p_book_name IN VARCHAR2
    )
    IS
        v_genre_id Genre.genre_id%TYPE;
        v_book_id Book.book_id%TYPE;
    BEGIN
        SELECT book_id INTO v_book_id FROM Book
        WHERE book_name = p_book_name;

        BEGIN
        SELECT genre_id INTO v_genre_id FROM Genre
        WHERE genre_name = p_genre_name;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO Genre (genre_name) VALUES (p_genre_name)
                RETURNING genre_id INTO v_genre_id;
        END;
        BEGIN
        INSERT INTO Genre_Book (genre_id, book_id)
        VALUES (v_genre_id, v_book_id);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN NULL;
        END;
    END;

    --- Create customer order ---
    PROCEDURE create_customer_order(
        p_client_id IN Client.client_id%TYPE,
        p_status_name IN Status.status_name%TYPE,
        p_order_date IN DATE DEFAULT SYSDATE,
        p_order_id OUT CustomerOrder.order_id%TYPE
    )
    IS
        v_status_id Status.status_id%TYPE;
    BEGIN
        SELECT status_id INTO v_status_id FROM Status
        WHERE status_name = p_status_name;

        INSERT INTO CustomerOrder (order_date, client_id, status_id)
        VALUES (p_order_date, p_client_id, v_status_id)
        RETURNING order_id INTO p_order_id;

        COMMIT;
    END;
END pkg_modifications;
/


/*=== PACKAGE QUERIES ===*/
CREATE OR REPLACE PACKAGE pkg_queries AS
    PROCEDURE showBookDetails;
    FUNCTION getOrderCountByUser(user_mail IN VARCHAR2) RETURN NUMBER;
END pkg_queries;
/

CREATE OR REPLACE PACKAGE BODY pkg_queries AS

    --- Show book details
    PROCEDURE showBookDetails IS
    BEGIN
        FOR book IN (
            SELECT b.book_id, b.book_name, b.ISBN, a.first_name, a.last_name1, a.last_name2, p.publisher_name
            FROM Book b
            LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
            LEFT JOIN Author a ON ba.author_id = a.author_id
            LEFT JOIN Publisher p ON b.publisher_id = p.publisher_id
            ORDER BY b.book_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('-------------------------------------');
            DBMS_OUTPUT.PUT_LINE('ID        | ' || book.book_id);
            DBMS_OUTPUT.PUT_LINE('Libro     | ' || book.book_name);
            DBMS_OUTPUT.PUT_LINE('ISBN      | ' || book.ISBN);
            DBMS_OUTPUT.PUT_LINE('Autor     | ' || book.first_name || ' ' || book.last_name1 || ' ' || NVL(book.last_name2, ''));
            DBMS_OUTPUT.PUT_LINE('Editorial | ' || book.publisher_name);
            DBMS_OUTPUT.PUT_LINE('-------------------------------------');
        END LOOP;
    END showBookDetails;

    --- Get order count by user email ---
    FUNCTION getOrderCountByUser(user_mail IN VARCHAR2) RETURN NUMBER
    IS
    v_order_count NUMBER;

    BEGIN
        SELECT COUNT(*) INTO v_order_count FROM CustomerOrder co
        JOIN Client c ON co.client_id = c.client_id
        WHERE c.email = user_mail;
        RETURN v_order_count;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END getOrderCountByUser;

END pkg_queries;
/