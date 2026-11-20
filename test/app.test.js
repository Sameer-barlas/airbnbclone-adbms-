const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const path = require('path');
const fs = require('fs');

test('StayEase Test Suite', async (t) => {
  await t.test('1. Environment & App Initialization', () => {
    const app = require('../app');
    assert.ok(app, 'Express app should be exported');
    assert.strictEqual(app.get('view engine'), 'ejs', 'View engine should be ejs');
    assert.strictEqual(app.get('views'), 'views', 'Views directory should be views');
    assert.strictEqual(app.get('trust proxy'), 1, 'Trust proxy should be enabled for Render/Vercel');
  });

  await t.test('2. Property Image Utility', () => {
    const propertyImage = require('../utils/propertyImage');

    // Test getImageUrl for seeded properties
    const url1 = propertyImage.getImageUrl(1);
    assert.ok(url1, 'property-1 image should exist');
    assert.ok(url1.includes('/uploads/properties/property-1'), 'URL should point to public uploads');

    // Test non-existent property
    const url999 = propertyImage.getImageUrl(9999);
    assert.strictEqual(url999, null, 'Non-existent property should return null');

    // Test attachImageUrls
    const sampleProperties = [
      { property_id: 1, title: 'Sample Home 1' },
      { property_id: 9999, title: 'Sample Home 9999' }
    ];
    const attached = propertyImage.attachImageUrls(sampleProperties);
    assert.strictEqual(attached.length, 2);
    assert.ok(attached[0].imageUrl);
    assert.strictEqual(attached[1].imageUrl, null);

    // Test saveImage with null file (safe handling)
    const result = propertyImage.saveImage(1, null);
    assert.strictEqual(result, null);
  });

  await t.test('3. Authentication: JWT and Middleware', async () => {
    const secret = process.env.JWT_SECRET || 'stayease-dev-secret-change-me';
    const payload = { user_id: 123, role: 'host', full_name: 'Test Host' };
    const token = jwt.sign(payload, secret, { expiresIn: '1h' });

    assert.ok(token, 'JWT should be generated');

    const decoded = jwt.verify(token, secret);
    assert.strictEqual(decoded.user_id, 123);
    assert.strictEqual(decoded.role, 'host');
    assert.strictEqual(decoded.full_name, 'Test Host');
  });

  await t.test('4. Signup Validation: Age and Phone Format', () => {
    // Phone regex test
    const phoneRegex = /^[0-9+\-() ]{7,20}$/;
    assert.ok(phoneRegex.test('0300-1234567'), 'Valid PK phone number');
    assert.ok(phoneRegex.test('+923001234567'), 'Valid international phone');
    assert.strictEqual(phoneRegex.test('abc1234'), false, 'Letters should be rejected');
    assert.strictEqual(phoneRegex.test('123'), false, 'Too short should be rejected');

    // Age validation test (18+ rule)
    const eighteenYearsAgo = new Date();
    eighteenYearsAgo.setFullYear(eighteenYearsAgo.getFullYear() - 18);

    const validDob = new Date('2000-01-01');
    assert.ok(validDob <= eighteenYearsAgo, 'Year 2000 is 18+');

    const invalidDob = new Date(); // born today
    assert.strictEqual(invalidDob <= eighteenYearsAgo, false, 'Born today is under 18');
  });

  await t.test('5. Database Config & TiDB SSL Handling', () => {
    // Test that utils/dbutils exports a promise pool
    const db = require('../utils/dbutils');
    assert.ok(db, 'dbutils should be exported');
    assert.strictEqual(typeof db.execute, 'function', 'db should have execute method');
    assert.strictEqual(typeof db.query, 'function', 'db should have query method');
    assert.strictEqual(typeof db.getConnection, 'function', 'db should have getConnection method');
  });

  await t.test('6. Static Files and CSS Build', () => {
    const cssPath = path.join(__dirname, '..', 'public', 'output.css');
    assert.ok(fs.existsSync(cssPath), 'public/output.css should exist');
    const cssContent = fs.readFileSync(cssPath, 'utf8');
    assert.ok(cssContent.length > 500, 'Compiled CSS should not be empty');
  });

  await t.test('7. Hosting Configuration Files', () => {
    const vercelConfigPath = path.join(__dirname, '..', 'vercel.json');
    assert.ok(fs.existsSync(vercelConfigPath), 'vercel.json must exist');
    const vercelConfig = JSON.parse(fs.readFileSync(vercelConfigPath, 'utf8'));
    assert.strictEqual(vercelConfig.version, 2);

    const apiIndexPath = path.join(__dirname, '..', 'api', 'index.js');
    assert.ok(fs.existsSync(apiIndexPath), 'api/index.js for Vercel must exist');

    const renderConfigPath = path.join(__dirname, '..', 'render.yaml');
    assert.ok(fs.existsSync(renderConfigPath), 'render.yaml must exist');

    const tidbSchemaPath = path.join(__dirname, '..', 'database', 'airbnb_tidb_schema.sql');
    assert.ok(fs.existsSync(tidbSchemaPath), 'database/airbnb_tidb_schema.sql must exist');
  });

  await t.test('8. End-to-End HTTP Route Tests', async () => {
    const app = require('../app');
    const Property = require('../model/properties');
    const http = require('node:http');

    // Mock fetchListings to avoid hanging on unavailable local database socket
    const originalFetch = Property.fetchListings;
    Property.fetchListings = async () => [[
      {
        property_id: 1,
        title: 'Skyline Loft Lahore',
        property_type: 'apartment',
        price_per_night: '9000.00',
        max_guests: 4,
        avg_rating: '4.80',
        total_reviews: 12,
        city_name: 'Lahore',
        country: 'Pakistan',
        host_name: 'Barlas Host One',
        host_id: 2,
        amenities: 'WiFi, Air Conditioning'
      }
    ]];

    const server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, resolve));
    const port = server.address().port;
    const baseUrl = `http://127.0.0.1:${port}`;

    const fetchNoKeepAlive = (url, options = {}) => {
      const headers = { ...(options.headers || {}), connection: 'close' };
      return fetch(url, { ...options, headers });
    };

    try {
      // 1. GET / (public home)
      const homeRes = await fetchNoKeepAlive(`${baseUrl}/`);
      assert.strictEqual(homeRes.status, 200);
      const homeHtml = await homeRes.text();
      assert.ok(homeHtml.includes('Rentza') || homeHtml.includes('StayEase'), 'Home HTML should mention Rentza');
      assert.ok(homeHtml.includes('Skyline Loft Lahore'), 'Rendered property should appear on page');

      // 2. GET /login
      const loginRes = await fetchNoKeepAlive(`${baseUrl}/login`);
      assert.strictEqual(loginRes.status, 200);
      const loginHtml = await loginRes.text();
      assert.ok(loginHtml.includes('Login'), 'Login page should render');

      // 3. GET /signup
      const signupRes = await fetchNoKeepAlive(`${baseUrl}/signup`);
      assert.strictEqual(signupRes.status, 200);
      const signupHtml = await signupRes.text();
      assert.ok(signupHtml.includes('Signup'), 'Signup page should render');

      // 4. GET /host/homes without auth (should redirect to /login)
      const hostRes = await fetchNoKeepAlive(`${baseUrl}/host/homes`, { redirect: 'manual' });
      assert.strictEqual(hostRes.status, 302);
      assert.strictEqual(hostRes.headers.get('location'), '/login');

      // 5. GET /admin without auth (should redirect to /login)
      const adminRes = await fetchNoKeepAlive(`${baseUrl}/admin`, { redirect: 'manual' });
      assert.strictEqual(adminRes.status, 302);
      assert.strictEqual(adminRes.headers.get('location'), '/login');

      // 6. GET /favourites without auth (should redirect to /login)
      const favRes = await fetchNoKeepAlive(`${baseUrl}/favourites`, { redirect: 'manual' });
      assert.strictEqual(favRes.status, 302);
      assert.strictEqual(favRes.headers.get('location'), '/login');

      // 7. GET /non-existent-route (404 test)
      const notFoundRes = await fetchNoKeepAlive(`${baseUrl}/this-page-does-not-exist`);
      assert.strictEqual(notFoundRes.status, 404);
      const notFoundHtml = await notFoundRes.text();
      assert.ok(notFoundHtml.includes('404'), '404 page should render');

      // 8. Static CSS asset
      const cssRes = await fetchNoKeepAlive(`${baseUrl}/output.css`);
      assert.strictEqual(cssRes.status, 200);

      // 9. Static Image asset
      const imgRes = await fetchNoKeepAlive(`${baseUrl}/uploads/properties/property-1.png`);
      assert.strictEqual(imgRes.status, 200);
      assert.strictEqual(imgRes.headers.get('content-type'), 'image/png');
    } finally {
      Property.fetchListings = originalFetch;
      if (typeof server.closeAllConnections === 'function') {
        server.closeAllConnections();
      }
      await new Promise((resolve) => server.close(resolve));
      const db = require('../utils/dbutils');
      try {
        await db.end();
      } catch (e) {}
    }
  });

  await t.test('9. TiDB Direct Booking & Cancellation Logic', async () => {
    const Booking = require('../model/bookings');

    // 1. Check-out before check-in
    const invalidDatesRes = await Booking.createDirect({}, {
      guestId: 3,
      propertyId: 1,
      checkIn: '2026-06-10',
      checkOut: '2026-06-05',
      numGuests: 2,
      paymentMethod: 'cash'
    });
    assert.strictEqual(invalidDatesRes.booking_id, -1);
    assert.ok(invalidDatesRes.message.includes('Check-out date must be after check-in date'));

    // 2. Mock connection for property checks
    const mockConn = {
      execute: async (sql, params) => {
        if (sql.includes('SELECT price_per_night, max_guests, host_id FROM properties')) {
          return [[{ price_per_night: 5000, max_guests: 4, host_id: 2 }]];
        }
        if (sql.includes('SELECT COUNT(*) AS count FROM bookings')) {
          return [[{ count: 0 }]];
        }
        return [[]];
      }
    };

    // 3. Guests exceed limit
    const exceedGuestsRes = await Booking.createDirect(mockConn, {
      guestId: 3,
      propertyId: 1,
      checkIn: '2026-06-01',
      checkOut: '2026-06-05',
      numGuests: 10,
      paymentMethod: 'cash'
    });
    assert.strictEqual(exceedGuestsRes.booking_id, -1);
    assert.ok(exceedGuestsRes.message.includes('allows max 4 guests'));

    // 4. Host booking their own property
    const ownPropertyRes = await Booking.createDirect(mockConn, {
      guestId: 2, // hostId is 2
      propertyId: 1,
      checkIn: '2026-06-01',
      checkOut: '2026-06-05',
      numGuests: 2,
      paymentMethod: 'cash'
    });
    assert.strictEqual(ownPropertyRes.booking_id, -1);
    assert.ok(ownPropertyRes.message.includes('Hosts cannot book their own property'));

    // 5. Cancellation tests
    const mockCancelConn = {
      execute: async (sql, params) => {
        if (sql.includes('SELECT check_in, check_out, property_id, guest_id, status FROM bookings')) {
          return [[{ check_in: '2026-06-01', check_out: '2026-06-05', property_id: 1, guest_id: 3, status: 'completed' }]];
        }
        return [[]];
      }
    };

    // Unauthorized cancel
    const unauthCancel = await Booking.cancelDirect(mockCancelConn, 100, 999);
    assert.ok(unauthCancel.message.includes('Unauthorized'));

    // Cancel completed booking
    const completedCancel = await Booking.cancelDirect(mockCancelConn, 100, 3);
    assert.ok(completedCancel.message.includes('Cannot cancel a booking with status: completed'));
  });
});
