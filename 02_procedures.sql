-- ============================================================
-- 02_procedures.sql
-- Stored procedures for the Supply Chain / Order Management System.
-- Run after 01_tables.sql.
-- ============================================================

-- ----------------------------------------------------------
-- Place a new order end-to-end: creates the order, its line item,
-- payment record, shipment, and vehicle assignment in one call.
-- ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE Place_New_Order (
    p_Customer_ID     IN Customer.Customer_ID%TYPE,
    p_Supplier_ID     IN Supplier1.Supplier_ID%TYPE,
    p_Product_ID      IN Product1.Product_ID%TYPE,
    p_Quantity        IN Order_Items.Quantity%TYPE,
    p_Order_ID        IN Orders.Order_ID%TYPE,
    p_Payment_Amount  IN NUMBER,
    p_Shipment_ID     IN Shipment.Shipment_ID%TYPE,
    p_Warehouse_ID    IN Shipment.Warehouse_ID%TYPE,
    p_Vehicle_ID      IN Shipment_Vehicle.Vehicle_ID%TYPE
) AS
BEGIN
    INSERT INTO Orders
    VALUES (p_Order_ID, p_Customer_ID, p_Supplier_ID, SYSDATE, 'PENDING');

    INSERT INTO Order_Items
    VALUES (p_Order_ID, p_Product_ID, p_Quantity);

    INSERT INTO Payment
    VALUES (p_Order_ID, p_Payment_Amount, 'PENDING', 'COD');

    INSERT INTO Shipment
    VALUES (p_Shipment_ID, p_Order_ID, p_Warehouse_ID, SYSDATE, SYSDATE + 5);

    INSERT INTO Shipment_Vehicle
    VALUES (p_Shipment_ID, p_Vehicle_ID);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- ----------------------------------------------------------
-- Update each order's delivery status to reflect the most recent
-- tracking event recorded for its shipment.
-- ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE Update_Delivery_From_Tracking IS
    CURSOR c IS
        SELECT t.Shipment_ID, t.Status
        FROM Tracking_Natural t
        WHERE t.Time_Stamp = (
            SELECT MAX(t2.Time_Stamp)
            FROM Tracking_Natural t2
            WHERE t2.Shipment_ID = t.Shipment_ID
        );
BEGIN
    FOR r IN c LOOP
        UPDATE Orders
        SET Delivery_Status = r.Status
        WHERE Order_ID = (
            SELECT Order_ID FROM Shipment WHERE Shipment_ID = r.Shipment_ID
        );
    END LOOP;
    COMMIT;
END;
/


-- ----------------------------------------------------------
-- Flag orders as DELAYED if their shipment's delivery date has
-- passed and the order hasn't already been delivered or cancelled.
-- ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE Mark_Delayed_Shipments IS
    CURSOR c IS
        SELECT s.Shipment_ID
        FROM Shipment s
        JOIN Orders o ON o.Order_ID = s.Order_ID
        WHERE s.Delivery_Date < SYSDATE
        AND o.Delivery_Status NOT IN ('DELIVERED', 'Cancelled');
BEGIN
    FOR r IN c LOOP
        UPDATE Orders
        SET Delivery_Status = 'DELAYED'
        WHERE Order_ID = (
            SELECT Order_ID FROM Shipment WHERE Shipment_ID = r.Shipment_ID
        );
    END LOOP;
    COMMIT;
END;
/


-- ----------------------------------------------------------
-- Print all orders that are not yet marked DELIVERED.
-- ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE Show_Undelivered IS
    CURSOR c IS
        SELECT Order_ID, Delivery_Status
        FROM Orders
        WHERE Delivery_Status != 'DELIVERED';
BEGIN
    FOR r IN c LOOP
        DBMS_OUTPUT.PUT_LINE('Order: ' || r.Order_ID || ' Status: ' || r.Delivery_Status);
    END LOOP;
END;
/


-- ----------------------------------------------------------
-- Cancel an order and mark its payment as refund-initiated.
-- ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE CancelOrder (
    p_order_id IN Orders.Order_ID%TYPE
) IS
    v_exists INT;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM Orders WHERE Order_ID = p_order_id;

    IF v_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Order ID not found.');
        RETURN;
    END IF;

    UPDATE Orders
    SET Delivery_Status = 'Cancelled'
    WHERE Order_ID = p_order_id;

    UPDATE Payment
    SET Payment_Status = 'Refund Initiated'
    WHERE Order_ID = p_order_id;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Order cancelled. Refund initiated.');
END;
/
