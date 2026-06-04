const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const User = require('../model/users')

const JWT_SECRET = process.env.JWT_SECRET || 'stayease-dev-secret-change-me'
const COOKIE_NAME = 'stayease_token'
const allowedSignupRoles = ['guest', 'host']

const getRedirectPath = role => {
    if (role === 'host') return '/host/homes'
    if (role === 'admin') return '/admin'
    return '/'
}

const signToken = user => {
    return jwt.sign(
        {
            user_id: user.user_id,
            role: user.role,
            full_name: user.full_name
        },
        JWT_SECRET,
        { expiresIn: '7d' }
    )
}

const setAuthCookie = (res, token) => {
    res.cookie(COOKIE_NAME, token, {
        httpOnly: true,
        sameSite: 'lax',
        maxAge: 7 * 24 * 60 * 60 * 1000
    })
}

exports.verifyToken = async (req, res, next) => {
    const token = req.cookies?.[COOKIE_NAME]
    req.user = null

    if (token) {
        try {
            const payload = jwt.verify(token, JWT_SECRET)
            const [users] = await User.findById(payload.user_id)
            const user = users[0]

            if (user && user.is_active) {
                req.user = {
                    user_id: user.user_id,
                    full_name: user.full_name,
                    email: user.email,
                    phone: user.phone,
                    role: user.role
                }
            } else {
                res.clearCookie(COOKIE_NAME)
            }
        } catch (err) {
            res.clearCookie(COOKIE_NAME)
        }
    }

    res.locals.currentUser = req.user
    res.locals.isAuthenticated = Boolean(req.user)
    res.locals.isGuest = req.user?.role === 'guest'
    res.locals.isHost = req.user?.role === 'host'
    res.locals.isAdmin = req.user?.role === 'admin'
    next()
}

exports.requireAuth = (req, res, next) => {
    if (!req.user) {
        return res.redirect('/login')
    }
    next()
}

exports.requireRole = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.redirect('/login')
        }

        if (!roles.includes(req.user.role)) {
            return res.status(403).render('404-error', {
                pageTitle: 'Access Denied',
                currentPage: 'error'
            })
        }

        next()
    }
}

exports.getlogin = (req, res) => {
    if (req.user) {
        return res.redirect(getRedirectPath(req.user.role))
    }

    res.render('auth/login', {
        pageTitle: 'Login',
        currentPage: 'login',
        errorMessage: null,
        oldInput: { email: '' }
    })
}

exports.postlogin = async (req, res) => {
    const { email, password } = req.body

    try {
        const [users] = await User.findByEmail(email)
        const user = users[0]

        if (!user || !user.is_active) {
            return res.status(422).render('auth/login', {
                pageTitle: 'Login',
                currentPage: 'login',
                errorMessage: 'Invalid email or password.',
                oldInput: { email }
            })
        }

        const passwordMatches = await bcrypt.compare(password, user.password_hash)
        if (!passwordMatches) {
            return res.status(422).render('auth/login', {
                pageTitle: 'Login',
                currentPage: 'login',
                errorMessage: 'Invalid email or password.',
                oldInput: { email }
            })
        }

        setAuthCookie(res, signToken(user))
        res.redirect(getRedirectPath(user.role))
    } catch (err) {
        console.log(err)
        res.status(500).render('auth/login', {
            pageTitle: 'Login',
            currentPage: 'login',
            errorMessage: 'Login failed. Please try again.',
            oldInput: { email }
        })
    }
}

exports.getsignup = (req, res) => {
    if (req.user) {
        return res.redirect(getRedirectPath(req.user.role))
    }

    res.render('auth/signup', {
        pageTitle: 'Signup',
        currentPage: 'signup',
        errorMessage: null,
        oldInput: {
            fullName: '',
            email: '',
            phone: '',
            dateOfBirth: '',
            role: 'guest'
        }
    })
}

exports.postsignup = async (req, res) => {
    const { fullName, email, phone, dateOfBirth, password, confirmPassword } = req.body
    const role = allowedSignupRoles.includes(req.body.role) ? req.body.role : 'guest'
    const oldInput = { fullName, email, phone, dateOfBirth, role }

    if (!fullName || !email || !password || password.length < 6 || password !== confirmPassword) {
        return res.status(422).render('auth/signup', {
            pageTitle: 'Signup',
            currentPage: 'signup',
            errorMessage: 'Please enter valid details. Password must match and be at least 6 characters.',
            oldInput
        })
    }

    try {
        const [existingUsers] = await User.findByEmail(email)
        if (existingUsers.length > 0) {
            return res.status(422).render('auth/signup', {
                pageTitle: 'Signup',
                currentPage: 'signup',
                errorMessage: 'This email is already registered.',
                oldInput
            })
        }

        const passwordHash = await bcrypt.hash(password, 10)
        const [result] = await User.create({
            fullName,
            email,
            passwordHash,
            phone,
            role,
            dateOfBirth
        })

        const user = {
            user_id: result.insertId,
            full_name: fullName,
            email,
            phone,
            role
        }

        setAuthCookie(res, signToken(user))
        res.redirect(getRedirectPath(role))
    } catch (err) {
        console.log(err)
        res.status(500).render('auth/signup', {
            pageTitle: 'Signup',
            currentPage: 'signup',
            errorMessage: err.sqlState === '45000' ? err.message : 'Signup failed. Please try again.',
            oldInput
        })
    }
}

exports.postlogout = (req, res) => {
    res.clearCookie(COOKIE_NAME)
    res.redirect('/')
}
