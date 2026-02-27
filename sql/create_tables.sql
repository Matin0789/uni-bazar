-- SUPPORT TABLES
CREATE TABLE supports (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    Lname VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    password VARCHAR(512)
);

-- PLAN_TYPE ENUMS
CREATE TYPE plan_type AS ENUM ('golden','vip');
-- PLAN TABELS
CREATE TABLE plans (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    period DATE NOT NULL, 
    price BIGINT NOT NULL,
    type plan_type NOT NULL,

    -- ADD realations
    employee_id INT,
    FOREIGN KEY (employee_id)
        REFERENCES supports(id)
        ON DELETE RESTRICT
);

-- USER TABLES
CREATE TABLE users (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255) UNIQUE,
    balance BIGINT DEFAULT 0, -- Wallet

    CONSTRAINT check_email_or_phone_not_null
        CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

CREATE TABLE addresses (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    user_id INT NOT NULL,
    province VARCHAR(100),
    city VARCHAR(100),
    street VARCHAR(255),
    postal_code VARCHAR(20),
    receiver_name VARCHAR(100),
    receiver_phone VARCHAR(20),

    CONSTRAINT pk_addresses PRIMARY KEY (id, user_id),

    CONSTRAINT fk_addresses_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- CART TABLES
CREATE TABLE carts (
    id INT GENERATED ALWAYS AS IDENTITY,
    user_id INT NOT NULL,
    is_locked BOOLEAN DEFAULT FALSE,

    CONSTRAINT pk_carts PRIMARY KEY (id, user_id),

    CONSTRAINT fk_carts_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

COMMENT ON COLUMN carts.is_locked IS 'For VIP Locked_Cart feature';

CREATE TABLE cart_items (
    id INT GENERATED ALWAYS AS IDENTITY,
    cart_id INT NOT NULL,
    cart_user_id INT NOT NULL,
    reserve_end TIMESTAMPTZ NOT NULL, -- Lock_End_Date

    CONSTRAINT pk_cart_items PRIMARY KEY (id, cart_id, cart_user_id),

    CONSTRAINT fk_cart_items_to_carts
        FOREIGN KEY (cart_id, cart_user_id) 
        REFERENCES carts(id, user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- PRODUCT TABLE
CREATE TYPE product_category AS ENUM ('Good', 'Service');

CREATE TABLE products (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    unit VARCHAR(50),
    image_url TEXT,
    product_type product_category NOT NULL,
    stock_quantity INT,

    CONSTRAINT check_product_type CHECK (
        (product_Type = 'Good' AND stock_Quantity IS NOT NULL) OR
        (product_Type = 'Service' AND stock_Quantity IS NULL)
    )
);

CREATE TABLE price_histories (
    id INT GENERATED ALWAYS AS IDENTITY,
    product_id INT NOT NULL,
    price BIGINT NOT NULL,
    valid_from TIME NOT NULL,
    valid_to TIME,

    CONSTRAINT pk_price_histories PRIMARY KEY (id, product_id),

    CONSTRAINT fk_price_histories_product_id
        FOREIGN KEY (product_id) 
        REFERENCES products(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT check_dates CHECK (valid_to IS NULL OR Valid_from <= Valid_to)
);

CREATE TYPE days_of_week AS ENUM ('Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday');

CREATE TABLE time_tables (
    id INT GENERATED ALWAYS AS IDENTITY,
    product_id INT NOT NULL,
    work_day days_of_week NOT NULL,   
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    CONSTRAINT pk_time_tables PRIMARY KEY (id, product_id),

    CONSTRAINT fk_time_tables_product_id
        FOREIGN KEY (product_id) 
        REFERENCES products(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE

    CONSTRAINT check_time_range 
        CHECK (end_time > start_time)
);

-- ORDER TABLES
CREATE TYPE order_status AS ENUM ('Pending', 'Paid', 'Shipped', 'Delivered', 'Cancelled');

CREATE TABLE orders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    payment_id INT NOT NULL REFERENCES payments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    status order_status DEFAULT 'Pending',
    total_amount BIGINT,
    final_amount BIGINT,
    tracking_code VARCHAR(100) UNIQUE
);

CREATE TABLE order_items (
    order_id INT NOT NULL,
    id INT GENERATED ALWAYS AS IDENTITY,
    price BIGINT NOT NULL,
    unit VARCHAR(50),

    PRIMARY KEY (order_id, id),

    FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE order_item_comment (
    item_id INT NOT NULL,
    id INT GENERATED ALWAYS AS IDENTITY,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    description TEXT,

    badge_id INT REFERENCES badges(id) ON DELETE RESTRICT -- INCLUDE relation
);

CREATE TYPE payment_status AS ENUM ('Success', 'Failed', 'Pending');
CREATE TYPE payment_method AS ENUM ('Online', 'Wallet');

CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
    payment_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status payment_status NOT NULL DEFAULT 'Pending',
    payment_method payment_method NOT NULL,
    amount BIGINT NOT NULL CHECK (amount > 0),
    transaction_ref VARCHAR(255) UNIQUE NOT NULL
);

-- SHIPMENT TABLES
CREATE TABLE shipments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    address_id BIGINT NOT NULL,
    address_user_id BIGINT NOT NULL,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shipping_method VARCHAR(50) NOT NULL,
    tracking_code VARCHAR(150) UNIQUE,
    carrier VARCHAR(100), -- Transportation Company
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,

    CONSTRAINT fk_shipments_to_addresses
        FOREIGN KEY (address_id, address_user_id)
        REFERENCES addresses(id, user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- EVENT ENUM
CREATE TYPE event_type AS ENUM('VIEW_BOOTH','VIEW_PRODUCT','ADD_TO_CART','PURCHASE');
-- EVENT TABLES
CREATE TABLE events (
    event_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type event_type NOT NULL,
    event_timestamp TIMESTAMP,
    
    user_id INT REFERENCES users(id) ON DELETE RESTRICT -- attends relation
);

-- BOOTH TABLES
CREATE TABLE booths (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booth_name VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    description TEXT,
    status_count INT CHECK (status_count BETWEEN 0 AND 6),
    status_end_date DATE,

    -- CREATES relation
    user_id INT,
    employee_id INT,
    request_id INT,
    FOREIGN KEY(user_id, employee_id, request_id) REFERENCES booth_requests(user_id, employee_id, request_id) ON DELETE RESTRICT

);

CREATE TABLE join_request (
    user_id NT REFERENCES users(id) ON DELETE RESTRICT,
    booth_id NT REFERENCES booths(id) ON DELETE RESTRICT,
    id INT GENERATED ALWAYS AS IDENTITY,

    PRIMARY KEY (user_id, booth_id, id)
);

-- WORKS_ON relation
CREATE TABLE works_on (
    request_id REFERENCES join_request(id) ON DELETE RESTRICT,
    user_id NT REFERENCES users(id) ON DELETE RESTRICT,
    booth_id NT REFERENCES booths(id) ON DELETE RESTRICT,
    
    PRIMARY KEY (user_id, booth_id, request_id),

    perm_no SMALLINT NOT NULL
    /*
    0001 : 1 : Can_Modify_Own_Products
    0010 : 2 : Can_Modify_All_Products
    0100 : 4 : Can_Add_Product
    1000 : 8 : Can_Edit_Booth_Info
    */
);

-- VIEW relation
CREATE TABLE user_view_booth (
    user_id INT REFERENCES users(id) ON DELETE RESTRICT,
    booth_id INT REFERENCES booths(id) ON DELETE RESTRICT,
    date DATE,

    PRIMARY KEY (booth_id, user_id)
);

-- GOLDEN_BOOTH TABLES
CREATE TABLE golden_booths (
    booth_id INT NOT NULL,
    id INT GENERATED ALWAYS AS IDENTITY,
    end_date DATE NOT NULL,

    PRIMARY KEY (booth_id, id),

    FOREIGN KEY (booth_id)
        REFERENCES booths(id)
        ON DELETE CASCADE,

    plan_id INT REFERENCES plans(id) ON DELETE RESTRICT -- OWNS realations
);

-- BADGE TABLES
CREATE TABLE badges (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100),
);

-- STORY TABLES
CREATE TABLE story (
    booth_id INT NOT NULL,
    story_id INT GENERATED ALWAYS AS IDENTITY,
    content TEXT,
    picture_url VARCHAR(200),

    PRIMARY KEY (booth_id, story_id),

    FOREIGN KEY (booth_id)
        REFERENCES booths(id)
        ON DELETE CASCADE
);

-- ACTION_LOG TABLES
CREATE TABLE action_logs (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    support_id INT,
    ip_address INET NOT NULL,
    action_type VARCHAR(100),
    description TEXT,
    timestamp TIMESTAMP,

    FOREIGN KEY (support_id)
        REFERENCES supports(id)
        ON DELETE RESTRICT
);

-- DISCOUNT_TYPE ENUMS
CREATE TYPE discount_type AS ENUM ('fixed', 'percentage');
-- DISCOUNT_CODE TABLES
CREATE TABLE discount_codes (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    support_id INT,
    code VARCHAR(20) UNIQUE NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    expiration_date DATE,
    discount_type discount_type NOT NULL,
    amount BIGINT,
    percent DECIMAL(5, 2) CHECK (percent BETWEEN 0 AND 100),

    CONSTRAINT check_amount_or_percent_not_null
        CHECK (amount IS NOT NULL OR percent IS NOT NULL),
    
    FOREIGN KEY (support_id)
        REFERENCES supports(id)
        ON DELETE RESTRICT
);

-- HAS realation table
CREATE TABLE users_has_dicount_code (
    user_id INT REFERENCES users(id) ON DELETE RESTRICT,
    code_id INT REFERENCES discount_codes(id) ON DELETE RESTRICT,

    PRIMARY KEY (user_id, code_id) 
);

-- VIP TABELS
CREATE TABLE vips (
    id INT GENERATED ALWAYS AS IDENTITY,
    user_id INT NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,

    CONSTRAINT pk_vips PRIMARY KEY (id, user_id),

    CONSTRAINT fk_vips_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    plan_id INT REFERENCES plans(id) ON DELETE RESTRICT -- OWNS realtions
);

-- STATUS ENUM
CREATE TYPE status_type AS ENUM('pending','rejected','accepted'); 
-- BOOTH_REQUEST TABLE
CREATE TABLE booth_requests (
    user_id INT REFERENCES users(id) ON DELETE RESTRICT,
    employee_id INT REFERENCES supports(id) ON DELETE RESTRICT,
    request_id INT GENERATED ALWAYS AS IDENTITY,
    PRIMARY KEY(user_id, employee_id, request_id),

    date DATE NOT NULL,
    reason TEXT,
    booth_name VARCHAR(100) NOT NULL,
    user_description TEXT,
    status status_type NOT NULL DEFAULT 'pending'
);
