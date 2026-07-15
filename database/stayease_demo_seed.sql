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
('Barlas Guest One', 'fakebarlas2@gmail.com', @sameer_hash, '0300-0000002', 'guest', '2000-02-02', 1),
('Barlas Host One', 'fakebarlas3@gmail.com', @sameer_hash, '0300-0000003', 'host', '1997-03-03', 1),
('Barlas Guest Two', 'fakebarlas4@gmail.com', @sameer_hash, '0300-0000004', 'guest', '2001-04-04', 1),
('Barlas Host Two', 'fakebarlas5@gmail.com', @sameer_hash, '0300-0000005', 'host', '1996-05-05', 1);

INSERT INTO properties
(host_id, city_id, title, description, property_type, price_per_night, max_guests, total_rooms, latitude, longitude, is_active)
VALUES
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Rosewood Apartment DHA Lahore', 'Rosewood Apartment DHA Lahore is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'apartment', 8500, 4, 2, 31.4697, 74.4111, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Gulberg Premium Villa', 'Gulberg Premium Villa is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'villa', 18000, 8, 5, 31.5204, 74.3587, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Karachi' LIMIT 1), 'Clifton Sea View Studio', 'Clifton Sea View Studio is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'studio', 6500, 2, 1, 24.8138, 67.0305, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Islamabad' LIMIT 1), 'F-7 Family House Islamabad', 'F-7 Family House Islamabad is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'house', 14000, 7, 4, 33.7205, 73.0575, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Dubai' LIMIT 1), 'Dubai Marina Skyline Apartment', 'Dubai Marina Skyline Apartment is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'apartment', 26000, 5, 2, 25.0800, 55.1400, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Istanbul' LIMIT 1), 'Istanbul Old Town Suite', 'Istanbul Old Town Suite is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'room', 11000, 3, 1, 41.0082, 28.9784, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Bahria Town Modern House', 'Bahria Town Modern House is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'house', 12500, 6, 3, 31.3695, 74.1861, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Karachi' LIMIT 1), 'Karachi Executive Apartment', 'Karachi Executive Apartment is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'apartment', 9500, 4, 2, 24.8607, 67.0011, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Islamabad' LIMIT 1), 'Margalla View Villa Islamabad', 'Margalla View Villa Islamabad is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'villa', 22000, 9, 5, 33.7380, 73.0845, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'Lahore Garden Studio', 'Lahore Garden Studio is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'studio', 5200, 2, 1, 31.5497, 74.3436, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Dubai' LIMIT 1), 'Dubai Downtown Luxury Room', 'Dubai Downtown Luxury Room is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'room', 15500, 2, 1, 25.2048, 55.2708, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Istanbul' LIMIT 1), 'Bosphorus Apartment Istanbul', 'Bosphorus Apartment Istanbul is a premium StayEase listing with verified amenities, comfortable rooms, and a clean guest-ready setup.', 'apartment', 16500, 5, 2, 41.0430, 29.0094, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Lahore' LIMIT 1), 'DHA Executive Apartment Lahore', 'DHA Executive Apartment Lahore is a furnished host listing with bright rooms, fast WiFi, secure parking, and easy access to cafes and shopping.', 'apartment', 10500, 4, 2, 31.4632, 74.4097, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas3@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Karachi' LIMIT 1), 'Clifton Corporate Suite', 'Clifton Corporate Suite is a polished guest-ready stay near the seafront with air conditioning, workspace comfort, and reliable utilities.', 'studio', 7800, 2, 1, 24.8172, 67.0321, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Islamabad' LIMIT 1), 'Blue Area Business House', 'Blue Area Business House gives families and work travelers a roomy Islamabad stay with kitchen access, parking, and quick routes to city landmarks.', 'house', 16500, 6, 3, 33.7077, 73.0515, 1),
((SELECT user_id FROM users WHERE email = 'fakebarlas5@gmail.com'), (SELECT city_id FROM cities WHERE city_name = 'Dubai' LIMIT 1), 'Jumeirah Beach Premium Room', 'Jumeirah Beach Premium Room is a compact luxury listing with resort-style comfort, balcony views, TV, and close access to Dubai beach attractions.', 'room', 18500, 2, 1, 25.2040, 55.2400, 1);

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Parking', 'Hot Water')
WHERE p.title = 'Rosewood Apartment DHA Lahore';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'Parking', 'Generator')
WHERE p.title = 'Gulberg Premium Villa';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Balcony', 'Hot Water')
WHERE p.title = 'Clifton Sea View Studio';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Kitchen', 'Parking', 'Washing Machine', 'Generator')
WHERE p.title = 'F-7 Family House Islamabad';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'TV', 'Balcony')
WHERE p.title = 'Dubai Marina Skyline Apartment';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Hot Water', 'Balcony')
WHERE p.title = 'Istanbul Old Town Suite';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Parking', 'Generator')
WHERE p.title = 'Bahria Town Modern House';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'TV', 'Hot Water')
WHERE p.title = 'Karachi Executive Apartment';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'Kitchen', 'Parking', 'Balcony')
WHERE p.title = 'Margalla View Villa Islamabad';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Hot Water')
WHERE p.title = 'Lahore Garden Studio';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Swimming Pool', 'TV', 'Parking')
WHERE p.title = 'Dubai Downtown Luxury Room';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Kitchen', 'TV', 'Washing Machine', 'Balcony', 'Hot Water')
WHERE p.title = 'Bosphorus Apartment Istanbul';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'Kitchen', 'Parking', 'TV')
WHERE p.title = 'DHA Executive Apartment Lahore';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Hot Water', 'Balcony')
WHERE p.title = 'Clifton Corporate Suite';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Kitchen', 'Parking', 'Washing Machine', 'Generator', 'Hot Water')
WHERE p.title = 'Blue Area Business House';

INSERT INTO property_amenities (property_id, amenity_id)
SELECT p.property_id, a.amenity_id
FROM properties p
JOIN amenities a ON a.name IN ('WiFi', 'Air Conditioning', 'TV', 'Balcony', 'Swimming Pool')
WHERE p.title = 'Jumeirah Beach Premium Room';

SELECT role, COUNT(*) AS total_users
FROM users
GROUP BY role;

SELECT u.email AS host_email, COUNT(p.property_id) AS total_homes
FROM users u
JOIN properties p ON p.host_id = u.user_id
WHERE u.role = 'host'
GROUP BY u.user_id, u.email;
