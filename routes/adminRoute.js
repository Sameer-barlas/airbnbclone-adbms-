const express = require('express')
const adminRouter = express.Router()
const admincontroller = require('../controllers/admincontroller')
const authcontroller = require('../controllers/authcontroller')

adminRouter.use(authcontroller.requireRole('admin'))

adminRouter.get('/', admincontroller.getdashboard)
adminRouter.post('/users/status', admincontroller.updateuserstatus)

module.exports = adminRouter
