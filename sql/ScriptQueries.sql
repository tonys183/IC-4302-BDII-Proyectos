---
CREATE OR REPLACE PROCEDURE showBookDetails() IS
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
    END;
/

---
CREATE OR REPLACE FUNCTION getOrderCountByUser(user_mail IN VARCHAR2)
RETURN NUMBER
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
END;
/