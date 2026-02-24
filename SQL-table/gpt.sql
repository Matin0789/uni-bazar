-- ==============
-- Core: Users
-- ==============
CREATE TABLE app_user (
  user_id           BIGSERIAL PRIMARY KEY,
  fname             VARCHAR(100),
  lname             VARCHAR(100),
  email             VARCHAR(255) UNIQUE NOT NULL,
  phone             VARCHAR(30),
  pass_hash         TEXT NOT NULL,
  image_url         TEXT,
  status_code       SMALLINT NOT NULL DEFAULT 1,
  -- From diagram: "Suspended or blocked; 1..5 suspended, 6 blocked"
  CHECK (status_code BETWEEN 1 AND 6)
);

-- Wallet (User OWNS 1..1 wallet)
CREATE TABLE wallet (
  user_id           BIGINT PRIMARY KEY REFERENCES app_user(user_id) ON DELETE CASCADE,
  balance           NUMERIC(12,2) NOT NULL DEFAULT 0
);

-- ==============
-- Booths & Employees
-- ==============
CREATE TABLE booth (
  booth_id          BIGSERIAL PRIMARY KEY,
  name              VARCHAR(200) NOT NULL,
  description       TEXT,
  image_url         TEXT,
  owner_user_id     BIGINT UNIQUE REFERENCES app_user(user_id) ON DELETE SET NULL
  -- diagram implies "BECOMES_OWNER_OF"/"OWNS" for booth; unique owner per booth.
);

CREATE TABLE employee (
  employee_id       BIGSERIAL PRIMARY KEY,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  fname             VARCHAR(100),
  lname             VARCHAR(100),
  image_url         TEXT,
  perm_no           SMALLINT NOT NULL DEFAULT 0,
  -- perm bitmask described in diagram (1,2,4,8 -> up to 15)
  CHECK (perm_no BETWEEN 0 AND 15)
);

-- Time_Table (Booth HAS N time slots)
CREATE TABLE time_table (
  time_table_id     BIGSERIAL PRIMARY KEY,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  start_time        TIME NOT NULL,
  end_time          TIME NOT NULL,
  CHECK (end_time > start_time)
);

-- ==============
-- Products / Services / Goods
-- ==============
CREATE TABLE product (
  product_id        BIGSERIAL PRIMARY KEY,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  title             VARCHAR(255) NOT NULL,
  description       TEXT,
  image_url         TEXT,
  stock_quantity    INTEGER NOT NULL DEFAULT 0,
  status            VARCHAR(30) DEFAULT 'Active'
);

-- Price history (Product HAS price history)
CREATE TABLE price_history (
  price_history_id  BIGSERIAL PRIMARY KEY,
  product_id        BIGINT NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  price             NUMERIC(12,2) NOT NULL,
  unit              VARCHAR(50),
  valid_from        TIMESTAMP NOT NULL DEFAULT now(),
  valid_to          TIMESTAMP
);

