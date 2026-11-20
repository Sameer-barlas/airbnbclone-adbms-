const db = require('../utils/dbutils')

module.exports = class Booking {
    static async createDirect(conn, { guestId, propertyId, checkIn, checkOut, numGuests, paymentMethod }) {
        const dIn = new Date(checkIn)
        const dOut = new Date(checkOut)
        if (dOut <= dIn) {
            return { booking_id: -1, message: 'Check-out date must be after check-in date.' }
        }

        const [[property]] = await conn.execute(
            'SELECT price_per_night, max_guests, host_id FROM properties WHERE property_id = ? AND is_active = 1',
            [propertyId]
        )

        if (!property) {
            return { booking_id: -1, message: 'Property not found or not active.' }
        }

        if (Number(numGuests) > property.max_guests) {
            return { booking_id: -1, message: `Property allows max ${property.max_guests} guests.` }
        }

        if (property.host_id === guestId) {
            return { booking_id: -1, message: 'Hosts cannot book their own property.' }
        }

        const [[conflict]] = await conn.execute(
            `SELECT COUNT(*) AS count
             FROM bookings
             WHERE property_id = ?
               AND status IN ('confirmed', 'pending')
               AND check_in < ?
               AND check_out > ?`,
            [propertyId, checkOut, checkIn]
        )

        if (conflict.count > 0) {
            return { booking_id: -1, message: 'Property already booked for the selected dates.' }
        }

        const nights = Math.max(1, Math.round((dOut - dIn) / (1000 * 60 * 60 * 24)))
        const totalPrice = nights * Number(property.price_per_night)

        await conn.beginTransaction()
        try {
            const [bRes] = await conn.execute(
                `INSERT INTO bookings (guest_id, property_id, check_in, check_out, num_guests, total_price, status)
                 VALUES (?, ?, ?, ?, ?, ?, 'confirmed')`,
                [guestId, propertyId, checkIn, checkOut, Number(numGuests) || 1, totalPrice]
            )
            const bookingId = bRes.insertId

            await conn.execute(
                `INSERT INTO payments (booking_id, amount, method, status)
                 VALUES (?, ?, ?, 'completed')`,
                [bookingId, totalPrice, paymentMethod || 'cash']
            )

            const cur = new Date(dIn)
            while (cur < dOut) {
                const curStr = cur.toISOString().split('T')[0]
                await conn.execute(
                    `INSERT INTO availability (property_id, available_date, is_blocked)
                     VALUES (?, ?, 1)
                     ON DUPLICATE KEY UPDATE is_blocked = 1`,
                    [propertyId, curStr]
                )
                cur.setDate(cur.getDate() + 1)
            }

            await conn.commit()
            return {
                booking_id: bookingId,
                message: `Booking confirmed! ID: ${bookingId} | Total: PKR ${totalPrice}`
            }
        } catch (err) {
            await conn.rollback()
            throw err
        }
    }

    static async cancelDirect(conn, bookingId, userId) {
        const [[booking]] = await conn.execute(
            'SELECT check_in, check_out, property_id, guest_id, status FROM bookings WHERE booking_id = ?',
            [bookingId]
        )

        if (!booking) {
            return { message: 'Booking not found.' }
        }

        if (booking.guest_id !== userId) {
            return { message: 'Unauthorized: You can only cancel your own bookings.' }
        }

        if (!['pending', 'confirmed'].includes(booking.status)) {
            return { message: `Cannot cancel a booking with status: ${booking.status}` }
        }

        await conn.beginTransaction()
        try {
            await conn.execute('UPDATE bookings SET status = ? WHERE booking_id = ?', ['cancelled', bookingId])
            await conn.execute('UPDATE payments SET status = ? WHERE booking_id = ?', ['refunded', bookingId])
            await conn.execute(
                `UPDATE availability
                 SET is_blocked = 0
                 WHERE property_id = ?
                   AND available_date >= ?
                   AND available_date < ?`,
                [booking.property_id, booking.check_in, booking.check_out]
            )
            await conn.commit()
            return { message: `Booking #${bookingId} cancelled and refund initiated.` }
        } catch (err) {
            await conn.rollback()
            throw err
        }
    }

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

            try {
                await conn.query(
                    'CALL sp_create_booking(?, ?, ?, ?, ?, ?, @bid, @msg)',
                    [guestId, propertyId, checkIn, checkOut, numGuests, paymentMethod]
                )
                const [[out]] = await conn.query('SELECT @bid AS booking_id, @msg AS message')
                return out
            } catch (procErr) {
                if (procErr.code === 'ER_SP_DOES_NOT_EXIST' || procErr.errno === 1305) {
                    return await this.createDirect(conn, {
                        guestId, propertyId, checkIn, checkOut, numGuests, paymentMethod
                    })
                }
                throw procErr
            }
        } finally {
            conn.release()
        }
    }

    static async cancel(bookingId, userId) {
        const conn = await db.getConnection()
        try {
            try {
                await conn.query('CALL sp_cancel_booking(?, ?, @msg)', [bookingId, userId])
                const [[out]] = await conn.query('SELECT @msg AS message')
                return out
            } catch (procErr) {
                if (procErr.code === 'ER_SP_DOES_NOT_EXIST' || procErr.errno === 1305) {
                    return await this.cancelDirect(conn, bookingId, userId)
                }
                throw procErr
            }
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

