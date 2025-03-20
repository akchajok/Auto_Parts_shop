/*
This SQL file serves as the submission for the Final Group Project
Team Member: Bekbol Ormotoev

1) Project Manager: Bekbol Ormotoev
2) Tasks handled: Full SQL development, optimization, and documentation
3) Submission includes:
   - Database creation
   - Table definitions with constraints
   - Indexes
   - Multi-table queries
   - Subqueries
   - Updatable views
   - Stored procedures
   - Stored functions
   - Transactions & Locking Mechanisms
   - Additional Testing Queries for Validation
*/

-- Drop database if exists to start fresh
DROP DATABASE IF EXISTS AutoPartsShop;
CREATE DATABASE AutoPartsShop;
USE AutoPartsShop;

-- Categories Table
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
) ENGINE=InnoDB;

-- Suppliers Table
CREATE TABLE Suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL UNIQUE,
    contact_name VARCHAR(255) NOT NULL,
    phone CHAR(10) NOT NULL CHECK (phone REGEXP '^[0-9]{10}$'),
    email VARCHAR(255) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone CHAR(10) NOT NULL CHECK (phone REGEXP '^[0-9]{10}$'),
    address VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Products Table
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    category_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    supplier_id INT NOT NULL,
    warranty_period INT DEFAULT 12 CHECK (warranty_period >= 0),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE CASCADE,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Orders Table
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount > 0),
    payment_method ENUM('Credit Card', 'PayPal', 'Bitcoin', 'Cash', 'Bank Transfer') NOT NULL,
    status ENUM('Pending', 'Shipped', 'Delivered', 'Canceled', 'Paid') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- OrderDetails Table (Bridge Table for Many-to-Many Relationship)
CREATE TABLE OrderDetails (
    order_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal > 0),
    discount DECIMAL(5,2) DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
) ENGINE=InnoDB;

/*
-- Indexes for Optimization
*/
CREATE INDEX idx_products_category_id ON Products(category_id);
CREATE INDEX idx_orders_customer_id ON Orders(customer_id);
CREATE INDEX idx_orderdetails_order_product ON OrderDetails(order_id, product_id);
CREATE INDEX idx_customers_email ON Customers(email);
CREATE INDEX idx_suppliers_email ON Suppliers(email);

/*
-- Updatable View for Customer Orders
*/
CREATE VIEW vw_customer_orders AS
SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount, o.status
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id;

/*
-- Transaction Handling: Secure Order Payment Processing
*/
DELIMITER $$
CREATE PROCEDURE sp_process_order_payment(IN orderID INT, IN paymentAmount DECIMAL(10,2))
BEGIN
    DECLARE current_balance DECIMAL(10,2);
    START TRANSACTION;
    SELECT total_amount INTO current_balance FROM Orders WHERE order_id = orderID FOR UPDATE;
    IF paymentAmount >= current_balance THEN
        UPDATE Orders SET status = 'Paid' WHERE order_id = orderID;
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END $$
DELIMITER ;

CALL sp_process_order_payment(1, 200.00);

/*
-- Stored Function to Calculate Discounted Total
*/
DELIMITER $$
CREATE FUNCTION fn_calculate_discounted_total(orderID INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(subtotal - (subtotal * discount / 100)) INTO total FROM OrderDetails WHERE order_id = orderID;
    RETURN total;
END $$
DELIMITER ;

SELECT fn_calculate_discounted_total(1);
