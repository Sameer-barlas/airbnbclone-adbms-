const db = require('../utils/dbutils')

module.exports = class Wishlist {
    static fetchByGuest(guestId) {
        return db.execute(
            `SELECT vpl.*
             FROM wishlists w
             JOIN vw_property_listing vpl ON w.property_id = vpl.property_id
             WHERE w.guest_id = ?
             ORDER BY w.saved_at DESC`,
            [guestId]
        )
    }

    static save(guestId, propertyId) {
        return db.execute(
            'INSERT IGNORE INTO wishlists (guest_id, property_id) VALUES (?, ?)',
            [guestId, propertyId]
        )
    }

    static deleteById(guestId, propertyId) {
        return db.execute(
            'DELETE FROM wishlists WHERE guest_id = ? AND property_id = ?',
            [guestId, propertyId]
        )
    }
}
