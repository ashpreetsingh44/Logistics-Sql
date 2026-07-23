-- ============================================================
-- 04_sample_data.sql
-- Sample rows to demo the schema, procedures, and triggers.
-- Run after 01_tables.sql, 02_procedures.sql, 03_triggers.sql.
-- ============================================================

-- Customers
INSERT INTO Customer VALUES (1, 'Aarav', 'Sharma', 'aarav.sharma@example.com', '9876500001', '12-A', 'Amritsar', '143001');
INSERT INTO Customer VALUES (2, 'Simran', 'Kaur', 'simran.kaur@example.com', '9876500002', '45-B', 'Ludhiana', '141001');

-- Suppliers
INSERT INTO Supplier1 VALUES (1, 'Rohit', 'Verma', 'rohit.verma@suppliers.com', '9988700001', '7-C', '110001');
INSERT INTO Supplier1 VALUES (2, 'Neha', 'Gupta', 'neha.gupta@suppliers.com', '9988700002', '9-D', '110002');

INSERT INTO Email_Supplier VALUES ('rohit.verma@suppliers.com', 1);
INSERT INTO Email_Supplier VALUES ('neha.gupta@suppliers.com', 2);

INSERT INTO Contact_Supplier VALUES ('9988700001', 1);
INSERT INTO Contact_Supplier VALUES ('9988700002', 2);

-- Products
INSERT INTO Product1 VALUES (101, 'Wireless Mouse');
INSERT INTO Product1 VALUES (102, 'Mechanical Keyboard');

-- Product_Detail must exist BEFORE Order_Items is inserted, since the
-- Reduce_Stock_After_Order trigger updates this table on order insert.
INSERT INTO Product_Detail VALUES ('Wireless Mouse', 'Electronics', 0.15, 100, 799.00);
INSERT INTO Product_Detail VALUES ('Mechanical Keyboard', 'Electronics', 0.90, 50, 2999.00);

-- Warehouse
INSERT INTO Warehouse VALUES (1, 'Amritsar Central', 5000, 'Karan Mehta');

-- Drivers (needed before Shipment_Vehicle, since trg_assign_driver
-- picks the first unassigned driver at insert time)
INSERT INTO Driver VALUES (1, 'Manpreet', 'Singh', '9123400001');
INSERT INTO Driver VALUES (2, 'Ravi', 'Kumar', '9123400002');

INSERT INTO License VALUES ('PB-DL-0001', 1);
INSERT INTO License VALUES ('PB-DL-0002', 2);

-- Vehicles (Driver_ID left NULL - trg_assign_driver fills it in
-- once the vehicle is linked to a shipment)
INSERT INTO Vehicle (Vehicle_ID, Driver_ID, Model, License_Plate) VALUES (1, NULL, 'Tata Ace', 'PB-02-AB-1234');
INSERT INTO Vehicle (Vehicle_ID, Driver_ID, Model, License_Plate) VALUES (2, NULL, 'Mahindra Bolero', 'PB-02-CD-5678');

-- ----------------------------------------------------------
-- Place two orders using the procedure (recommended way - this
-- exercises Orders, Order_Items, Payment, Shipment, Shipment_Vehicle,
-- and all three triggers in one call each).
-- ----------------------------------------------------------
BEGIN
    Place_New_Order(
        p_Customer_ID    => 1,
        p_Supplier_ID    => 1,
        p_Product_ID     => 101,
        p_Quantity       => 3,
        p_Order_ID       => 1001,
        p_Payment_Amount => 2397.00,
        p_Shipment_ID    => 5001,
        p_Warehouse_ID   => 1,
        p_Vehicle_ID     => 1
    );

    Place_New_Order(
        p_Customer_ID    => 2,
        p_Supplier_ID    => 2,
        p_Product_ID     => 102,
        p_Quantity       => 1,
        p_Order_ID       => 1002,
        p_Payment_Amount => 2999.00,
        p_Shipment_ID    => 5002,
        p_Warehouse_ID   => 1,
        p_Vehicle_ID     => 2
    );
END;
/

-- Tracking events for the first shipment (used by
-- Update_Delivery_From_Tracking to pick the latest status)
INSERT INTO Tracking_Natural VALUES (5001, TIMESTAMP '2026-07-20 09:00:00', 'PICKED_UP', 'Amritsar Warehouse', 31.634000, 74.872200);
INSERT INTO Tracking_Natural VALUES (5001, TIMESTAMP '2026-07-21 14:30:00', 'IN_TRANSIT', 'Jalandhar Hub', 31.326000, 75.576100);
INSERT INTO Tracking_Natural VALUES (5001, TIMESTAMP '2026-07-22 11:15:00', 'DELIVERED', 'Amritsar - Customer Address', 31.634000, 74.872200);

COMMIT;

-- ----------------------------------------------------------
-- Verification queries - run these to confirm everything worked:
-- ----------------------------------------------------------
-- SELECT * FROM Orders;
-- SELECT * FROM Payment;                 -- Payment_Status should be 'PAID'
-- SELECT * FROM Product_Detail;          -- Quantity reduced by ordered amounts
-- SELECT * FROM Vehicle;                 -- Driver_ID should now be populated
-- EXEC Update_Delivery_From_Tracking;    -- Orders(1001) should become 'DELIVERED'
-- EXEC Show_Undelivered;
-- EXEC Mark_Delayed_Shipments;
-- EXEC CancelOrder(1002);
