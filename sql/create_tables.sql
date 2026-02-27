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
        REFERENCES supports(employee_id)
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
    
)

-- EVENT ENUM
CREATE TYPE PLAN_TYPE AS ENUM('VIEW_BOOTH','VIEW_PRODUCT','ADD_TO_CART','PURCHASE');
-- EVENT TABLES
CREATE TABLE events (
    event_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type PLAN_TYPE NOT NULL,
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

    plan_id INT REFERENCES plans(plan_id) ON DELETE RESTRICT -- OWNS realations
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
CREATE TYPE DISCOUNT_TYPE AS ENUM ('FIXED', 'PERCENTAGE');
-- DISCOUNT_CODE TABLES
CREATE TABLE discount_codes (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    support_id INT,
    code VARCHAR(20) UNIQUE NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    expiration_date DATE,
    discount_type DISCOUNT_TYPE NOT NULL,
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
    user_id INT REFERENCES users(user_id) ON DELETE RESTRICT,
    code_id INT REFERENCES discount_codes(code_id) ON DELETE RESTRICT,

    PRIMARY KEY (user_id, code_id) 
);

-- VIP TABELS
CREATE TABLE vips (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,

    CONSTRAINT pk_vips (id, user_id)

    CONSTRAINT fk_vips_user_id
        FOREIGN KEY
        REFERENCES users(user_id) ON DELETE CASCADE
        ON DELETE CASCADE
        ON UPDATE CASCADE

    plan_id INT REFERENCES plans(plan_id) ON DELETE RESTRICT -- OWNS realtions
);

-- STATUS ENUM
CREATE TYPE STATUS_TYPE AS ENUM('PENDIGN','REJECTED','ACCEPTED'); 
-- BOOTH_REQUEST TABLE
CREATE TABLE booth_requests (
    user_id INT REFERENCES users(id) ON DELETE RESTRICT,
    employee_id INT REFERENCES supports(employee_id) ON DELETE RESTRICT,
    request_id INT GENERATED ALWAYS AS IDENTITY,
    PRIMARY KEY(user_id, employee_id, request_id),

    date DATE NOT NULL,
    reason TEXT,
    booth_name VARCHAR(100) NOT NULL,
    user_description TEXT,
    status STATUS_TYPE NOT NULL DEFAULT 'PENDING'

)
