-- SUPPORT TABLES
CREATE TABLE supports (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    Lname VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    password VARCHAR(512)
);

-- PLAN_TYPE ENUMS
CREATE TYPE PLAN_TYPE AS ENUM ('GOLDEN','VIP');
-- PLAN TABELS
CREATE TABLE plans (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    period DATE NOT NULL, 
    price BIGINT NOT NULL,

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
    id INT GENERATED ALWAYS AS IDENTITY,
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

CREATE TYPE order_status AS ENUM ('Pending', 'Paid', 'Shipped', 'Delivered', 'Cancelled');

-- ORDER TABLES
CREATE TABLE orders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
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
    rating 
    description TEXT
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
    status_end_date DATE
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
