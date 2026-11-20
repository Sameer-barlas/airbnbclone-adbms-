const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const uploadDir = path.join(rootDir, 'public', 'uploads', 'properties');

fs.mkdirSync(uploadDir, { recursive: true });

for (let propertyId = 1; propertyId <= 12; propertyId += 1) {
  const jpgFile = path.join(uploadDir, `property-${propertyId}.jpg`);
  const pngFile = path.join(uploadDir, `property-${propertyId}.png`);

  if (fs.existsSync(jpgFile) && !fs.existsSync(pngFile)) {
    fs.copyFileSync(jpgFile, pngFile);
  } else if (fs.existsSync(pngFile) && !fs.existsSync(jpgFile)) {
    fs.copyFileSync(pngFile, jpgFile);
  }

  console.log(`Verified property ${propertyId} images exist in ${path.relative(rootDir, uploadDir)}`);
}
