-- =============================================================
--  STAYEASE — TiDB CLOUD / TiDB SERVERLESS DATABASE SCHEMA
-- =============================================================
--  Compatible with: TiDB Serverless, TiDB Dedicated, MySQL 8.0+
--  Note: TiDB does not support Stored Procedures or Triggers.
--  All business logic (ACID booking transactions, double-booking checks,
--  availability blocking, revenue reports, age validation, and rating
--  recalculations) is handled natively by the StayEase Node.js application layer.
-- =============================================================

CREATE DATABASE IF NOT EXISTS air_bnb;
USE air_bnb;

-- -------------------------------------------------------------
-- TABLE 1: CITIES
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cities (
    city_id     INT AUTO_INCREMENT PRIMARY KEY,
    city_name   VARCHAR(100) NOT NULL,
    country     VARCHAR(100) NOT NULL,
    CONSTRAINT uq_city UNIQUE (city_name, country)
);

-- -------------------------------------------------------------
-- TABLE 2: USERS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(150)  NOT NULL,
    email         VARCHAR(255)  NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    phone         VARCHAR(20),
    role          ENUM('guest','host','admin') NOT NULL DEFAULT 'guest',
    date_of_birth DATE,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_email UNIQUE (email)
);

-- -------------------------------------------------------------
-- TABLE 3: PROPERTIES
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS properties (
    property_id     INT AUTO_INCREMENT PRIMARY KEY,
    host_id         INT           NOT NULL,
    city_id         INT           NOT NULL,
    title           VARCHAR(255)  NOT NULL,
    description     TEXT,
    property_type   ENUM('apartment','house','villa','studio','room') NOT NULL,
    price_per_night DECIMAL(10,2) NOT NULL,
    max_guests      INT           NOT NULL DEFAULT 1,
    total_rooms     INT           NOT NULL DEFAULT 1,
    latitude        DECIMAL(9,6),
    longitude       DECIMAL(9,6),
    avg_rating      DECIMAL(3,2)  DEFAULT 0.00,
    total_reviews   INT           DEFAULT 0,
    is_active       TINYINT(1)    NOT NULL DEFAULT 1,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_property_host FOREIGN KEY (host_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_property_city FOREIGN KEY (city_id)
        REFERENCES cities(city_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_price      CHECK (price_per_night > 0),
    CONSTRAINT chk_max_guests CHECK (max_guests BETWEEN 1 AND 50),
    CONSTRAINT chk_rooms      CHECK (total_rooms >= 1)
);

-- -------------------------------------------------------------
-- TABLE 4: AMENITIES
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS amenities (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    CONSTRAINT uq_amenity UNIQUE (name)
);

-- -------------------------------------------------------------
-- TABLE 5: PROPERTY_AMENITIES (Junction Table)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS property_amenities (
    property_id INT NOT NULL,
    amenity_id  INT NOT NULL,
    PRIMARY KEY (property_id, amenity_id),
    CONSTRAINT fk_pa_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT fk_pa_amenity  FOREIGN KEY (amenity_id)
        REFERENCES amenities(amenity_id) ON DELETE CASCADE
);

-- -------------------------------------------------------------
-- TABLE 6: AVAILABILITY CALENDAR
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id     INT  NOT NULL,
    available_date  DATE NOT NULL,
    is_blocked      TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_avail_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT uq_avail_date UNIQUE (property_id, available_date)
);

-- -------------------------------------------------------------
-- TABLE 7: BOOKINGS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
    booking_id   INT AUTO_INCREMENT PRIMARY KEY,
    guest_id     INT           NOT NULL,
    property_id  INT           NOT NULL,
    check_in     DATE          NOT NULL,
    check_out    DATE          NOT NULL,
    num_guests   INT           NOT NULL DEFAULT 1,
    total_price  DECIMAL(12,2) NOT NULL,
    status       ENUM('pending','confirmed','cancelled','completed') NOT NULL DEFAULT 'pending',
    booked_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_guest    FOREIGN KEY (guest_id)
        REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_booking_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_dates       CHECK (check_out > check_in),
    CONSTRAINT chk_num_guests  CHECK (num_guests >= 1),
    CONSTRAINT chk_total_price CHECK (total_price >= 0)
);

