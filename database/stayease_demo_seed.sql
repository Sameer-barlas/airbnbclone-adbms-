CREATE DATABASE IF NOT EXISTS air_bnb;
USE air_bnb;

SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM reviews;
DELETE FROM payments;
DELETE FROM wishlists;
DELETE FROM messages;
DELETE FROM availability;
DELETE FROM property_amenities;
DELETE FROM bookings;
DELETE FROM properties;
DELETE FROM users;
DELETE FROM audit_log;

ALTER TABLE reviews AUTO_INCREMENT = 1;
ALTER TABLE payments AUTO_INCREMENT = 1;
ALTER TABLE wishlists AUTO_INCREMENT = 1;
ALTER TABLE messages AUTO_INCREMENT = 1;
ALTER TABLE availability AUTO_INCREMENT = 1;
ALTER TABLE bookings AUTO_INCREMENT = 1;
ALTER TABLE properties AUTO_INCREMENT = 1;
ALTER TABLE users AUTO_INCREMENT = 1;
ALTER TABLE audit_log AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

INSERT IGNORE INTO cities (city_name, country) VALUES
('Lahore', 'Pakistan'),
('Karachi', 'Pakistan'),
('Islamabad', 'Pakistan'),
('Dubai', 'UAE'),
('Istanbul', 'Turkey');

INSERT IGNORE INTO amenities (name) VALUES
('WiFi'),
('Air Conditioning'),
('Parking'),
('Swimming Pool'),
('Kitchen'),
('TV'),  
('Washing Machine'),
('Balcony'),
('Hot Water'),
('Generator');

SET @sameer_hash = '$2b$10$ERvXmyWlz0AR5a4ZXygg.eMYHtWVVr9AdjTilkakxG/lQRvfmtCaq';

INSERT INTO users (full_name, email, password_hash, phone, role, date_of_birth, is_active) VALUES
('StayEase Admin', 'fakebarlas1@gmail.com', @sameer_hash, '0300-0000001', 'admin', '1998-01-01', 1),
('Barlas Host One', 'fakebarlas2@gmail.com', @sameer_hash, '0300-0000002', 'host', '1997-03-03', 1),
('Barlas Guest One', 'fakebarlas3@gmail.com', @sameer_hash, '0300-0000003', 'guest', '2000-02-02', 1),
('Barlas Host Two', 'fakebarlas4@gmail.com', @sameer_hash, '0300-0000004', 'host', '1996-05-05', 1),
('Barlas Guest Two', 'fakebarlas5@gmail.com', @sameer_hash, '0300-0000005', 'guest', '2001-04-04', 1)
ON DUPLICATE KEY UPDATE
    full_name = VALUES(full_name),
    password_hash = VALUES(password_hash),
    phone = VALUES(phone),
    role = VALUES(role),
    date_of_birth = VALUES(date_of_birth),
    is_active = VALUES(is_active);

-- Homes are inserted into the properties table below.
INSERT INTO properties
(host_id, city_id, title, description, property_type, price_per_night, max_guests, total_rooms, latitude, longitude, is_active)
VALUES
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Skyline Loft Lahore', 'Stylish city-center apartment with bright interiors, fast WiFi, and easy access to cafes and business hubs.', 'apartment', 9000, 4, 2, 31.4697, 74.4111, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Garden Villa Gulberg', 'Luxury villa with a private garden, pool, and ample space for families and groups.', 'villa', 18000, 8, 5, 31.5204, 74.3587, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Karachi' LIMIT 1), 'Karachi Marina Studio', 'Compact but elegant studio near the coast with modern finishes and excellent views.', 'studio', 7200, 2, 1, 24.8138, 67.0305, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Islamabad' LIMIT 1), 'Islamabad Family House', 'Large family house with a kitchen, parking, and comfortable bedrooms for longer stays.', 'house', 14500, 6, 4, 33.7205, 73.0575, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Dubai' LIMIT 1), 'Dubai Marina Penthouse', 'High-rise penthouse with skyline views, balcony, and premium amenities for a luxurious stay.', 'apartment', 28000, 5, 3, 25.0800, 55.1400, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Istanbul' LIMIT 1), 'Istanbul Rooftop Room', 'Cozy rooftop room in the heart of the city with breakfast-friendly surroundings and local charm.', 'room', 12000, 2, 1, 41.0082, 28.9784, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Bahria Town Executive House', 'Executive home with modern furniture, spacious rooms, and parking for easy city access.', 'house', 13500, 6, 3, 31.3695, 74.1861, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Karachi' LIMIT 1), 'Clifton Business Apartment', 'Business-ready apartment near Clifton with a private workspace and fast internet access.', 'apartment', 10500, 4, 2, 24.8607, 67.0011, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Islamabad' LIMIT 1), 'Margalla View Villa', 'Premium villa with mountain views and luxurious interiors for discerning travelers.', 'villa', 23000, 8, 5, 33.7380, 73.0845, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Lahore Heritage Studio', 'Warm and neatly curated studio ideal for short stays and city exploration.', 'studio', 5600, 2, 1, 31.5497, 74.3436, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Dubai' LIMIT 1), 'Downtown Dubai Room', 'Comfortable room with fantastic city access and thoughtful amenities for short visits.', 'room', 16000, 2, 1, 25.2048, 55.2708, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas4@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Istanbul' LIMIT 1), 'Bosphorus Luxury Apartment', 'Spacious apartment with modern design, full kitchen, and a calm neighborhood feel.', 'apartment', 17000, 5, 2, 41.0430, 29.0094, 1);

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Parking', 'Hot Water')
WHERE p.title = 'Skyline Loft Lahore';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'Parking', 'Generator')
WHERE p.title = 'Garden Villa Gulberg';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Balcony', 'Hot Water')
WHERE p.title = 'Karachi Marina Studio';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Kitchen', 'Parking', 'Washing Machine', 'Generator')
WHERE p.title = 'Islamabad Family House';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'TV', 'Balcony')
WHERE p.title = 'Dubai Marina Penthouse';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Hot Water', 'Balcony')
WHERE p.title = 'Istanbul Rooftop Room';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Parking', 'Generator')
WHERE p.title = 'Bahria Town Executive House';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'TV', 'Hot Water')
WHERE p.title = 'Clifton Business Apartment';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'Parking', 'Balcony')
WHERE p.title = 'Margalla View Villa';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Hot Water')
WHERE p.title = 'Lahore Heritage Studio';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Parking', 'Balcony')
WHERE p.title = 'Downtown Dubai Room';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Kitchen', 'TV', 'Washing Machine', 'Balcony', 'Hot Water')
WHERE p.title = 'Bosphorus Luxury Apartment';

