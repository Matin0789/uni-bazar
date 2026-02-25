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
    status_count INT CHECK (status_count BETWEEN 0 AND 6)
    status_end_date DATE
)

-- SUPPORT TABLES
CREATE TABLE supports (
    Employee_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname VARCHAR(100) NOT NULL,
    Lname VARCHAR(100) NOT NULL,
    image_url VARCHAR(200),
    password VARCHAR(512)
)

-- ACTION_LOG TABLES
CREATE TABLE action_logs (
    log_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ip_address INET NOT NULL,
    action_type VARCHAR(100),
    description TEXT,
    timestamp TIMESTAMP
)

-- DISCOUNT_TYPE ENUMS
CREATE TYPE DISCOUNT_TYPE AS ENUM ('FIXED', 'PERCENTAGE');
-- DISCOUNT_CODE TABLES
CREATE TYPE discount_codes (
    code_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    is_used BOOLEAN DEFAULT NOT NULL,
    expiration_date DATE,
    discount_type DISCOUNT _TYPE NOT NULL,
    amount BIGINT,
    percent DECIMAL(5, 2) CHECK (percent BETWEEN 0 AND 100),

    CONSTRAINT check_amount_or_percent_not_null
        CHECK (amount IS NOT NULL OR percent IS NOT NULL)
)
CREATE TABLE vips (
    vip_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL
);
