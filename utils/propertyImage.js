const fs = require('fs')
const path = require('path')
const rootDir = require('./path')

const uploadDir = path.join(rootDir, 'public', 'uploads', 'properties')
const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp']
const defaultSeedCount = 12

const getExtension = mimetype => {
    if (mimetype === 'image/png') return '.png'
    if (mimetype === 'image/webp') return '.webp'
    return '.jpg'
}

exports.getImageUrl = propertyId => {
    const id = Number(propertyId)

    // Check if the file exists on the local filesystem
    for (const ext of allowedExtensions) {
        const filePath = path.join(uploadDir, `property-${propertyId}${ext}`)
        if (fs.existsSync(filePath)) {
            return `/uploads/properties/property-${propertyId}${ext}`
        }
    }

    // Serverless / static CDN fallback for seeded demo properties (1-12)
    if (!isNaN(id) && id >= 1 && id <= defaultSeedCount) {
        return `/uploads/properties/property-${id}.jpg`
    }

    return null
}

exports.attachImageUrls = properties => {
    if (!Array.isArray(properties)) return []
    return properties.map(property => ({
        ...property,
        imageUrl: exports.getImageUrl(property.property_id)
    }))
}

exports.saveImage = (propertyId, file) => {
    if (!file) return null

    try {
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
    } catch (err) {
        console.warn('Could not save image to disk (filesystem may be read-only in serverless mode):', err.message)
        return null
    }
}
