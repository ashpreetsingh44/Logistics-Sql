-- ============================================================
-- 01_tables.sql
-- Schema: Supply Chain / Order Management System
-- Run this file first. Tables are ordered so every FK reference
-- points to a table that already exists (no forward references).
-- ============================================================

CREATE TABLE Customer (
    Customer_ID   INT PRIMARY KEY,
    First_Name    VARCHAR(100),
    Last_Name     VARCHAR(100),
    Email         VARCHAR(255) UNIQUE,
    Contact_No    VARCHAR(20) UNIQUE,
    House_No      VARCHAR(20),
    City          VARCHAR(100),
    Zip_Code      VARCHAR(10)
);

CREATE TABLE Supplier1 (
    Supplier_ID   INT PRIMARY KEY,
    First_Name    VARCHAR(100),
    Last_Name     VARCHAR(100),
    Email         VARCHAR(255) UNIQUE,
    Contact_No    VARCHAR(20) UNIQUE,
    House_No      VARCHAR(20),
    Zip_Code      VARCHAR(10)
);

CREATE TABLE Email_Supplier (
    Email         VARCHAR(255) PRIMARY KEY,
    Supplier_ID   INT,
    FOREIGN KEY (Supplier_ID) REFERENCES Supplier1(Supplier_ID)
);

CREATE TABLE Contact_Supplier (
    Contact_No    VARCHAR(20) PRIMARY KEY,
    Supplier_ID   INT,
    FOREIGN KEY (Supplier_ID) REFERENCES Supplier1(Supplier_ID)
);

CREATE TABLE Product1 (
    Product_ID    INT PRIMARY KEY,
    Name          VARCHAR(255) UNIQUE
);

CREATE TABLE Product_Detail (
    Name          VARCHAR(255),
    Category      VARCHAR(100),
    Weight        DECIMAL(10,2),
    Quantity      INT,
    Price         DECIMAL(10,2),
    PRIMARY KEY (Name),
    FOREIGN KEY (Name) REFERENCES Product1(Name)
);

CREATE TABLE Orders (
    Order_ID          INT PRIMARY KEY,
    Customer_ID       INT,
    Supplier_ID       INT,
    Order_Date        DATE,
    Delivery_Status   VARCHAR(100),
    FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID),
    FOREIGN KEY (Supplier_ID) REFERENCES Supplier1(Supplier_ID)
);

-- Links an order to the product(s) it contains, with quantity.
-- Required so triggers/procedures can know what was ordered.
CREATE TABLE Order_Items (
    Order_ID      INT,
    Product_ID    INT,
    Quantity      INT NOT NULL,
    PRIMARY KEY (Order_ID, Product_ID),
    FOREIGN KEY (Order_ID)   REFERENCES Orders(Order_ID),
    FOREIGN KEY (Product_ID) REFERENCES Product1(Product_ID)
);

CREATE TABLE Payment (
    Order_ID         INT PRIMARY KEY,
    Amount           DECIMAL(10,2),
    Payment_Status   VARCHAR(100),
    Payment_Method   VARCHAR(100),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

CREATE TABLE Warehouse (
    Warehouse_ID   INT PRIMARY KEY,
    Location       VARCHAR(255),
    Capacity       INT,
    Manager_Name   VARCHAR(100)
);

CREATE TABLE Driver (
    Driver_ID    INT PRIMARY KEY,
    First_Name   VARCHAR(100),
    Last_Name    VARCHAR(100),
    Contact_No   VARCHAR(20) UNIQUE
);

CREATE TABLE License (
    License_No   VARCHAR(20) PRIMARY KEY,
    Driver_ID    INT,
    FOREIGN KEY (Driver_ID) REFERENCES Driver(Driver_ID)
);

CREATE TABLE Vehicle (
    Vehicle_ID      INT PRIMARY KEY,
    Driver_ID       INT,
    Model           VARCHAR(100),
    License_Plate   VARCHAR(20),
    FOREIGN KEY (Driver_ID) REFERENCES Driver(Driver_ID)
);

CREATE TABLE Shipment (
    Shipment_ID     INT PRIMARY KEY,
    Order_ID        INT,
    Warehouse_ID    INT,
    Shipment_Date   DATE,
    Delivery_Date   DATE,
    FOREIGN KEY (Order_ID)     REFERENCES Orders(Order_ID),
    FOREIGN KEY (Warehouse_ID) REFERENCES Warehouse(Warehouse_ID)
);

-- Junction between a shipment and the vehicle assigned to carry it.
CREATE TABLE Shipment_Vehicle (
    Shipment_ID   INT PRIMARY KEY,
    Vehicle_ID    INT,
    FOREIGN KEY (Shipment_ID) REFERENCES Shipment(Shipment_ID),
    FOREIGN KEY (Vehicle_ID)  REFERENCES Vehicle(Vehicle_ID)
);

CREATE TABLE Tracking_Natural (
    Shipment_ID   INT,
    Time_Stamp    TIMESTAMP,
    Status        VARCHAR(100),
    Location      VARCHAR(255),
    Latitude      DECIMAL(9,6),
    Longitude     DECIMAL(9,6),
    PRIMARY KEY (Shipment_ID, Time_Stamp),
    FOREIGN KEY (Shipment_ID) REFERENCES Shipment(Shipment_ID)
);

CREATE TABLE Tracking_ID_Map (
    Tracking_ID   INT PRIMARY KEY,
    Shipment_ID   INT,
    Time_Stamp    TIMESTAMP,
    FOREIGN KEY (Shipment_ID) REFERENCES Shipment(Shipment_ID)
);
