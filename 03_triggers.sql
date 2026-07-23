-- ============================================================
-- 03_triggers.sql
-- Triggers for the Supply Chain / Order Management System.
-- Run after 01_tables.sql and 02_procedures.sql.
-- ============================================================

-- ----------------------------------------------------------
-- Auto-assign the first available driver whenever a shipment
-- is linked to a vehicle. Fires on Shipment_Vehicle so the row
-- it needs already exists at trigger time.
-- ----------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_assign_driver
AFTER INSERT ON Shipment_Vehicle
FOR EACH ROW
DECLARE
    v_driver_id Driver.Driver_ID%TYPE;
BEGIN
    SELECT Driver_ID INTO v_driver_id
    FROM Driver
    WHERE Driver_ID NOT IN (
        SELECT Driver_ID FROM Vehicle WHERE Driver_ID IS NOT NULL
    )
    AND ROWNUM = 1;

    UPDATE Vehicle
    SET Driver_ID = v_driver_id
    WHERE Vehicle_ID = :NEW.Vehicle_ID;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No available driver to assign for Vehicle ' || :NEW.Vehicle_ID);
END;
/


-- ----------------------------------------------------------
-- Auto-set payment status based on amount, but only when the
-- payment row is first created. BEFORE trigger that sets :NEW
-- directly (a row-level trigger cannot safely UPDATE the same
-- table that fired it - that raises ORA-04091).
--
-- Deliberately INSERT-only, not INSERT OR UPDATE: if this also
-- fired on UPDATE, it would silently overwrite any later manual
-- status change (e.g. CancelOrder setting 'Refund Initiated')
-- back to 'PAID'/'PENDING' based on Amount alone.
-- ----------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_payment_status
BEFORE INSERT ON Payment
FOR EACH ROW
BEGIN
    IF :NEW.Amount = 0 THEN
        :NEW.Payment_Status := 'PENDING';
    ELSE
        :NEW.Payment_Status := 'PAID';
    END IF;
END;
/


-- ----------------------------------------------------------
-- Reduce stock in Product_Detail whenever a line item is added
-- to an order. Fires on Order_Items, where product + quantity
-- actually live, and joins through Product1.Name.
-- ----------------------------------------------------------
CREATE OR REPLACE TRIGGER Reduce_Stock_After_Order
AFTER INSERT ON Order_Items
FOR EACH ROW
DECLARE
    v_name Product1.Name%TYPE;
BEGIN
    SELECT Name INTO v_name
    FROM Product1
    WHERE Product_ID = :NEW.Product_ID;

    UPDATE Product_Detail
    SET Quantity = Quantity - :NEW.Quantity
    WHERE Name = v_name;
END;
/
