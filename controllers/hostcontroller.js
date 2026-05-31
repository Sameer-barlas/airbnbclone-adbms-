const Property = require('../model/properties')
const Booking = require('../model/bookings')
const propertyImage = require('../utils/propertyImage')

const propertyTypes = ['apartment', 'house', 'villa', 'studio', 'room']

const buildPropertyData = body => ({
    cityId: body.cityId,
    title: body.title,
    description: body.description,
    propertyType: body.propertyType,
    pricePerNight: body.pricePerNight,
    maxGuests: body.maxGuests,
    totalRooms: body.totalRooms,
    latitude: body.latitude,
    longitude: body.longitude,
    amenityIds: body.amenityIds
})

const renderPropertyForm = async (res, options) => {
    const [cities] = await Property.fetchCities()
    const [amenities] = await Property.fetchAmenities()
    res.render('admin/update-home', {
        cities,
        amenities,
        propertyTypes,
        ...options
    })
}

exports.gethosthomes = async (req, res) => {
    try {
        const [hostProperties] = await Property.fetchHostProperties(req.user.user_id)
        const registeredHomes = propertyImage.attachImageUrls(hostProperties)
        const [dashboardRows] = await Property.fetchHostDashboard(req.user.user_id)
        const [revenueRows] = await Property.fetchHostRevenue(req.user.user_id, new Date().getFullYear())
        const [hostBookings] = await Booking.fetchHostBookings(req.user.user_id)

        res.render('admin/homes', {
            currentPage: 'host-homes',
            pageTitle: 'Host Homes',
            registeredHomes,
            dashboard: dashboardRows[0] || null,
            revenueReport: revenueRows[0] || [],
            hostBookings,
            message: req.query.message || null
        })
    } catch (err) {
        console.log(err)
        res.render('admin/homes', {
            currentPage: 'host-homes',
            pageTitle: 'Host Homes',
            registeredHomes: [],
            dashboard: null,
            revenueReport: [],
            hostBookings: [],
            message: 'Could not load host dashboard.'
        })
    }
}

exports.getaddhome = async (req, res) => {
    try {
        await renderPropertyForm(res, {
            pageTitle: 'Add Home',
            currentPage: 'add-home',
            editting: false,
            currentHome: null,
            selectedAmenities: [],
            errorMessage: null
        })
    } catch (err) {
        console.log(err)
        res.redirect('/host/homes')
    }
}

exports.postaddhome = async (req, res) => {
    try {
        const propertyId = await Property.create(req.user.user_id, buildPropertyData(req.body))
        propertyImage.saveImage(propertyId, req.file)
        res.redirect('/host/homes?message=Home added successfully.')
    } catch (err) {
        console.log(err)
        await renderPropertyForm(res, {
            pageTitle: 'Add Home',
            currentPage: 'add-home',
            editting: false,
            currentHome: req.body,
            selectedAmenities: Array.isArray(req.body.amenityIds) ? req.body.amenityIds : [req.body.amenityIds].filter(Boolean),
            errorMessage: err.message
        })
    }
}

exports.getedithome = async (req, res) => {
    try {
        const [properties] = await Property.findForHost(req.params.id, req.user.user_id)
        const [details] = await Property.findDetail(req.params.id)
        const [amenityRows] = await Property.fetchPropertyAmenityIds(req.params.id)

        if (!properties[0]) {
            return res.redirect('/host/homes?message=Home not found.')
        }

        await renderPropertyForm(res, {
            currentHome: {
                ...(details[0] || properties[0]),
                imageUrl: propertyImage.getImageUrl(req.params.id)
            },
            pageTitle: 'Edit Home',
            currentPage: 'edit-home',
            editting: true,
            selectedAmenities: amenityRows.map(row => String(row.amenity_id)),
            errorMessage: null
        })
    } catch (err) {
        console.log(err)
        res.redirect('/host/homes')
    }
}

exports.postedithome = async (req, res) => {
    try {
        await Property.update(req.body.id, req.user.user_id, buildPropertyData(req.body))
        propertyImage.saveImage(req.body.id, req.file)
        res.redirect('/host/homes?message=Home updated successfully.')
    } catch (err) {
        console.log(err)
        res.redirect('/host/homes?message=Could not update home.')
    }
}

exports.deletehome = async (req, res) => {
    try {
        const [result] = await Property.softDelete(req.body.id, req.user.user_id)
        if (result.affectedRows === 0) {
            return res.redirect('/host/homes?message=This home has active bookings, so it cannot be deleted.')
        }
        res.redirect('/host/homes?message=Home removed from public listings.')
    } catch (err) {
        console.log(err)
        res.redirect('/host/homes?message=Could not delete home.')
    }
}

exports.setavailability = async (req, res) => {
    try {
        await Property.setAvailability(
            req.body.propertyId,
            req.user.user_id,
            req.body.availableDate,
            req.body.isBlocked === '1'
        )
        const action = req.body.isBlocked === '1' ? 'blocked' : 'opened'
        res.redirect(`/host/homes?message=Date ${action} successfully.`)
    } catch (err) {
        console.log(err)
        res.redirect(`/host/homes?message=${encodeURIComponent(err.message || 'Could not update availability.')}`)
    }
}
