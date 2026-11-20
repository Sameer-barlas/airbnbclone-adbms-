const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const sourceDir = path.join(rootDir, 'public');
const uploadDir = path.join(rootDir, 'public', 'uploads', 'properties');

fs.mkdirSync(uploadDir, { recursive: true });

const sourceFiles = [
  path.join(sourceDir, 'image1.png'),
  path.join(sourceDir, 'image2.png')
];

for (let propertyId = 1; propertyId <= 12; propertyId += 1) {
  const sourceFile = sourceFiles[(propertyId - 1) % sourceFiles.length];
  const destinationFile = path.join(uploadDir, `property-${propertyId}.png`);

  if (!fs.existsSync(sourceFile)) {
    console.warn(`Missing source image: ${sourceFile}`);
    continue;
  }

  fs.copyFileSync(sourceFile, destinationFile);
  console.log(`Created ${path.relative(rootDir, destinationFile)}`);
}