INSERT INTO availability (property_id, available_date, is_blocked)
SELECT p.property_id, d.available_date, 0
FROM properties p
JOIN (SELECT '2026-07-15' AS available_date UNION ALL SELECT '2026-07-16' UNION ALL SELECT '2026-07-17') d
WHERE p.title IN ('Skyline Loft Lahore', 'Garden Villa Gulberg', 'Bahria Town Executive House', 'Margalla View Villa');

INSERT INTO bookings (guest_id, property_id, check_in, check_out, num_guests, total_price, status) VALUES
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Skyline Loft Lahore'), '2026-07-20', '2026-07-24', 2, 36000.00, 'confirmed'),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Karachi Marina Studio'), '2026-08-02', '2026-08-05', 2, 21600.00, 'completed'),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Clifton Business Apartment'), '2026-08-10', '2026-08-13', 3, 31500.00, 'cancelled'),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Margalla View Villa'), '2026-09-01', '2026-09-05', 4, 92000.00, 'confirmed'),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Bosphorus Luxury Apartment'), '2026-10-05', '2026-10-08', 2, 51000.00, 'pending');

INSERT INTO payments (booking_id, amount, method, status)
SELECT b.booking_id, b.total_price, 'credit_card', 'completed'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Skyline Loft Lahore';

INSERT INTO payments (booking_id, amount, method, status)
SELECT b.booking_id, b.total_price, 'paypal', 'completed'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Karachi Marina Studio';

INSERT INTO payments (booking_id, amount, method, status)
SELECT b.booking_id, b.total_price, 'bank_transfer', 'refunded'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Clifton Business Apartment';

INSERT INTO payments (booking_id, amount, method, status)
SELECT b.booking_id, b.total_price, 'credit_card', 'completed'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Margalla View Villa';

INSERT INTO payments (booking_id, amount, method, status)
SELECT b.booking_id, b.total_price, 'cash', 'pending'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Bosphorus Luxury Apartment';

INSERT INTO reviews (booking_id, guest_id, property_id, rating, comment)
SELECT b.booking_id, b.guest_id, b.property_id, 5, 'Excellent stay, spotless home and great host communication.'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Skyline Loft Lahore';

INSERT INTO reviews (booking_id, guest_id, property_id, rating, comment)
SELECT b.booking_id, b.guest_id, b.property_id, 4, 'Comfortable and well-located, though the check-in could be smoother.'
FROM bookings b
JOIN properties p ON b.property_id = p.property_id
WHERE p.title = 'Karachi Marina Studio';

INSERT INTO messages (sender_id, receiver_id, property_id, body, is_read) VALUES
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Skyline Loft Lahore'), 'Hello, is the apartment still available for a short stay next week?', 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas2@gmail.com'), (SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Skyline Loft Lahore'), 'Yes, it is available and we can offer early check-in if needed.', 1);

INSERT INTO wishlists (guest_id, property_id) VALUES
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Dubai Marina Penthouse')),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT property_id FROM properties WHERE title = 'Garden Villa Gulberg'));
