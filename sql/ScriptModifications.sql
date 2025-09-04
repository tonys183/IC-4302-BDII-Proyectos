---
CREATE OR REPLACE PROCEDURE delete_order(p_order_id IN NUMBER) IS
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

/

---
CREATE OR REPLACE FUNCTION insert_book(
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
/