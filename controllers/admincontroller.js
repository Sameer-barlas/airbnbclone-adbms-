const Admin = require('../model/admin')
const User = require('../model/users')

exports.getdashboard = async (req, res) => {
    try {
        const [[userStats], [propertyStats], [bookingStats], [revenueStats]] = await Admin.fetchDashboard()
        const [users] = await User.fetchAll()
        const [revenueByCity] = await Admin.fetchRevenueByCity()
        const [auditLog] = await Admin.fetchAuditLog()

        res.render('admin/dashboard', {
            pageTitle: 'Admin Dashboard',
            currentPage: 'admin',
            stats: {
                totalUsers: userStats[0].total_users,
                totalProperties: propertyStats[0].total_properties,
                totalBookings: bookingStats[0].total_bookings,
                totalRevenue: revenueStats[0].total_revenue
            },
            users,
            revenueByCity,
            auditLog,
            message: req.query.message || null
        })
    } catch (err) {
        console.log(err)
        res.render('admin/dashboard', {
            pageTitle: 'Admin Dashboard',
            currentPage: 'admin',
            stats: { totalUsers: 0, totalProperties: 0, totalBookings: 0, totalRevenue: 0 },
            users: [],
            revenueByCity: [],
            auditLog: [],
            message: 'Could not load admin dashboard.'
        })
    }
}

exports.updateuserstatus = async (req, res) => {
    try {
        await User.updateStatus(req.body.userId, req.body.isActive === '1' ? 1 : 0)
        res.redirect('/admin?message=User status updated.')
    } catch (err) {
        console.log(err)
        res.redirect('/admin?message=Could not update user status.')
    }
}
