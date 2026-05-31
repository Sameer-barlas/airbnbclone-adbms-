const db = require('../utils/dbutils')

module.exports = class Review {
    static async create({ bookingId, guestId, rating, comment }) {
        const conn = await db.getConnection()
        try {
            await conn.beginTransaction()
            const [[booking]] = await conn.execute(
                `SELECT booking_id, guest_id, property_id, status
                 FROM bookings
                 WHERE booking_id = ? AND guest_id = ?`,
                [bookingId, guestId]
            )

            if (!booking) {
                throw new Error('Booking not found.')
            }

            if (booking.status !== 'completed') {
                throw new Error('You can review only completed bookings.')
            }

            await conn.execute(
                `INSERT INTO reviews (booking_id, guest_id, property_id, rating, comment)
                 VALUES (?, ?, ?, ?, ?)`,
                [bookingId, guestId, booking.property_id, rating, comment || null]
            )

            await conn.commit()
        } catch (err) {
            await conn.rollback()
            throw err
        } finally {
            conn.release()
        }
    }
}
