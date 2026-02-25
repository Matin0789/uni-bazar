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