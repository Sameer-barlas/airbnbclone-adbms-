const db = require('../utils/dbutils')

const toArray = value => {
    if (!value) return []
    return Array.isArray(value) ? value : [value]
}

module.exports = class Property {
    static fetchListings() {
        return db.execute(
            `SELECT * FROM vw_property_listing
             ORDER BY avg_rating DESC, price_per_night ASC`
        )
    }

    static search({ city, checkIn, checkOut, guests, minPrice, maxPrice }) {
        return db.query(
            'CALL sp_search_properties(?, ?, ?, ?, ?, ?)',
            [
                city || null,
                checkIn || null,
                checkOut || null,
                guests || 1,
                minPrice || null,
                maxPrice || null
            ]
        )
    }

    static findDetail(propertyId) {
        return db.execute(
            `SELECT
                p.property_id,
                p.host_id,
                p.city_id,
                p.title,
                p.description,
                p.property_type,
                p.price_per_night,
                p.max_guests,
                p.total_rooms,
                p.latitude,
                p.longitude,
                p.avg_rating,
                p.total_reviews,
                p.is_active,
                p.created_at,
                c.city_name,
                c.country,
                u.full_name AS host_name,
                GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', ') AS amenities
             FROM properties p
             JOIN cities c ON p.city_id = c.city_id
             JOIN users u ON p.host_id = u.user_id
             LEFT JOIN property_amenities pa ON p.property_id = pa.property_id
             LEFT JOIN amenities a ON pa.amenity_id = a.amenity_id
             WHERE p.property_id = ? AND p.is_active = 1
             GROUP BY
                p.property_id, p.host_id, p.city_id, p.title, p.description, p.property_type,
                p.price_per_night, p.max_guests, p.total_rooms, p.latitude, p.longitude,
                p.avg_rating, p.total_reviews, p.is_active, p.created_at,
                c.city_name, c.country, u.full_name`,
            [propertyId]
        )
    }

    static fetchReviews(propertyId) {
        return db.execute(
            `SELECT r.review_id, r.rating, r.comment, r.created_at, u.full_name AS guest_name
             FROM reviews r
             JOIN users u ON r.guest_id = u.user_id
             WHERE r.property_id = ?
             ORDER BY r.created_at DESC`,
            [propertyId]
        )
    }

    static fetchCities() {
        return db.execute('SELECT city_id, city_name, country FROM cities ORDER BY city_name')
    }

    static fetchAmenities() {
        return db.execute('SELECT amenity_id, name FROM amenities ORDER BY name')
    }

    static fetchPropertyAmenityIds(propertyId) {
        return db.execute(
            'SELECT amenity_id FROM property_amenities WHERE property_id = ?',
            [propertyId]
        )
    }

    static fetchHostProperties(hostId) {
        return db.execute(
            `SELECT
                vpl.*,
                (
                    SELECT COUNT(*)
                    FROM bookings b
                    WHERE b.property_id = vpl.property_id
                      AND b.status IN ('pending', 'confirmed')
                ) AS active_booking_count
             FROM vw_property_listing vpl
             WHERE vpl.host_id = ?
             ORDER BY property_id DESC`,
            [hostId]
        )
    }

    static fetchHostDashboard(hostId) {
        return db.execute('SELECT * FROM vw_host_dashboard WHERE host_id = ?', [hostId])
    }

    static fetchHostRevenue(hostId, year) {
        return db.query('CALL sp_host_revenue_report(?, ?)', [hostId, year])
    }

    static findForHost(propertyId, hostId) {
        return db.execute(
            `SELECT * FROM properties
             WHERE property_id = ? AND host_id = ? AND is_active = 1`,
            [propertyId, hostId]
        )
    }

    static async create(hostId, data) {
        const conn = await db.getConnection()
        try {
            await conn.beginTransaction()
            const [result] = await conn.execute(
                `INSERT INTO properties
                    (host_id, city_id, title, description, property_type, price_per_night,
                     max_guests, total_rooms, latitude, longitude)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    hostId,
                    data.cityId,
                    data.title,
                    data.description || null,
                    data.propertyType,
                    data.pricePerNight,
                    data.maxGuests,
                    data.totalRooms,
                    data.latitude || null,
                    data.longitude || null
                ]
            )

            const propertyId = result.insertId
            for (const amenityId of toArray(data.amenityIds)) {
                await conn.execute(
                    'INSERT INTO property_amenities (property_id, amenity_id) VALUES (?, ?)',
                    [propertyId, amenityId]
                )
            }

            await conn.commit()
            return propertyId
        } catch (err) {
            await conn.rollback()
            throw err
        } finally {
            conn.release()
        }
    }

    static async update(propertyId, hostId, data) {
        const conn = await db.getConnection()
        try {
            await conn.beginTransaction()
            await conn.execute(
                `UPDATE properties
                 SET city_id = ?, title = ?, description = ?, property_type = ?,
                     price_per_night = ?, max_guests = ?, total_rooms = ?,
                     latitude = ?, longitude = ?
                 WHERE property_id = ? AND host_id = ?`,
                [
                    data.cityId,
                    data.title,
                    data.description || null,
                    data.propertyType,
                    data.pricePerNight,
                    data.maxGuests,
                    data.totalRooms,
                    data.latitude || null,
                    data.longitude || null,
                    propertyId,
                    hostId
                ]
            )

            await conn.execute('DELETE FROM property_amenities WHERE property_id = ?', [propertyId])
            for (const amenityId of toArray(data.amenityIds)) {
                await conn.execute(
                    'INSERT INTO property_amenities (property_id, amenity_id) VALUES (?, ?)',
                    [propertyId, amenityId]
                )
            }

            await conn.commit()
        } catch (err) {
            await conn.rollback()
            throw err
        } finally {
            conn.release()
        }
    }

    static async softDelete(propertyId, hostId) {
        return db.execute(
            `UPDATE properties p
             SET p.is_active = 0
             WHERE p.property_id = ?
               AND p.host_id = ?
               AND NOT EXISTS (
                    SELECT 1
                    FROM bookings b
                    WHERE b.property_id = p.property_id
                      AND b.status IN ('pending', 'confirmed')
               )`,
            [propertyId, hostId]
        )
    }

    static fetchBlockedPropertyIds({ checkIn, checkOut }) {
        return db.execute(
            `SELECT DISTINCT property_id
             FROM availability
             WHERE is_blocked = 1
               AND available_date >= ?
               AND available_date < ?`,
            [checkIn, checkOut]
        )
    }

    static async setAvailability(propertyId, hostId, availableDate, isBlocked) {
        const [[property]] = await db.execute(
            'SELECT property_id FROM properties WHERE property_id = ? AND host_id = ? AND is_active = 1',
            [propertyId, hostId]
        )

        if (!property) {
            throw new Error('Home not found.')
        }

        if (!isBlocked) {
            const [[booking]] = await db.execute(
                `SELECT COUNT(*) AS count
                 FROM bookings
                 WHERE property_id = ?
                   AND status IN ('pending', 'confirmed')
                   AND check_in <= ?
                   AND check_out > ?`,
                [propertyId, availableDate, availableDate]
            )

            if (booking.count > 0) {
                throw new Error('This date already has an active booking, so it cannot be opened.')
            }
        }

        return db.execute(
            `INSERT INTO availability (property_id, available_date, is_blocked)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE is_blocked = ?`,
            [propertyId, availableDate, isBlocked ? 1 : 0, isBlocked ? 1 : 0]
        )
    }
}
