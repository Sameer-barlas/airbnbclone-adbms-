-- =============================================================
--  AIRBNB-LIKE SYSTEM — COMPLETE ADBMS DATABASE SCHEMA
--  Compatible with MySQL 8.0+ / MySQL Workbench
--  Covers: Foreign Keys, Complex JOINs, Views, Stored Procedures,
--          Triggers, Transactions, Indexing, Aggregate Queries,
--          Constraints, No Double Booking Logic
-- =============================================================


USE air_bnb;
-- =============================================================
-- TABLE 1: CITIES
-- =============================================================
CREATE TABLE cities (
    city_id     INT AUTO_INCREMENT PRIMARY KEY,
    city_name   VARCHAR(100) NOT NULL,
    country     VARCHAR(100) NOT NULL,
    CONSTRAINT uq_city UNIQUE (city_name, country)
);

-- =============================================================
-- TABLE 2: USERS
-- NOTE: CURDATE() is not allowed in CHECK constraints in MySQL.
--       Age validation is handled in the application / stored procedure.
--       Phone format validation is done via trigger (REGEXP not reliable in CHECK).
-- =============================================================
CREATE TABLE users (
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
    -- chk_phone and chk_dob enforced via BEFORE INSERT trigger below
);

-- =============================================================
-- TABLE 3: PROPERTIES
-- FK -> users (host), FK -> cities
-- =============================================================
CREATE TABLE properties (
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

-- =============================================================
-- TABLE 4: AMENITIES
-- =============================================================
CREATE TABLE amenities (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    CONSTRAINT uq_amenity UNIQUE (name)
);

-- =============================================================
-- TABLE 5: PROPERTY_AMENITIES  (junction / bridge table)
-- =============================================================
CREATE TABLE property_amenities (
    property_id INT NOT NULL,
    amenity_id  INT NOT NULL,
    PRIMARY KEY (property_id, amenity_id),

    CONSTRAINT fk_pa_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT fk_pa_amenity  FOREIGN KEY (amenity_id)
        REFERENCES amenities(amenity_id) ON DELETE CASCADE
);

-- =============================================================
-- TABLE 6: AVAILABILITY CALENDAR
-- =============================================================
CREATE TABLE availability (
    availability_id INT AUTO_INCREMENT PRIMARY KEY,
    property_id     INT  NOT NULL,
    available_date  DATE NOT NULL,
    is_blocked      TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT fk_avail_property FOREIGN KEY (property_id)
        REFERENCES properties(property_id) ON DELETE CASCADE,
    CONSTRAINT uq_avail_date UNIQUE (property_id, available_date)
);

-- =============================================================
-- TABLE 7: BOOKINGS
-- =============================================================
CREATE TABLE bookings (
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

-- =============================================================
-- TABLE 8: PAYMENTS
-- =============================================================
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT           NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    method     ENUM('credit_card','debit_card','paypal','bank_transfer','cash') NOT NULL,
    status     ENUM('pending','completed','refunded','failed') NOT NULL DEFAULT 'pending',
    paid_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payment_booking  FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_booking_payment  UNIQUE (booking_id),
    CONSTRAINT chk_amount          CHECK (amount > 0)
);

-- =============================================================
-- TABLE 9: REVIEWS
-- =============================================================
CREATE TABLE reviews (
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

-- =============================================================
-- TABLE 10: MESSAGES
-- =============================================================
CREATE TABLE messages (
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

-- =============================================================
-- TABLE 11: WISHLISTS
-- =============================================================
CREATE TABLE wishlists (
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

-- =============================================================
-- TABLE 12: AUDIT LOG
-- =============================================================
CREATE TABLE audit_log (
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

CREATE INDEX idx_property_city     ON properties(city_id);
CREATE INDEX idx_property_price    ON properties(price_per_night);
CREATE INDEX idx_property_type     ON properties(property_type);
CREATE INDEX idx_property_host     ON properties(host_id);
CREATE INDEX idx_property_search   ON properties(city_id, property_type, price_per_night, is_active);

CREATE INDEX idx_avail_date        ON availability(property_id, available_date, is_blocked);

CREATE INDEX idx_booking_guest     ON bookings(guest_id);
CREATE INDEX idx_booking_property  ON bookings(property_id);
CREATE INDEX idx_booking_status    ON bookings(status);
CREATE INDEX idx_booking_dates     ON bookings(property_id, check_in, check_out);

CREATE INDEX idx_review_property   ON reviews(property_id);
CREATE INDEX idx_review_guest      ON reviews(guest_id);

CREATE INDEX idx_msg_receiver      ON messages(receiver_id, is_read);
CREATE INDEX idx_msg_sender        ON messages(sender_id);

CREATE INDEX idx_audit_table       ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_time        ON audit_log(action_time);


-- =============================================================
--  VIEWS
-- =============================================================

-- VIEW 1: Property listing card (search results)
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
--  STORED PROCEDURES
-- =============================================================

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_create_booking$$
DROP PROCEDURE IF EXISTS sp_cancel_booking$$
DROP PROCEDURE IF EXISTS sp_search_properties$$
DROP PROCEDURE IF EXISTS sp_host_revenue_report$$
-- ---------------------------------------------------------------
-- PROCEDURE 1: Create Booking
--   Includes: double-booking check, ACID transaction, validation
--   FIX: removed ENUM param type (not supported) -> use VARCHAR
--   FIX: removed WITH RECURSIVE subquery -> uses helper loop table
-- ---------------------------------------------------------------
CREATE PROCEDURE sp_create_booking (
    IN  p_guest_id       INT,
    IN  p_property_id    INT,
    IN  p_check_in       DATE,
    IN  p_check_out      DATE,
    IN  p_num_guests     INT,
    IN  p_payment_method VARCHAR(20),
    OUT p_booking_id     INT,
    OUT p_message        VARCHAR(255)
)
sp_create_booking: BEGIN
    DECLARE v_price_per_night DECIMAL(10,2);
    DECLARE v_max_guests      INT;
    DECLARE v_nights          INT;
    DECLARE v_total_price     DECIMAL(12,2);
    DECLARE v_conflict_count  INT DEFAULT 0;
    DECLARE v_host_id         INT;
    DECLARE v_loop_date       DATE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_booking_id = -1;
        SET p_message = 'Booking failed due to a database error. Transaction rolled back.';
    END;

    IF p_check_out <= p_check_in THEN
        SET p_booking_id = -1;
        SET p_message = 'Check-out date must be after check-in date.';
        LEAVE sp_create_booking;
    END IF;

    SELECT price_per_night, max_guests, host_id
    INTO v_price_per_night, v_max_guests, v_host_id
    FROM properties
    WHERE property_id = p_property_id AND is_active = 1;

    IF v_price_per_night IS NULL THEN
        SET p_booking_id = -1;
        SET p_message = 'Property not found or not active.';
        LEAVE sp_create_booking;
    END IF;

    IF p_num_guests > v_max_guests THEN
        SET p_booking_id = -1;
        SET p_message = CONCAT('Property allows max ', v_max_guests, ' guests.');
        LEAVE sp_create_booking;
    END IF;

    IF v_host_id = p_guest_id THEN
        SET p_booking_id = -1;
        SET p_message = 'Hosts cannot book their own property.';
        LEAVE sp_create_booking;
    END IF;

    SELECT COUNT(*) INTO v_conflict_count
    FROM bookings
    WHERE property_id = p_property_id
      AND status IN ('confirmed', 'pending')
      AND check_in < p_check_out
      AND check_out > p_check_in;

    IF v_conflict_count > 0 THEN
        SET p_booking_id = -1;
        SET p_message = 'Property already booked for the selected dates.';
        LEAVE sp_create_booking;
    END IF;

    SET v_nights = DATEDIFF(p_check_out, p_check_in);
    SET v_total_price = v_nights * v_price_per_night;

    START TRANSACTION;

        INSERT INTO bookings (guest_id, property_id, check_in, check_out, num_guests, total_price, status)
        VALUES (p_guest_id, p_property_id, p_check_in, p_check_out, p_num_guests, v_total_price, 'confirmed');

        SET p_booking_id = LAST_INSERT_ID();

        INSERT INTO payments (booking_id, amount, method, status)
        VALUES (p_booking_id, v_total_price, p_payment_method, 'completed');

        SET v_loop_date = p_check_in;

        WHILE v_loop_date < p_check_out DO
            INSERT INTO availability (property_id, available_date, is_blocked)
            VALUES (p_property_id, v_loop_date, 1)
            ON DUPLICATE KEY UPDATE is_blocked = 1;

            SET v_loop_date = DATE_ADD(v_loop_date, INTERVAL 1 DAY);
        END WHILE;

    COMMIT;

    SET p_message = CONCAT('Booking confirmed! ID: ', p_booking_id, ' | Total: PKR ', v_total_price);
END sp_create_booking$$


-- ---------------------------------------------------------------
-- PROCEDURE 2: Cancel Booking
-- ---------------------------------------------------------------
CREATE PROCEDURE sp_cancel_booking (
    IN  p_booking_id INT,
    IN  p_user_id    INT,
    OUT p_message    VARCHAR(255)
)
sp_cancel_booking: BEGIN
    DECLARE v_check_in    DATE;
    DECLARE v_check_out   DATE;
    DECLARE v_property_id INT;
    DECLARE v_guest_id    INT;
    DECLARE v_status      VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Cancellation failed. Transaction rolled back.';
    END;

    SELECT check_in, check_out, property_id, guest_id, status
    INTO   v_check_in, v_check_out, v_property_id, v_guest_id, v_status
    FROM   bookings
    WHERE  booking_id = p_booking_id;

    IF v_guest_id IS NULL THEN
        SET p_message = 'Booking not found.';
        LEAVE sp_cancel_booking;
    END IF;

    IF v_guest_id <> p_user_id THEN
        SET p_message = 'Unauthorized: You can only cancel your own bookings.';
        LEAVE sp_cancel_booking;
    END IF;

    IF v_status NOT IN ('pending', 'confirmed') THEN
        SET p_message = CONCAT('Cannot cancel a booking with status: ', v_status);
        LEAVE sp_cancel_booking;
    END IF;

    START TRANSACTION;

        UPDATE bookings SET status = 'cancelled' WHERE booking_id = p_booking_id;
        UPDATE payments SET status = 'refunded'  WHERE booking_id = p_booking_id;

        UPDATE availability
        SET    is_blocked = 0
        WHERE  property_id   = v_property_id
          AND  available_date >= v_check_in
          AND  available_date <  v_check_out;

    COMMIT;

    SET p_message = CONCAT('Booking #', p_booking_id, ' cancelled and refund initiated.');
END sp_cancel_booking$$


-- ---------------------------------------------------------------
-- PROCEDURE 3: Search Available Properties
-- ---------------------------------------------------------------
CREATE PROCEDURE sp_search_properties (
    IN p_city      VARCHAR(100),
    IN p_check_in  DATE,
    IN p_check_out DATE,
    IN p_guests    INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2)
)
BEGIN
    SELECT
        p.property_id,
        p.title,
        p.property_type,
        p.price_per_night,
        DATEDIFF(p_check_out, p_check_in) * p.price_per_night AS total_cost,
        p.max_guests,
        p.avg_rating,
        p.total_reviews,
        c.city_name,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS amenities
    FROM properties p
    JOIN cities c ON p.city_id = c.city_id
    LEFT JOIN property_amenities pa ON p.property_id = pa.property_id
    LEFT JOIN amenities          a  ON pa.amenity_id  = a.amenity_id
    WHERE p.is_active      = 1
      AND c.city_name      = p_city
      AND p.max_guests    >= p_guests
      AND p.price_per_night BETWEEN IFNULL(p_min_price, 0)
                                AND IFNULL(p_max_price, 9999999)
      AND p.property_id NOT IN (
            SELECT DISTINCT property_id
            FROM   bookings
            WHERE  status    IN ('confirmed', 'pending')
              AND  check_in  <  p_check_out
              AND  check_out >  p_check_in
      )
    GROUP BY
        p.property_id, p.title, p.property_type, p.price_per_night,
        p.max_guests, p.avg_rating, p.total_reviews, c.city_name
    ORDER BY p.avg_rating DESC, p.price_per_night ASC;
END$$


-- ---------------------------------------------------------------
-- PROCEDURE 4: Host Revenue Report (with window functions)
-- ---------------------------------------------------------------
CREATE PROCEDURE sp_host_revenue_report (
    IN p_host_id INT,
    IN p_year    INT
)
BEGIN
    SELECT
        MONTHNAME(b.check_in)                              AS month_name,
        MONTH(b.check_in)                                  AS month_num,
        COUNT(b.booking_id)                                AS total_bookings,
        SUM(b.total_price)                                 AS gross_revenue,
        ROUND(AVG(b.total_price), 2)                       AS avg_booking_value,
        ROUND(AVG(DATEDIFF(b.check_out, b.check_in)), 1)   AS avg_nights,
        SUM(COUNT(b.booking_id)) OVER (ORDER BY MONTH(b.check_in)) AS running_bookings,
        SUM(SUM(b.total_price))  OVER (ORDER BY MONTH(b.check_in)) AS running_revenue
    FROM bookings b
    JOIN properties p ON b.property_id = p.property_id
    WHERE p.host_id         = p_host_id
      AND b.status          IN ('confirmed', 'completed')
      AND YEAR(b.check_in)  = p_year
    GROUP BY month_name, month_num
    ORDER BY month_num;
END$$


DELIMITER ;


-- =============================================================
--  TRIGGERS
-- =============================================================

DELIMITER $$

-- TRIGGER 1: Validate user age and phone on INSERT
--   (replaces CURDATE() and REGEXP CHECK constraints)
CREATE TRIGGER trg_user_before_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.date_of_birth IS NOT NULL
       AND NEW.date_of_birth > DATE_SUB(CURDATE(), INTERVAL 18 YEAR) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User must be at least 18 years old.';
    END IF;

    IF NEW.phone IS NOT NULL
       AND NEW.phone NOT REGEXP '^[0-9+\\-() ]{7,20}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid phone number format.';
    END IF;
END$$


-- TRIGGER 2: After review INSERT -> update avg_rating + total_reviews
CREATE TRIGGER trg_after_review_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
    UPDATE properties
    SET avg_rating    = (SELECT ROUND(AVG(rating), 2) FROM reviews WHERE property_id = NEW.property_id),
        total_reviews = (SELECT COUNT(*)              FROM reviews WHERE property_id = NEW.property_id)
    WHERE property_id = NEW.property_id;
END$$


-- TRIGGER 3: After review UPDATE -> recalculate avg_rating
CREATE TRIGGER trg_after_review_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
    UPDATE properties
    SET avg_rating = (SELECT ROUND(AVG(rating), 2) FROM reviews WHERE property_id = NEW.property_id)
    WHERE property_id = NEW.property_id;
END$$


-- TRIGGER 4: After review DELETE -> recalculate avg_rating
CREATE TRIGGER trg_after_review_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
    UPDATE properties
    SET avg_rating    = IFNULL((SELECT ROUND(AVG(rating), 2) FROM reviews WHERE property_id = OLD.property_id), 0),
        total_reviews = (SELECT COUNT(*) FROM reviews WHERE property_id = OLD.property_id)
    WHERE property_id = OLD.property_id;
END$$


-- TRIGGER 5: Before booking INSERT -> prevent double booking at DB level
CREATE TRIGGER trg_before_booking_insert
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_conflict INT DEFAULT 0;

    SELECT COUNT(*) INTO v_conflict
    FROM   bookings
    WHERE  property_id = NEW.property_id
      AND  status      IN ('confirmed', 'pending')
      AND  check_in    <  NEW.check_out
      AND  check_out   >  NEW.check_in;

    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'DOUBLE BOOKING PREVENTED: Property already booked for these dates.';
    END IF;
END$$


-- TRIGGER 6: After booking status UPDATE -> write to audit_log
CREATE TRIGGER trg_booking_status_change
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO audit_log (user_id, action, table_name, record_id, old_values, new_values)
        VALUES (
            NEW.guest_id,
            CONCAT('BOOKING_STATUS_CHANGE: ', OLD.status, ' -> ', NEW.status),
            'bookings',
            NEW.booking_id,
            JSON_OBJECT('status', OLD.status, 'total_price', OLD.total_price),
            JSON_OBJECT('status', NEW.status, 'total_price', NEW.total_price)
        );
    END IF;
END$$


-- TRIGGER 7: After user INSERT -> audit log
CREATE TRIGGER trg_user_registration_log
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, new_values)
    VALUES (
        NEW.user_id,
        'USER_REGISTERED',
        'users',
        NEW.user_id,
        JSON_OBJECT('email', NEW.email, 'role', NEW.role, 'created_at', NEW.created_at)
    );
END$$


-- TRIGGER 8: Before user DELETE -> archive to audit_log
CREATE TRIGGER trg_user_delete_log
BEFORE DELETE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (user_id, action, table_name, record_id, old_values)
    VALUES (
        OLD.user_id,
        'USER_DELETED',
        'users',
        OLD.user_id,
        JSON_OBJECT('email', OLD.email, 'role', OLD.role, 'created_at', OLD.created_at)
    );
END$$


DELIMITER ;


-- =============================================================
--  SAMPLE DATA
-- =============================================================

INSERT INTO cities (city_name, country) VALUES
('Lahore',    'Pakistan'),
('Karachi',   'Pakistan'),
('Islamabad', 'Pakistan'),
('Dubai',     'UAE'),
('Istanbul',  'Turkey');

INSERT INTO users (full_name, email, password_hash, phone, role, date_of_birth) VALUES
('Ali Hassan',   'ali@mail.com',    SHA2('pass123', 256), '0300-1111111', 'host',  '1990-05-15'),
('Sara Khan',    'sara@mail.com',   SHA2('pass123', 256), '0301-2222222', 'guest', '1995-08-20'),
('Ahmed Raza',   'ahmed@mail.com',  SHA2('pass123', 256), '0302-3333333', 'host',  '1985-03-10'),
('Fatima Malik', 'fatima@mail.com', SHA2('pass123', 256), '0303-4444444', 'guest', '1998-11-25'),
('Omar Sheikh',  'omar@mail.com',   SHA2('pass123', 256), '0304-5555555', 'admin', '1988-07-04');

INSERT INTO amenities (name) VALUES
('WiFi'), ('Air Conditioning'), ('Parking'), ('Swimming Pool'),
('Kitchen'), ('TV'), ('Washing Machine'), ('Balcony'), ('Hot Water'), ('Generator');

INSERT INTO properties (host_id, city_id, title, description, property_type, price_per_night, max_guests, total_rooms) VALUES
(1, 1, 'Cozy Apartment in DHA Lahore',  'Modern 2BR apartment in DHA Phase 5',      'apartment', 5000.00,  4,  2),
(1, 1, 'Luxury Villa Gulberg',           'Spacious villa with pool in Gulberg III',  'villa',    15000.00, 10,  5),
(3, 2, 'Studio Flat Clifton Karachi',    'Neat studio near Clifton Beach',           'studio',   3500.00,   2,  1),
(3, 3, 'Islamabad F-7 House',            'Full house in F-7 sector near Blue Area',  'house',    8000.00,   8,  4),
(1, 4, 'Dubai Marina Apartment',         'High-rise apartment with sea view',        'apartment',25000.00,  3,  2);

INSERT INTO property_amenities VALUES
(1,1),(1,2),(1,3),(1,5),(1,6),(1,9),
(2,1),(2,2),(2,3),(2,4),(2,5),(2,6),(2,7),(2,8),(2,9),(2,10),
(3,1),(3,2),(3,5),(3,9),
(4,1),(4,2),(4,3),(4,5),(4,6),(4,7),(4,9),(4,10),
(5,1),(5,2),(5,3),(5,4),(5,5),(5,6);

INSERT INTO availability (property_id, available_date, is_blocked) VALUES
(1,'2025-06-01',0),(1,'2025-06-02',0),(1,'2025-06-03',0),
(2,'2025-06-01',0),(2,'2025-06-02',0),
(3,'2025-06-01',0),(3,'2025-06-02',0);

-- Disable double-booking trigger temporarily to insert test bookings directly
SET @OLD_SQL_MODE = @@SQL_MODE;
SET SQL_MODE = '';

INSERT INTO bookings (guest_id, property_id, check_in, check_out, num_guests, total_price, status) VALUES
(2, 1, '2025-07-01', '2025-07-05', 2, 20000.00, 'confirmed'),
(4, 3, '2025-07-10', '2025-07-12', 1,  7000.00, 'confirmed'),
(2, 4, '2025-08-01', '2025-08-03', 4, 16000.00, 'completed');

SET SQL_MODE = @OLD_SQL_MODE;

INSERT INTO payments (booking_id, amount, method, status) VALUES
(1, 20000.00, 'credit_card',   'completed'),
(2,  7000.00, 'paypal',        'completed'),
(3, 16000.00, 'bank_transfer', 'completed');

INSERT INTO reviews (booking_id, guest_id, property_id, rating, comment) VALUES
(3, 2, 4, 5, 'Amazing house! Very clean and well-located. Highly recommend.'),
(2, 4, 3, 4, 'Nice studio, good value for money. WiFi was a bit slow.');


-- =============================================================
--  AGGREGATE QUERY EXAMPLES
-- =============================================================

-- Q1: Top 5 highest-rated properties
SELECT
    p.title,
    c.city_name,
    p.avg_rating,
    p.total_reviews,
    p.price_per_night
FROM properties p
JOIN cities c ON p.city_id = c.city_id
WHERE p.total_reviews > 0
ORDER BY p.avg_rating DESC, p.total_reviews DESC
LIMIT 5;

-- Q2: Revenue per host (HAVING filters active hosts only)
SELECT
    u.full_name              AS host_name,
    COUNT(b.booking_id)      AS total_bookings,
    SUM(b.total_price)       AS total_revenue,
    ROUND(AVG(b.total_price), 2) AS avg_booking_value,
    MAX(b.total_price)       AS highest_booking
FROM users      u
JOIN properties p  ON u.user_id     = p.host_id
JOIN bookings   b  ON p.property_id = b.property_id
WHERE b.status IN ('confirmed', 'completed')
  AND u.role = 'host'
GROUP BY u.user_id, u.full_name
HAVING total_bookings >= 1
ORDER BY total_revenue DESC;

-- Q3: Most popular cities by booking count
SELECT
    c.city_name,
    c.country,
    COUNT(b.booking_id)         AS total_bookings,
    SUM(b.total_price)          AS total_revenue,
    ROUND(AVG(p.avg_rating), 2) AS avg_property_rating
FROM cities     c
JOIN properties p  ON c.city_id     = p.city_id
JOIN bookings   b  ON p.property_id = b.property_id
WHERE b.status IN ('confirmed', 'completed')
GROUP BY c.city_id, c.city_name, c.country
ORDER BY total_bookings DESC;

-- Q4: Monthly booking trend with running total (window function)
SELECT
    DATE_FORMAT(booked_at, '%Y-%m') AS month,
    COUNT(*)                        AS monthly_bookings,
    SUM(total_price)                AS monthly_revenue,
    SUM(COUNT(*)) OVER (
        ORDER BY DATE_FORMAT(booked_at, '%Y-%m')
    )                               AS cumulative_bookings
FROM bookings
WHERE status IN ('confirmed', 'completed')
GROUP BY month
ORDER BY month;

-- Q5: Complex JOIN - Guest booking history with review status
SELECT
    u.full_name   AS guest_name,
    p.title       AS property,
    c.city_name,
    b.check_in,
    b.check_out,
    DATEDIFF(b.check_out, b.check_in) AS nights,
    b.total_price,
    b.status      AS booking_status,
    py.method     AS payment_method,
    CASE WHEN r.review_id IS NOT NULL THEN 'Yes' ELSE 'No' END AS has_review,
    r.rating
FROM users      u
JOIN bookings   b  ON u.user_id     = b.guest_id
JOIN properties p  ON b.property_id = p.property_id
JOIN cities     c  ON p.city_id     = c.city_id
JOIN payments   py ON b.booking_id  = py.booking_id
LEFT JOIN reviews r ON b.booking_id = r.booking_id
WHERE u.user_id = 2
ORDER BY b.booked_at DESC;

-- =============================================================
--  END OF SCHEMA
-- =============================================================
