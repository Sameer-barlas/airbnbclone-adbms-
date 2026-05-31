const db = require('../utils/dbutils')

module.exports = class Booking {
    static async create({ guestId, propertyId, checkIn, checkOut, numGuests, paymentMethod }) {
        const conn = await db.getConnection()
        try {
            const [[blockedDates]] = await conn.execute(
                `SELECT COUNT(*) AS count
                 FROM availability
                 WHERE property_id = ?
                   AND is_blocked = 1
                   AND available_date >= ?
                   AND available_date < ?`,
                [propertyId, checkIn, checkOut]
            )

            if (blockedDates.count > 0) {
                return {
                    booking_id: -1,
                    message: 'This home is blocked by the host for one or more selected dates.'
                }
            }

            await conn.query(
                'CALL sp_create_booking(?, ?, ?, ?, ?, ?, @bid, @msg)',
                [guestId, propertyId, checkIn, checkOut, numGuests, paymentMethod]
            )
            const [[out]] = await conn.query('SELECT @bid AS booking_id, @msg AS message')
            return out
        } finally {
            conn.release()
        }
    }

    static async cancel(bookingId, userId) {
        const conn = await db.getConnection()
        try {
            await conn.query('CALL sp_cancel_booking(?, ?, @msg)', [bookingId, userId])
            const [[out]] = await conn.query('SELECT @msg AS message')
            return out
        } finally {
            conn.release()
        }
    }

    static fetchGuestBookings(guestId) {
        return db.execute(
            `SELECT *
             FROM vw_booking_details
             WHERE guest_id = ?
             ORDER BY booked_at DESC`,
            [guestId]
        )
    }

    static fetchHostBookings(hostId) {
        return db.execute(
            `SELECT *
             FROM vw_booking_details
             WHERE host_id = ?
             ORDER BY booked_at DESC`,
            [hostId]
        )
    }
}
