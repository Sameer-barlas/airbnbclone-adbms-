const db = require('../utils/dbutils')

module.exports = class Admin {
    static fetchDashboard() {
        return Promise.all([
            db.execute('SELECT COUNT(*) AS total_users FROM users'),
            db.execute('SELECT COUNT(*) AS total_properties FROM properties WHERE is_active = 1'),
            db.execute('SELECT COUNT(*) AS total_bookings FROM bookings'),
            db.execute("SELECT IFNULL(SUM(amount), 0) AS total_revenue FROM payments WHERE status = 'completed'")
        ])
    }

    static fetchRevenueByCity() {
        return db.execute(
            `SELECT *
             FROM vw_revenue_by_city_month
             ORDER BY booking_year DESC, booking_month DESC, total_revenue DESC`
        )
    }

    static fetchAuditLog() {
        return db.execute(
            `SELECT al.*, u.full_name
             FROM audit_log al
             LEFT JOIN users u ON al.user_id = u.user_id
             WHERE al.action = 'USER_REGISTERED'
             ORDER BY al.action_time DESC
             LIMIT 100`
        )
    }
}
