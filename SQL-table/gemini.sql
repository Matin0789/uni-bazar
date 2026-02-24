-- Create the database (Optional)
CREATE DATABASE project_db;
USE project_db;

-- ==========================================
-- 1. USERS & ACCOUNTS
-- ==========================================

CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    fname VARCHAR(100),
    lname VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    image_url TEXT,
    status INT DEFAULT 0 COMMENT '0: Active, 1-5: Suspended, 6: Blocked',
    is_vip BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Wallet (
    wallet_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE,
    balance DECIMAL(15, 2) DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Address (
    address_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    province VARCHAR(100),
    city VARCHAR(100),
    street VARCHAR(255),
    postal_code VARCHAR(20),
    receiver_name VARCHAR(200),
    receiver_phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- ==========================================
-- 2. BOOTHS (STORES) & EMPLOYEES
-- ==========================================

CREATE TABLE Booth (
    booth_id INT PRIMARY KEY AUTO_INCREMENT,
    owner_id INT,
    name VARCHAR(100),
    description TEXT,
    image_url TEXT,
    account_no VARCHAR(50),
    is_golden BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (owner_id) REFERENCES Users(user_id)
);

CREATE TABLE Employee (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    booth_id INT,
    perm_no INT COMMENT 'Bitmask: 1=Modify Own, 2=Modify All, 4=Add Product, 8=Edit Booth Info',
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

CREATE TABLE Story (
    story_id INT PRIMARY KEY AUTO_INCREMENT,
    booth_id INT,
    content TEXT,
    picture_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

-- ==========================================
-- 3. PRODUCTS (INHERITANCE STRUCTURE)
-- ==========================================

-- Parent Table
CREATE TABLE Product (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    booth_id INT,
    title VARCHAR(255),
    description TEXT,
    image_url TEXT,
    base_price DECIMAL(10, 2),
    stock_quantity INT,
    product_type ENUM('Good', 'Service'),
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

-- Child Table: Goods (Physical items)
CREATE TABLE Good (
    product_id INT PRIMARY KEY,
    expiration_date DATE,
    is_used BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES Product(product_id) ON DELETE CASCADE
);

-- Child Table: Services
CREATE TABLE Service (
    product_id INT PRIMARY KEY,
    location VARCHAR(255),
    FOREIGN KEY (product_id) REFERENCES Product(product_id) ON DELETE CASCADE
);

CREATE TABLE Time_Table (
    timetable_id INT PRIMARY KEY AUTO_INCREMENT,
    service_id INT,
    start_time DATETIME,
    end_time DATETIME,
    FOREIGN KEY (service_id) REFERENCES Service(product_id)
);

CREATE TABLE Price_History (
    price_history_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT,
    price DECIMAL(10, 2),
    valid_from DATETIME,
    valid_to DATETIME,
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ==========================================
-- 4. DISCOUNTS
-- ==========================================

CREATE TABLE Discount_Code (
    discount_id INT PRIMARY KEY AUTO_INCREMENT,
    booth_id INT,
    code VARCHAR(50) UNIQUE,
    start_date DATETIME,
    end_date DATETIME,
    type ENUM('Fixed', 'Percentage'),
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

CREATE TABLE Discount_Fixed (
    discount_id INT PRIMARY KEY,
    amount DECIMAL(10, 2),
    FOREIGN KEY (discount_id) REFERENCES Discount_Code(discount_id) ON DELETE CASCADE
);

CREATE TABLE Discount_Percentage (
    discount_id INT PRIMARY KEY,
    percent DECIMAL(5, 2),
    FOREIGN KEY (discount_id) REFERENCES Discount_Code(discount_id) ON DELETE CASCADE
);

-- ==========================================
-- 5. SHOPPING CART
-- ==========================================

CREATE TABLE Cart (
    cart_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    is_locked BOOLEAN DEFAULT FALSE COMMENT 'For VIP Locked_Cart feature',
    lock_end_date DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Cart_Item (
    cart_item_id INT PRIMARY KEY AUTO_INCREMENT,
    cart_id INT,
    product_id INT,
    quantity INT,
    reserve_start DATETIME COMMENT 'For Services',
    reserve_end DATETIME COMMENT 'For Services',
    FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ==========================================
-- 6. ORDERS & SHIPMENT
-- ==========================================

CREATE TABLE Orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    discount_id INT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2),
    final_amount DECIMAL(10, 2),
    status ENUM('Pending', 'Paid', 'Shipped', 'Delivered', 'Cancelled'),
    tracking_code VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (discount_id) REFERENCES Discount_Code(discount_id)
);

CREATE TABLE Order_Item (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    reserve_start DATETIME,
    reserve_end DATETIME,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Payment (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    payment_date DATETIME,
    amount DECIMAL(10, 2),
    payment_method ENUM('Online', 'Wallet'),
    payment_status ENUM('Success', 'Failed', 'Pending'),
    transaction_ref VARCHAR(255) COMMENT 'Gateway reference code',
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

CREATE TABLE Shipment (
    shipment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT UNIQUE,
    address_id INT,
    shipment_date DATETIME,
    shipment_method VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (address_id) REFERENCES Address(address_id)
);

-- ==========================================
-- 7. SOCIAL: CHAT, REVIEWS & BOOKMARKS
-- ==========================================

CREATE TABLE Chat (
    chat_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    booth_id INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

CREATE TABLE Message (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    chat_id INT,
    sender_type ENUM('User', 'Booth'),
    content TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (chat_id) REFERENCES Chat(chat_id)
);

CREATE TABLE Review (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    review_date DATETIME,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Bookmarks (
    user_id INT,
    product_id INT,
    date DATETIME,
    PRIMARY KEY (user_id, product_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- ==========================================
-- 8. SUBSCRIPTIONS (PLANS)
-- ==========================================

CREATE TABLE Plan (
    plan_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    price DECIMAL(10, 2),
    period_days INT,
    type ENUM('VIP', 'Golden')
);

CREATE TABLE User_Plan_Subscription (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    plan_id INT,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (plan_id) REFERENCES Plan(plan_id)
);

-- ==========================================
-- 9. ADMINISTRATION & REQUESTS
-- ==========================================

CREATE TABLE Request (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    type ENUM('Join', 'Create_Booth', 'Support'),
    status ENUM('Pending', 'Approved', 'Rejected'),
    request_date DATETIME,
    description TEXT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Badge (
    badge_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    icon_url TEXT
);

CREATE TABLE Badge_Assignment (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    badge_id INT,
    booth_id INT,
    date_assigned DATETIME,
    FOREIGN KEY (badge_id) REFERENCES Badge(badge_id),
    FOREIGN KEY (booth_id) REFERENCES Booth(booth_id)
);

CREATE TABLE Action_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action_type ENUM('View_Booth', 'View_Product', 'Add_Cart', 'Purchase'),
    description TEXT,
    ip_address VARCHAR(45),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);