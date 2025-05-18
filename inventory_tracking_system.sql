-- ========================================
-- Create Database
-- ========================================
CREATE DATABASE IF NOT EXISTS AdvancedInventoryTrackingDB;
USE AdvancedInventoryTrackingDB;

-- ========================================
-- Create Tables
-- ========================================

-- 1. Employees Table
CREATE TABLE IF NOT EXISTS Employees (
    EmployeeID INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeName VARCHAR(100) NOT NULL,
    Role VARCHAR(50) NOT NULL,
    ContactEmail VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(15),
    DateHired DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Suppliers Table
CREATE TABLE IF NOT EXISTS Suppliers (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    ContactName VARCHAR(50),
    ContactEmail VARCHAR(100) UNIQUE,
    PhoneNumber VARCHAR(15),
    Address VARCHAR(255),
    DateAdded DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS Categories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(100) NOT NULL UNIQUE,
    Description TEXT
);

-- 4. Products Table
CREATE TABLE IF NOT EXISTS Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    SupplierID INT,
    CategoryID INT,
    Price DECIMAL(10, 2) CHECK (Price > 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    ReorderLevel INT DEFAULT 10 CHECK (ReorderLevel >= 0),
    ExpiryDate DATE,
    DateAdded DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_supplier FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID) ON DELETE SET NULL,
    CONSTRAINT fk_category FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL,
    UNIQUE (ProductName)
);

-- 5. Warehouses Table
CREATE TABLE IF NOT EXISTS Warehouses (
    WarehouseID INT AUTO_INCREMENT PRIMARY KEY,
    WarehouseName VARCHAR(100) NOT NULL,
    Location VARCHAR(255) NOT NULL
);

-- 6. InventoryStock Table
CREATE TABLE IF NOT EXISTS InventoryStock (
    StockID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT,
    WarehouseID INT,
    Quantity INT DEFAULT 0 CHECK (Quantity >= 0),
    CONSTRAINT fk_product_stock FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    CONSTRAINT fk_warehouse_stock FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID) ON DELETE CASCADE,
    UNIQUE (ProductID, WarehouseID)
);

-- 7. InventoryTransactions Table
CREATE TABLE IF NOT EXISTS InventoryTransactions (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT,
    WarehouseID INT,
    EmployeeID INT,
    TransactionType ENUM('Purchase', 'Sale', 'Adjustment') NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    PurchasePrice DECIMAL(10, 2) CHECK (PurchasePrice >= 0),
    SalePrice DECIMAL(10, 2) CHECK (SalePrice >= 0),
    TransactionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Notes TEXT,
    CONSTRAINT fk_product_transaction FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    CONSTRAINT fk_warehouse_transaction FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID) ON DELETE CASCADE,
    CONSTRAINT fk_employee_transaction FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE SET NULL
);

-- 8. AuditLog Table
CREATE TABLE IF NOT EXISTS AuditLog (
    AuditID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(50) NOT NULL,
    RecordID INT NOT NULL,
    Operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    OldValue TEXT,
    NewValue TEXT,
    ModifiedBy VARCHAR(100),
    ModifiedDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 9. Checkin Table
CREATE TABLE IF NOT EXISTS Checkin (
    CheckinID INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeID INT,
    ProductID INT,
    WarehouseID INT,
    CheckinDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT fk_employee_checkin FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE SET NULL,
    CONSTRAINT fk_product_checkin FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE SET NULL,
    CONSTRAINT fk_warehouse_checkin FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID) ON DELETE SET NULL
);
-- 10. Checkout Table
CREATE TABLE IF NOT EXISTS Checkout (
    CheckoutID INT AUTO_INCREMENT PRIMARY KEY,
    EmployeeID INT,
    ProductID INT,
    WarehouseID INT,
    CheckoutDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    CONSTRAINT fk_employee_checkout FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID) ON DELETE SET NULL,
    CONSTRAINT fk_product_checkout FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE SET NULL,
    CONSTRAINT fk_warehouse_checkout FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID) ON DELETE SET NULL
);


-- ========================================
-- Triggers for Automatic Stock Updates
-- ========================================

-- Trigger to update stock after a Purchase transaction (No error rate)
DELIMITER //
CREATE TRIGGER update_stock_after_purchase
AFTER INSERT ON InventoryTransactions
FOR EACH ROW
BEGIN
    -- Update the stock level after purchase
    UPDATE InventoryStock
    SET Quantity = Quantity + NEW.Quantity
    WHERE ProductID = NEW.ProductID AND WarehouseID = NEW.WarehouseID;
END //
DELIMITER ;

-- Trigger to update stock after a Sale transaction (No error rate)
DELIMITER //
CREATE TRIGGER update_stock_after_sale
AFTER INSERT ON InventoryTransactions
FOR EACH ROW
BEGIN
    -- Update the stock level after sale
    UPDATE InventoryStock
    SET Quantity = Quantity - NEW.Quantity
    WHERE ProductID = NEW.ProductID AND WarehouseID = NEW.WarehouseID;
END //
DELIMITER ;

-- ========================================
-- Sample Data Insertion
-- ========================================

-- Insert sample employees
INSERT INTO Employees (EmployeeName, Role, ContactEmail, PhoneNumber) VALUES
('Alice Dlamini', 'Manager', 'alice@company.com', '+27 12-456-7891'),
('Nico Williams', 'Stock Clerk', 'nico@company.com', '+27 12-456-7892'),
('Charlie Sethole', 'Sales Associate', 'charlie@company.com', '+27 12-456-7893');

-- Insert sample suppliers
INSERT INTO Suppliers (SupplierName, ContactName, ContactEmail, PhoneNumber, Address) VALUES
('ABC Electronics', 'John Doe', 'john@abc.com', '123-456-7890', '1234 Electronics St, Pta'),
('XYZ Gadgets', 'Jane Smith', 'jane@xyz.com', '987-654-3210', '5678 Gadget Ave, Cpt');

-- Insert sample products
INSERT INTO Products (ProductName, SupplierID, CategoryID, Price, StockQuantity, ExpiryDate) VALUES
('Laptop', 1, 1, 999.99, 50, '2025-12-31'),
('Smartphone', 2, 2, 799.99, 200, '2026-06-30');
