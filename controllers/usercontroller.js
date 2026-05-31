const Property = require('../model/properties')
const Wishlist = require('../model/wishlists')
const Booking = require('../model/bookings')
const Review = require('../model/reviews')
const Message = require('../model/messages')
const propertyImage = require('../utils/propertyImage')

const getSearchInput = req => ({
    city: req.query.city || '',
    checkIn: req.query.checkIn || '',
    checkOut: req.query.checkOut || '',
    guests: req.query.guests || '',
    minPrice: req.query.minPrice || '',
    maxPrice: req.query.maxPrice || ''
})

exports.gethomes = async (req, res) => {
    try {
        const [properties] = await Property.fetchListings()
        const registeredHomes = propertyImage.attachImageUrls(properties)

        if (!req.user) {
            return res.render('store/public-home', {
                registeredHomes,
                pageTitle: 'Homes',
                currentPage: 'home',
                errorMessage: null
            })
        }

        const [cities] = await Property.fetchCities()

        res.render('store/home', {
            registeredHomes,
            cities,
            searchInput: getSearchInput(req),
            pageTitle: 'Homes',
            currentPage: 'home',
            errorMessage: null
        })
    } catch (err) {
        console.log(err)
        if (!req.user) {
            return res.render('store/public-home', {
                registeredHomes: [],
                pageTitle: 'Homes',
                currentPage: 'home',
                errorMessage: 'Could not load homes. Please check the database schema.'
            })
        }

        res.render('store/home', {
            registeredHomes: [],
            cities: [],
            searchInput: getSearchInput(req),
            pageTitle: 'Homes',
            currentPage: 'home',
            errorMessage: 'Could not load homes. Please check the database schema.'
        })
    }
}

exports.searchproperties = async (req, res) => {
    if (!req.user) {
        return res.redirect('/')
    }

    const searchInput = getSearchInput(req)

    try {
        const [rows] = await Property.search(searchInput)
        const [cities] = await Property.fetchCities()
        let searchResults = rows[0] || []

        if (searchInput.checkIn && searchInput.checkOut) {
            const [blockedRows] = await Property.fetchBlockedPropertyIds({
                checkIn: searchInput.checkIn,
                checkOut: searchInput.checkOut
            })
            const blockedIds = new Set(blockedRows.map(row => Number(row.property_id)))
            searchResults = searchResults.filter(home => !blockedIds.has(Number(home.property_id)))
        }

        const registeredHomes = propertyImage.attachImageUrls(searchResults)

        res.render('store/home', {
            registeredHomes,
            cities,
            searchInput,
            pageTitle: 'Search Homes',
            currentPage: 'home',
            errorMessage: null
        })
    } catch (err) {
        console.log(err)
        const [cities] = await Property.fetchCities()
        res.render('store/home', {
            registeredHomes: [],
            cities,
            searchInput,
            pageTitle: 'Search Homes',
            currentPage: 'home',
            errorMessage: err.message
        })
    }
}

exports.getfavourites = async (req, res) => {
    try {
        const [wishlistHomes] = await Wishlist.fetchByGuest(req.user.user_id)
        const favHomes = propertyImage.attachImageUrls(wishlistHomes)
        res.render('store/favourites', {
            pageTitle: 'Favourites',
            currentPage: 'favourites',
            favHomes
        })
    } catch (err) {
        console.log(err)
        res.redirect('/')
    }
}

exports.addtofavourites = async (req, res) => {
    try {
        await Wishlist.save(req.user.user_id, req.body.propertyId || req.body.id)
        res.redirect(req.get('Referrer') || '/')
    } catch (err) {
        console.log(err)
        res.redirect('/')
    }
}

exports.removefromfavourites = async (req, res) => {
    try {
        await Wishlist.deleteById(req.user.user_id, req.body.propertyId || req.body.id)
        res.redirect('/favourites')
    } catch (err) {
        console.log(err)
        res.redirect('/favourites')
    }
}

exports.gethomedetails = async (req, res) => {
    try {
        const [properties] = await Property.findDetail(req.params.id)
        const [reviews] = await Property.fetchReviews(req.params.id)
        const currentHome = properties[0]

        res.render('store/home-details', {
            pageTitle: 'Home Details',
            currentHome: currentHome ? {
                ...currentHome,
                imageUrl: propertyImage.getImageUrl(currentHome.property_id)
            } : null,
            reviews,
            currentPage: 'homeDetails',
            message: req.query.message || null
        })
    } catch (err) {
        console.log(err)
        res.redirect('/')
    }
}

