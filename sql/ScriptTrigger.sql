CREATE OR REPLACE TRIGGER trg_log_order_quantity
    AFTER UPDATE OF quantity ON OrderDetail
    FOR EACH ROW
        DECLARE
            v_user_id NUMBER;
        BEGIN
        v_user_id := SYS_CONTEXT('USERENV', 'SESSION_USER');
        INSERT INTO Log_Table (user_id, action, action_date, current_value, previous_value)
        VALUES (v_user_id, 'UPDATE ORDER QUANTITY', SYSDATE, :NEW.quantity, :OLD.quantity);
    END;
/
