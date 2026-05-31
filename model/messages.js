const db = require('../utils/dbutils')

module.exports = class Message {
    static send({ senderId, receiverId, propertyId, body }) {
        return db.execute(
            `INSERT INTO messages (sender_id, receiver_id, property_id, body)
             VALUES (?, ?, ?, ?)`,
            [senderId, receiverId, propertyId || null, body]
        )
    }

    static inbox(userId) {
        return db.execute(
            `SELECT m.*, s.full_name AS sender_name, r.full_name AS receiver_name, p.title AS property_title
             FROM messages m
             JOIN users s ON m.sender_id = s.user_id
             JOIN users r ON m.receiver_id = r.user_id
             LEFT JOIN properties p ON m.property_id = p.property_id
             WHERE m.receiver_id = ?
             ORDER BY m.sent_at DESC`,
            [userId]
        )
    }

    static conversation(userId, otherUserId) {
        return db.execute(
            `SELECT m.*, s.full_name AS sender_name, r.full_name AS receiver_name
             FROM messages m
             JOIN users s ON m.sender_id = s.user_id
             JOIN users r ON m.receiver_id = r.user_id
             WHERE (m.sender_id = ? AND m.receiver_id = ?)
                OR (m.sender_id = ? AND m.receiver_id = ?)
             ORDER BY m.sent_at ASC`,
            [userId, otherUserId, otherUserId, userId]
        )
    }

    static markRead(messageId, userId) {
        return db.execute(
            'UPDATE messages SET is_read = 1 WHERE message_id = ? AND receiver_id = ?',
            [messageId, userId]
        )
    }
}