exports.bookhome = async (req, res) => {
    try {
        const [properties] = await Property.findDetail(req.params.id)
        const currentHome = properties[0]
        res.render('store/book', {
            pageTitle: 'Book Home',
            currentHome: currentHome ? {
                ...currentHome,
                imageUrl: propertyImage.getImageUrl(currentHome.property_id)
            } : null,
            currentPage: 'book',
            errorMessage: null,
            oldInput: {
                checkIn: '',
                checkOut: '',
                numGuests: '1',
                paymentMethod: 'cash'
            }
        })
    } catch (err) {
        console.log(err)
        res.redirect('/')
    }
}

exports.confirmbooking = async (req, res) => {
    const { propertyId, homeId, checkIn, checkOut, numGuests, paymentMethod } = req.body
    const selectedPropertyId = propertyId || homeId

    try {
        const result = await Booking.create({
            guestId: req.user.user_id,
            propertyId: selectedPropertyId,
            checkIn,
            checkOut,
            numGuests,
            paymentMethod
        })

        if (Number(result.booking_id) === -1) {
            const [properties] = await Property.findDetail(selectedPropertyId)
            return res.status(422).render('store/book', {
                pageTitle: 'Book Home',
                currentHome: properties[0],
                currentPage: 'book',
                errorMessage: result.message,
                oldInput: { checkIn, checkOut, numGuests, paymentMethod }
            })
        }

        res.redirect(`/bookings?message=${encodeURIComponent(result.message)}`)
    } catch (err) {
        console.log(err)
        const [properties] = await Property.findDetail(selectedPropertyId)
        res.status(500).render('store/book', {
            pageTitle: 'Book Home',
            currentHome: properties[0],
            currentPage: 'book',
            errorMessage: err.message,
            oldInput: { checkIn, checkOut, numGuests, paymentMethod }
        })
    }
}

exports.getbookings = async (req, res) => {
    try {
        const [bookings] = await Booking.fetchGuestBookings(req.user.user_id)
        res.render('store/bookings', {
            pageTitle: 'Bookings',
            currentPage: 'bookings',
            bookings,
            message: req.query.message || null,
            errorMessage: null
        })
    } catch (err) {
        console.log(err)
        res.render('store/bookings', {
            pageTitle: 'Bookings',
            currentPage: 'bookings',
            bookings: [],
            message: null,
            errorMessage: 'Could not load bookings.'
        })
    }
}

exports.cancelbooking = async (req, res) => {
    try {
        const result = await Booking.cancel(req.body.bookingId, req.user.user_id)
        res.redirect(`/bookings?message=${encodeURIComponent(result.message)}`)
    } catch (err) {
        console.log(err)
        res.redirect(`/bookings?message=${encodeURIComponent(err.message)}`)
    }
}

exports.submitreview = async (req, res) => {
    try {
        await Review.create({
            bookingId: req.body.bookingId,
            guestId: req.user.user_id,
            rating: req.body.rating,
            comment: req.body.comment
        })
        res.redirect('/bookings?message=Review submitted successfully.')
    } catch (err) {
        console.log(err)
        res.redirect(`/bookings?message=${encodeURIComponent(err.message)}`)
    }
}

exports.getmessages = async (req, res) => {
    try {
        const [messages] = await Message.inbox(req.user.user_id)
        res.render('store/messages', {
            pageTitle: 'Messages',
            currentPage: 'messages',
            messages
        })
    } catch (err) {
        console.log(err)
        res.redirect('/')
    }
}

exports.getconversation = async (req, res) => {
    try {
        const [messages] = await Message.conversation(req.user.user_id, req.params.userId)
        res.render('store/conversation', {
            pageTitle: 'Conversation',
            currentPage: 'messages',
            messages,
            otherUserId: req.params.userId
        })
    } catch (err) {
        console.log(err)
        res.redirect('/messages')
    }
}

exports.sendmessage = async (req, res) => {
    try {
        await Message.send({
            senderId: req.user.user_id,
            receiverId: req.body.receiverId,
            propertyId: req.body.propertyId,
            body: req.body.body
        })
        res.redirect(req.body.redirectTo || '/messages')
    } catch (err) {
        console.log(err)
        res.redirect(req.body.redirectTo || '/messages')
    }
}

exports.markmessageasread = async (req, res) => {
    try {
        await Message.markRead(req.body.messageId, req.user.user_id)
        res.redirect('/messages')
    } catch (err) {
        console.log(err)
        res.redirect('/messages')
    }
}
