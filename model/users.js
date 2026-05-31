const db = require('../utils/dbutils')

module.exports = class User {
    static create({ fullName, email, passwordHash, phone, role, dateOfBirth }) {
        return db.execute(
            `INSERT INTO users (full_name, email, password_hash, phone, role, date_of_birth)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [fullName, email, passwordHash, phone || null, role, dateOfBirth || null]
        )
    }

    static findByEmail(email) {
        return db.execute('SELECT * FROM users WHERE email = ?', [email])
    }

    static findById(userId) {
        return db.execute(
            `SELECT user_id, full_name, email, phone, role, date_of_birth, is_active, created_at
             FROM users WHERE user_id = ?`,
            [userId]
        )
    }

    static fetchAll() {
        return db.execute(
            `SELECT user_id, full_name, email, phone, role, date_of_birth, is_active, created_at
             FROM users
             ORDER BY created_at DESC`
        )
    }

    static updateStatus(userId, isActive) {
        return db.execute('UPDATE users SET is_active = ? WHERE user_id = ?', [isActive, userId])
    }
}