-- ==============
-- Cart / Locked Cart / Items
-- ==============
CREATE TABLE cart (
  cart_id           BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL UNIQUE REFERENCES app_user(user_id) ON DELETE CASCADE,
  discount_code_id  BIGINT NULL, -- preview purpose (optional)
  created_at        TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE locked_cart (
  cart_id           BIGINT PRIMARY KEY REFERENCES cart(cart_id) ON DELETE CASCADE,
  lock_end_date     TIMESTAMP NOT NULL
);

CREATE TABLE cart_item (
  cart_item_id      BIGSERIAL PRIMARY KEY,
  cart_id           BIGINT NOT NULL REFERENCES cart(cart_id) ON DELETE CASCADE,
  product_id        BIGINT NOT NULL REFERENCES product(product_id) ON DELETE RESTRICT,
  quantity          INTEGER NOT NULL CHECK (quantity > 0),
  reserved_start    TIMESTAMP,
  reserved_end      TIMESTAMP
);

-- ==============
-- Orders / Items / Payments / Shipments
-- ==============
CREATE TABLE discount_code (
  discount_code_id  BIGSERIAL PRIMARY KEY,
  code              VARCHAR(50) UNIQUE NOT NULL,
  fixed_amount      NUMERIC(12,2),
  percentage        NUMERIC(5,2),
  start_date        DATE,
  expiration_date   DATE,
  is_used           BOOLEAN NOT NULL DEFAULT FALSE,
  CHECK (
    (fixed_amount IS NOT NULL AND percentage IS NULL)
    OR
    (fixed_amount IS NULL AND percentage IS NOT NULL)
  )
);

CREATE TABLE "order" (
  order_id          BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE RESTRICT,
  order_date        TIMESTAMP NOT NULL DEFAULT now(),
  total_amount      NUMERIC(12,2) NOT NULL DEFAULT 0,
  final_amount      NUMERIC(12,2), -- diagram: "Only for VIP users"
  status            VARCHAR(20) NOT NULL DEFAULT 'Pending',
  tracking_code     VARCHAR(100),
  discount_code_id  BIGINT NULL REFERENCES discount_code(discount_code_id) ON DELETE SET NULL
);

CREATE TABLE order_item (
  order_item_id     BIGSERIAL PRIMARY KEY,
  order_id          BIGINT NOT NULL REFERENCES "order"(order_id) ON DELETE CASCADE,
  product_id        BIGINT NOT NULL REFERENCES product(product_id) ON DELETE RESTRICT,
  unit_price        NUMERIC(12,2) NOT NULL,
  quantity          INTEGER NOT NULL CHECK (quantity > 0),
  unit              VARCHAR(50)
);

CREATE TABLE payment (
  payment_id        BIGSERIAL PRIMARY KEY,
  order_id          BIGINT NOT NULL REFERENCES "order"(order_id) ON DELETE CASCADE,
  payment_date      TIMESTAMP NOT NULL DEFAULT now(),
  amount            NUMERIC(12,2) NOT NULL,
  payment_method    VARCHAR(20) NOT NULL,   -- Online / Wallet
  payment_status    VARCHAR(20) NOT NULL,   -- Success / Failed / Pending
  transaction_ref   VARCHAR(255) UNIQUE
);

CREATE TABLE shipment (
  shipment_id       BIGSERIAL PRIMARY KEY,
  order_id          BIGINT NOT NULL UNIQUE REFERENCES "order"(order_id) ON DELETE CASCADE,
  shipment_date     TIMESTAMP,
  shipment_method   VARCHAR(50),
  receiver_name     VARCHAR(200),
  receiver_phone    VARCHAR(30),
  province          VARCHAR(100),
  city              VARCHAR(100),
  street            VARCHAR(255),
  postal_code       VARCHAR(20),
  address           TEXT
);

-- ==============
-- Reviews / Comments / Ratings (User evaluates Product/Booth)
-- ==============
CREATE TABLE review (
  review_id         BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  product_id        BIGINT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  booth_id          BIGINT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  rating            SMALLINT CHECK (rating BETWEEN 1 AND 5),
  comment           TEXT,
  created_at        TIMESTAMP NOT NULL DEFAULT now(),
  CHECK (
    (product_id IS NOT NULL AND booth_id IS NULL)
    OR
    (product_id IS NULL AND booth_id IS NOT NULL)
  )
);

-- Bookmarks (User BOOKMARKS Product) M:N
CREATE TABLE product_bookmark (
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  product_id        BIGINT NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  created_at        TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

-- Views (User VIEWS Product/Booth) M:N with date
CREATE TABLE product_view (
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  product_id        BIGINT NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
  viewed_at         TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id, viewed_at)
);

CREATE TABLE booth_view (
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  viewed_at         TIMESTAMP NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, booth_id, viewed_at)
);

