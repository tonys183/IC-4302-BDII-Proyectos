--- Trigger Delete Book Cascade - CustomerOrder & OrderDetail ---
CREATE OR REPLACE TRIGGER trg_delete_book_cascade
    AFTER DELETE ON Book
    FOR EACH ROW
DECLARE
BEGIN
    DELETE FROM OrderDetail
    WHERE book_id = :OLD.book_id;

    DELETE FROM CustomerOrder co
    WHERE NOT EXISTS (
        SELECT 1 FROM OrderDetail od
        WHERE od.order_id = co.order_id
    );
END;
/

--- Trigger CustomerOrder - OrderDetail ---
CREATE OR REPLACE TRIGGER trg_customer_order_date
    BEFORE INSERT ON CustomerOrder
    FOR EACH ROW
BEGIN
    IF :NEW.order_date IS NULL THEN
        :NEW.order_date := SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica';
    END IF;
END;
/

--- Trigger Date - OrderDetail ---
CREATE OR REPLACE TRIGGER trg_order_detail_date
    BEFORE INSERT ON OrderDetail
    FOR EACH ROW
BEGIN
    IF :NEW.date_detail IS NULL THEN
        :NEW.date_detail := SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica';
    END IF;
END;
/

--- Trigger Status - CustomerOrder ---
CREATE OR REPLACE TRIGGER trg_customer_order_status
    BEFORE INSERT ON CustomerOrder
    FOR EACH ROW
BEGIN
    IF :NEW.status_id IS NULL THEN
        :NEW.status_id := 2;
    END IF;
END;
/

--- Trigger Stock - OrderDetail ---
CREATE OR REPLACE TRIGGER trg_order_detail_stock_insert
    BEFORE INSERT ON OrderDetail
    FOR EACH ROW
DECLARE
    v_current_stock NUMBER;
    v_new_stock NUMBER;
BEGIN
    IF :NEW.supply_id IS NOT NULL THEN
        SELECT stock INTO v_current_stock FROM Supply 
        WHERE supply_id = :NEW.supply_id;
        
        IF v_current_stock < :NEW.quantity THEN
            RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente.');
        END IF;
        
        v_new_stock := v_current_stock - :NEW.quantity;
        
        UPDATE Supply SET stock = v_new_stock 
        WHERE supply_id = :NEW.supply_id;

        IF v_new_stock = 0 THEN
            NULL;
        END IF;
    END IF;
END;
/

--- Trigger Stock Update - OrderDetail ---
CREATE OR REPLACE TRIGGER trg_order_detail_stock_update
    BEFORE UPDATE OF quantity ON OrderDetail
    FOR EACH ROW
DECLARE
    v_current_stock NUMBER;
    v_stock_difference NUMBER;
    v_new_stock NUMBER;
BEGIN
    IF :NEW.supply_id IS NOT NULL THEN
        SELECT stock INTO v_current_stock FROM Supply 
        WHERE supply_id = :NEW.supply_id;
        
        v_stock_difference := :NEW.quantity - :OLD.quantity;
        
        IF v_stock_difference > 0 THEN
            IF v_current_stock < v_stock_difference THEN
                RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente.');
            END IF;
        END IF;
        
        v_new_stock := v_current_stock - v_stock_difference;
        
        UPDATE Supply SET stock = v_new_stock 
        WHERE supply_id = :NEW.supply_id;
        
        IF v_new_stock = 0 THEN
            NULL;
        END IF;
    END IF;
END;
/

--- Trigger Log Quantity Update - OrderDetail ---
CREATE OR REPLACE TRIGGER trg_log_order_quantity
    AFTER UPDATE OF quantity ON OrderDetail
    FOR EACH ROW
DECLARE
    v_admin_user_id NUMBER;
BEGIN
    SELECT admin_user_id INTO v_admin_user_id FROM Temp_Admin_Session
    WHERE created_date > SYSDATE - 1/24 AND ROWNUM = 1;
    
    INSERT INTO Log_Table (
        user_id,
        order_id,
        action,
        action_date,
        current_value,
        previous_value
    )
    VALUES (
        v_admin_user_id,
        :NEW.order_id,
        'ADMIN UPDATE ORDER QUANTITY',
        SYSTIMESTAMP AT TIME ZONE 'America/Costa_Rica',
        :NEW.quantity,
        :OLD.quantity
    );
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
    WHEN OTHERS THEN
        NULL;
END;
/