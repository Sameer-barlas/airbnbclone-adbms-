const express = require('express')
const authRouter = express.Router()
const authcontroller = require('../controllers/authcontroller')

authRouter.get('/login', authcontroller.getlogin)
authRouter.post('/login', authcontroller.postlogin)
authRouter.get('/signup', authcontroller.getsignup)
authRouter.post('/signup', authcontroller.postsignup)
authRouter.post('/logout', authcontroller.postlogout)

module.exports = authRouter
