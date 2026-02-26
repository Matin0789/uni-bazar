-- USER TABLES
CREATE TABLE users (
    user_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255) UNIQUE,
    balance BIGINT DEFAULT 0, -- Wallet

    CONSTRAINT check_email_or_phone_not_null
        CHECK (phone IS NOT NULL OR email IS NOT NULL)
);

-- BOOTH TABLES
CREATE TABLE booths (
    booth_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booth_name VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    description TEXT,
    status_count INT CHECK (status_count BETWEEN 0 AND 6),
    status_end_date DATE
);

-- GOLDEN_BOOTH TABLES
CREATE TABLE golden_booths (
    booth_id INT NOT NULL,
    plan_id INT GENERATED ALWAYS AS IDENTITY,
    end_date DATE NOT NULL,

    PRIMARY KEY (booth_id, plan_id),

    FOREIGN KEY (booth_id)
        REFERENCES booths(booth_id)
        ON DELETE CASCADE
);

-- STORY TABLES
CREATE TABLE story (
    booth_id INT NOT NULL,
    story_id INT GENERATED ALWAYS AS IDENTITY,
    content TEXT,
    picture_url VARCHAR(200),

    PRIMARY KEY (booth_id, story_id),

    FOREIGN KEY (booth_id)
        REFERENCES booths(booth_id)
        ON DELETE CASCADE
);

-- SUPPORT TABLES
CREATE TABLE supports (
    employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    Lname VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    password VARCHAR(512)
);

-- ACTION_LOG TABLES
CREATE TABLE action_logs (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INT,
    ip_address INET NOT NULL,
    action_type VARCHAR(100),
    description TEXT,
    timestamp TIMESTAMP

    FOREIGN KEY (employee_id)
        REFERENCES supports(employee_id)
        ON DELETE RESTRICT
);

-- DISCOUNT_TYPE ENUMS
CREATE TYPE DISCOUNT_TYPE AS ENUM ('FIXED', 'PERCENTAGE');
-- DISCOUNT_CODE TABLES
CREATE TABLE discount_codes (
    code_id SERIAL PRIMARY KEY,
    employee_id INT,
    code VARCHAR(20) UNIQUE NOT NULL,
    is_used BOOLEAN DEFAULT NOT NULL,
    expiration_date DATE,
    discount_type DISCOUNT _TYPE NOT NULL,
    amount BIGINT,
    percent DECIMAL(5, 2) CHECK (percent BETWEEN 0 AND 100),

    CONSTRAINT check_amount_or_percent_not_null
        CHECK (amount IS NOT NULL OR percent IS NOT NULL)
    
    FOREIGN KEY (employee_id)
        REFERENCES supports(employee_id)
        ON DELETE RESTRICT
);

-- PLAN_TYPE ENUMS
CREATE TYPE PLAN_TYPE AS ENUM ('GOLDEN','VIP');
-- PLAN TABELS
CREATE TABLE plans (
    plan_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    period DATE NOT NULL, 
    price BIGINT NOT NULL,

    -- ADD realations
    employee_id INT,
    FOREIGN KEY (employee_id)
        REFERENCES supports(employee_id)
        ON DELETE RESTRICT
);

-- VIP TABELS
CREATE TABLE vips (
    vip_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL
);
