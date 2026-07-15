const Property = require('../model/properties')
const Booking = require('../model/bookings')
const propertyImage = require('../utils/propertyImage')

const propertyTypes = ['apartment', 'house', 'villa', 'studio', 'room']

const toArray = value => {
    if (!value) return []
    return Array.isArray(value) ? value : [value]
}

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
    amenityIds: toArray(body.amenityIds)
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

const validatePropertyData = (data, cities, amenities) => {
    const errors = []
    const validCityIds = new Set(cities.map(city => String(city.city_id)))
    const validAmenityIds = new Set(amenities.map(amenity => String(amenity.amenity_id)))

    if (!data.title || !data.title.trim()) {
        errors.push('Title is required.')
    }

    if (!validCityIds.has(String(data.cityId || ''))) {
        errors.push(cities.length ? 'Please choose a valid city.' : 'No cities are available. Add cities in MySQL before creating a home.')
    }

    if (!propertyTypes.includes(data.propertyType)) {
        errors.push('Please choose a valid home type.')
    }

    if (!Number.isFinite(Number(data.pricePerNight)) || Number(data.pricePerNight) < 1) {
        errors.push('Price per night must be at least 1.')
    }

    if (!Number.isFinite(Number(data.maxGuests)) || Number(data.maxGuests) < 1 || Number(data.maxGuests) > 50) {
        errors.push('Max guests must be between 1 and 50.')
    }

    if (!Number.isFinite(Number(data.totalRooms)) || Number(data.totalRooms) < 1) {
        errors.push('Rooms must be at least 1.')
    }

    const invalidAmenity = data.amenityIds.find(amenityId => !validAmenityIds.has(String(amenityId)))
    if (invalidAmenity) {
        errors.push('Please choose only valid amenities.')
    }

    return errors
}

const renderPropertyFormWithInput = async (res, options, statusCode = 422) => {
    res.status(statusCode)
    await renderPropertyForm(res, {
        ...options,
        selectedAmenities: toArray(options.selectedAmenities).map(String)
    })
}

const getUploadErrorMessage = err => {
    if (!err) return null
    if (err.code === 'LIMIT_FILE_SIZE') {
        return 'House image must be 5MB or smaller.'
    }
    return err.message || 'Could not upload house image.'
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
    const data = buildPropertyData(req.body)

    try {
        const uploadErrorMessage = getUploadErrorMessage(req.uploadError)
        if (uploadErrorMessage) {
            return renderPropertyFormWithInput(res, {
                pageTitle: 'Add Home',
                currentPage: 'add-home',
                editting: false,
                currentHome: req.body,
                selectedAmenities: data.amenityIds,
                errorMessage: uploadErrorMessage
            })
        }

        const [cities] = await Property.fetchCities()
        const [amenities] = await Property.fetchAmenities()
        const validationErrors = validatePropertyData(data, cities, amenities)

        if (validationErrors.length) {
            return renderPropertyFormWithInput(res, {
                pageTitle: 'Add Home',
                currentPage: 'add-home',
                editting: false,
                currentHome: req.body,
                selectedAmenities: data.amenityIds,
                errorMessage: validationErrors.join(' ')
            })
        }

        const propertyId = await Property.create(req.user.user_id, data)
        propertyImage.saveImage(propertyId, req.file)
        res.redirect('/host/homes?message=Home added successfully.')
    } catch (err) {
        console.log(err)
        await renderPropertyFormWithInput(res, {
            pageTitle: 'Add Home',
            currentPage: 'add-home',
            editting: false,
            currentHome: req.body,
            selectedAmenities: data.amenityIds,
            errorMessage: err.sqlState === '23000' ? 'Please choose a valid city and amenities.' : err.message
        }, 500)
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
    const data = buildPropertyData(req.body)

    try {
        const [properties] = await Property.findForHost(req.body.id, req.user.user_id)

        if (!properties[0]) {
            return res.redirect('/host/homes?message=Home not found.')
        }

        const uploadErrorMessage = getUploadErrorMessage(req.uploadError)
        if (uploadErrorMessage) {
            return renderPropertyFormWithInput(res, {
                currentHome: {
                    ...properties[0],
                    ...req.body,
                    property_id: req.body.id,
                    imageUrl: propertyImage.getImageUrl(req.body.id)
                },
                pageTitle: 'Edit Home',
                currentPage: 'edit-home',
                editting: true,
                selectedAmenities: data.amenityIds,
                errorMessage: uploadErrorMessage
            })
        }

        const [cities] = await Property.fetchCities()
        const [amenities] = await Property.fetchAmenities()
        const validationErrors = validatePropertyData(data, cities, amenities)

        if (validationErrors.length) {
            return renderPropertyFormWithInput(res, {
                currentHome: {
                    ...properties[0],
                    ...req.body,
                    property_id: req.body.id,
                    imageUrl: propertyImage.getImageUrl(req.body.id)
                },
                pageTitle: 'Edit Home',
                currentPage: 'edit-home',
                editting: true,
                selectedAmenities: data.amenityIds,
                errorMessage: validationErrors.join(' ')
            })
        }

        await Property.update(req.body.id, req.user.user_id, data)
        propertyImage.saveImage(req.body.id, req.file)
        res.redirect('/host/homes?message=Home updated successfully.')
    } catch (err) {
        console.log(err)
        await renderPropertyFormWithInput(res, {
            currentHome: {
                ...req.body,
                property_id: req.body.id,
                imageUrl: propertyImage.getImageUrl(req.body.id)
            },
            pageTitle: 'Edit Home',
            currentPage: 'edit-home',
            editting: true,
            selectedAmenities: data.amenityIds,
            errorMessage: err.sqlState === '23000' ? 'Please choose a valid city and amenities.' : 'Could not update home.'
        }, 500)
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