-- ==============
-- Chat / Messages (User OWNS chat; chat contains messages)
-- ==============
CREATE TABLE chat (
  chat_id           BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  created_at        TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE message (
  message_id        BIGSERIAL PRIMARY KEY,
  chat_id           BIGINT NOT NULL REFERENCES chat(chat_id) ON DELETE CASCADE,
  sender_type       VARCHAR(20) NOT NULL, -- e.g., 'User','Support','Employee'
  content           TEXT NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT now()
);

-- ==============
-- Support & Requests (Page_Request, Booth_Request, Join_Request)
-- ==============
CREATE TABLE support_request (
  support_request_id BIGSERIAL PRIMARY KEY,
  user_id            BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  support_reason     TEXT,
  status             VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE booth_request (
  booth_request_id   BIGSERIAL PRIMARY KEY,
  user_id            BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  reason             TEXT,
  status             VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE page_request (
  page_request_id    BIGSERIAL PRIMARY KEY,
  user_id            BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  reason             TEXT,
  status             VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE join_request (
  join_request_id    BIGSERIAL PRIMARY KEY,
  user_id            BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  booth_id           BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  status             VARCHAR(30) NOT NULL DEFAULT 'Pending',
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

-- ==============
-- Badges / Golden Booth / Stories
-- ==============
CREATE TABLE badge (
  badge_id          BIGSERIAL PRIMARY KEY,
  name              VARCHAR(100) NOT NULL
);

CREATE TABLE badge_approval (
  badge_approval_id BIGSERIAL PRIMARY KEY,
  badge_id          BIGINT NOT NULL REFERENCES badge(badge_id) ON DELETE CASCADE,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  status            VARCHAR(30) NOT NULL DEFAULT 'Pending',
  start_date        DATE,
  end_date          DATE
);

CREATE TABLE golden_booth (
  booth_id          BIGINT PRIMARY KEY REFERENCES booth(booth_id) ON DELETE CASCADE,
  start_date        DATE,
  end_date          DATE
);

CREATE TABLE story (
  story_id          BIGSERIAL PRIMARY KEY,
  booth_id          BIGINT NOT NULL REFERENCES booth(booth_id) ON DELETE CASCADE,
  picture_url       TEXT,
  content           TEXT,
  created_at        TIMESTAMP NOT NULL DEFAULT now()
);

-- ==============
-- VIP / Plans
-- ==============
CREATE TABLE plan (
  plan_id           BIGSERIAL PRIMARY KEY,
  plan_name         VARCHAR(100) NOT NULL,  -- Golden_Plan / VIP_Plan
  period_days       INTEGER NOT NULL CHECK (period_days > 0),
  price             NUMERIC(12,2) NOT NULL,
  end_date          DATE
);

CREATE TABLE user_plan (
  user_plan_id      BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  plan_id           BIGINT NOT NULL REFERENCES plan(plan_id) ON DELETE RESTRICT,
  start_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  end_date          DATE NOT NULL,
  UNIQUE (user_id, plan_id, start_date)
);

-- ==============
-- Action Log / Events
-- ==============
CREATE TABLE action_log (
  log_id            BIGSERIAL PRIMARY KEY,
  user_id           BIGINT REFERENCES app_user(user_id) ON DELETE SET NULL,
  action_type       VARCHAR(50) NOT NULL,
  description       TEXT,
  ip_address        VARCHAR(60),
  ts               TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE event (
  event_id          BIGSERIAL PRIMARY KEY,
  user_id           BIGINT NOT NULL REFERENCES app_user(user_id) ON DELETE CASCADE,
  session_id        VARCHAR(100),
  event_type        VARCHAR(30) NOT NULL,   -- VIEW_BOOTH / VIEW_PRODUCT / ADD_TO_CART / PURCHASE
  event_timestamp   TIMESTAMP NOT NULL DEFAULT now(),
  booth_id          BIGINT REFERENCES booth(booth_id) ON DELETE SET NULL,
  product_id        BIGINT REFERENCES product(product_id) ON DELETE SET NULL
);