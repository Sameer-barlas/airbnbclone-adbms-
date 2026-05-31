const fs = require('fs')
const path = require('path')
const rootDir = require('./path')

const uploadDir = path.join(rootDir, 'public', 'uploads', 'properties')
const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp']

const getExtension = mimetype => {
    if (mimetype === 'image/png') return '.png'
    if (mimetype === 'image/webp') return '.webp'
    return '.jpg'
}

exports.getImageUrl = propertyId => {
    for (const ext of allowedExtensions) {
        const filePath = path.join(uploadDir, `property-${propertyId}${ext}`)
        if (fs.existsSync(filePath)) {
            return `/uploads/properties/property-${propertyId}${ext}`
        }
    }
    return null
}

exports.attachImageUrls = properties => {
    return properties.map(property => ({
        ...property,
        imageUrl: exports.getImageUrl(property.property_id)
    }))
}

exports.saveImage = (propertyId, file) => {
    if (!file) return null

    fs.mkdirSync(uploadDir, { recursive: true })

    for (const ext of allowedExtensions) {
        const oldPath = path.join(uploadDir, `property-${propertyId}${ext}`)
        if (fs.existsSync(oldPath)) {
            fs.unlinkSync(oldPath)
        }
    }

    const extension = getExtension(file.mimetype)
    const fileName = `property-${propertyId}${extension}`
    const filePath = path.join(uploadDir, fileName)
    fs.writeFileSync(filePath, file.buffer)

    return `/uploads/properties/${fileName}`
}