-- -------------------------------------------------------------
-- TABLE 8: PAYMENTS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT           NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    method     ENUM('credit_card','debit_card','paypal','bank_transfer','cash') NOT NULL,
    status     ENUM('pending','completed','refunded','failed') NOT NULL DEFAULT 'pending',
    paid_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_booking_payment UNIQUE (booking_id),
    CONSTRAINT chk_amount         CHECK (amount > 0)
);

-- -------------------------------------------------------------
-- TABLE 9: REVIEWS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    review_id   INT AUTO_INCREMENT PRIMARY KEY,
    booking_id  INT     NOT NULL,
    guest_id    INT     NOT NULL,
    property_id INT     NOT NULL,
    rating      TINYINT NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_review_booking  FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_guest    FOREIGN KEY (guest_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT uq_review_booking  UNIQUE (booking_id),
    CONSTRAINT chk_rating         CHECK (rating BETWEEN 1 AND 5)
);

-- -------------------------------------------------------------
-- TABLE 10: MESSAGES
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS messages (
    message_id  INT AUTO_INCREMENT PRIMARY KEY,
    sender_id   INT  NOT NULL,
    receiver_id INT  NOT NULL,
    property_id INT,
    body        TEXT NOT NULL,
    sent_at     TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_read     TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT fk_msg_sender   FOREIGN KEY (sender_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_receiver FOREIGN KEY (receiver_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE SET NULL,
    CONSTRAINT chk_no_self_msg CHECK (sender_id <> receiver_id)
);

-- -------------------------------------------------------------
-- TABLE 11: WISHLISTS
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS wishlists (
    wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id    INT NOT NULL,
    property_id INT NOT NULL,
    saved_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_wl_guest    FOREIGN KEY (guest_id)
        REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_wl_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT uq_wishlist    UNIQUE (guest_id, property_id)
);

-- -------------------------------------------------------------
-- TABLE 12: AUDIT LOG
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT,
    action      VARCHAR(50) NOT NULL,
    table_name  VARCHAR(50) NOT NULL,
    record_id   INT,
    old_values  JSON,
    new_values  JSON,
    action_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_log_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON DELETE SET NULL
);


-- =============================================================
--  INDEXES
-- =============================================================
CREATE INDEX IF NOT EXISTS idx_property_city     ON properties(city_id);
CREATE INDEX IF NOT EXISTS idx_property_price    ON properties(price_per_night);
CREATE INDEX IF NOT EXISTS idx_property_type     ON properties(property_type);
CREATE INDEX IF NOT EXISTS idx_property_host     ON properties(host_id);
CREATE INDEX IF NOT EXISTS idx_property_search   ON properties(city_id, property_type, price_per_night, is_active);

CREATE INDEX IF NOT EXISTS idx_avail_date        ON availability(property_id, available_date, is_blocked);

CREATE INDEX IF NOT EXISTS idx_booking_guest     ON bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_booking_property  ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_booking_status    ON bookings(status);
CREATE INDEX IF NOT EXISTS idx_booking_dates     ON bookings(property_id, check_in, check_out);

CREATE INDEX IF NOT EXISTS idx_review_property   ON reviews(property_id);
CREATE INDEX IF NOT EXISTS idx_review_guest      ON reviews(guest_id);

CREATE INDEX IF NOT EXISTS idx_msg_receiver      ON messages(receiver_id, is_read);
CREATE INDEX IF NOT EXISTS idx_msg_sender        ON messages(sender_id);

CREATE INDEX IF NOT EXISTS idx_audit_table       ON audit_log(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_time        ON audit_log(action_time);


-- =============================================================
--  VIEWS
-- =============================================================

-- VIEW 1: Property listing card (search & homepage)
CREATE OR REPLACE VIEW vw_property_listing AS
SELECT
    p.property_id,
    p.title,
    p.property_type,
    p.price_per_night,
    p.max_guests,
    p.avg_rating,
    p.total_reviews,
    c.city_name,
    c.country,
    u.full_name AS host_name,
    u.user_id   AS host_id,
    GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', ') AS amenities
FROM properties p
JOIN cities  c  ON p.city_id  = c.city_id
JOIN users   u  ON p.host_id  = u.user_id
LEFT JOIN property_amenities pa ON p.property_id = pa.property_id
LEFT JOIN amenities          a  ON pa.amenity_id  = a.amenity_id
WHERE p.is_active = 1
GROUP BY
    p.property_id, p.title, p.property_type, p.price_per_night,
    p.max_guests, p.avg_rating, p.total_reviews,
    c.city_name, c.country, u.full_name, u.user_id;

-- VIEW 2: Full booking details (joins 6 tables)
CREATE OR REPLACE VIEW vw_booking_details AS
SELECT
    b.booking_id,
    b.status,
    b.check_in,
    b.check_out,
    DATEDIFF(b.check_out, b.check_in) AS nights,
    b.total_price,
    b.num_guests,
    b.booked_at,
    g.user_id   AS guest_id,
    g.full_name AS guest_name,
    g.email     AS guest_email,
    p.property_id,
    p.title     AS property_title,
    c.city_name,
    c.country,
    h.user_id   AS host_id,
    h.full_name AS host_name,
    py.status   AS payment_status,
    py.method   AS payment_method
FROM bookings   b
JOIN users      g  ON b.guest_id    = g.user_id
JOIN properties p  ON b.property_id = p.property_id
JOIN cities     c  ON p.city_id     = c.city_id
JOIN users      h  ON p.host_id     = h.user_id
LEFT JOIN payments py ON b.booking_id = py.booking_id;

-- VIEW 3: Host dashboard summary
CREATE OR REPLACE VIEW vw_host_dashboard AS
SELECT
    u.user_id   AS host_id,
    u.full_name AS host_name,
    COUNT(DISTINCT p.property_id)  AS total_properties,
    COUNT(DISTINCT b.booking_id)   AS total_bookings,
    IFNULL(SUM(CASE WHEN b.status = 'confirmed' THEN b.total_price END), 0) AS total_revenue,
    ROUND(AVG(r.rating), 2)        AS avg_rating,
    COUNT(DISTINCT r.review_id)    AS total_reviews
FROM users u
LEFT JOIN properties p ON u.user_id     = p.host_id
LEFT JOIN bookings   b ON p.property_id = b.property_id
LEFT JOIN reviews    r ON p.property_id = r.property_id
WHERE u.role = 'host'
GROUP BY u.user_id, u.full_name;

-- VIEW 4: Admin revenue report by city and month
CREATE OR REPLACE VIEW vw_revenue_by_city_month AS
SELECT
    c.city_name,
    c.country,
    YEAR(b.booked_at)            AS booking_year,
    MONTH(b.booked_at)           AS booking_month,
    COUNT(b.booking_id)          AS total_bookings,
    SUM(b.total_price)           AS total_revenue,
    ROUND(AVG(b.total_price), 2) AS avg_booking_value
FROM bookings   b
JOIN properties p ON b.property_id = p.property_id
JOIN cities     c ON p.city_id     = c.city_id
WHERE b.status IN ('confirmed', 'completed')
GROUP BY c.city_name, c.country, booking_year, booking_month;

-- VIEW 5: Currently unavailable properties
CREATE OR REPLACE VIEW vw_unavailable_properties AS
SELECT DISTINCT property_id
FROM bookings
WHERE status IN ('confirmed', 'pending')
  AND check_in  < DATE_ADD(CURDATE(), INTERVAL 30 DAY)
  AND check_out > CURDATE();


-- =============================================================
--  DEFAULT SEED DATA
-- =============================================================

INSERT IGNORE INTO cities (city_name, country) VALUES
('Lahore',    'Pakistan'),
('Karachi',   'Pakistan'),
('Islamabad', 'Pakistan'),
('Dubai',     'UAE'),
('Istanbul',  'Turkey');

INSERT IGNORE INTO amenities (name) VALUES
('WiFi'), ('Air Conditioning'), ('Parking'), ('Swimming Pool'),
('Kitchen'), ('TV'), ('Washing Machine'), ('Balcony'), ('Hot Water'), ('Generator');
