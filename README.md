# StayEase — Full-Stack Airbnb Clone (ADBMS Project)

StayEase is an MVC-based Airbnb web application built with **Node.js, Express, EJS, Tailwind CSS, and MySQL / TiDB Cloud**.

---

## 📌 Architecture Overview

- **Frontend**: Server-Side Rendered (SSR) HTML views powered by **EJS** and styled with **Tailwind CSS v4**. (There is no separate React frontend; views and routing are handled seamlessly by Express).
- **Backend**: **Node.js + Express 5** RESTful MVC architecture (`controllers/`, `model/`, `routes/`, `views/`).
- **Database**: Compatible with both **TiDB Cloud (Serverless)** and **Local MySQL 8.0+**.
- **Auth & Security**: Stateless JWT authentication stored in HTTP-only cookies, password hashing with `bcrypt`, and Role-Based Access Control (RBAC) separating **Guest**, **Host**, and **Admin** permissions.
- **Image Handling**: `multer` handles uploads; property cover photos are served from `public/uploads/properties`.

---

## 🚀 Quick Start (Local Development)

### 1. Install Dependencies
```bash
npm install
```

### 2. Build Tailwind CSS
```bash
npm run build
```
*(During development, you can run `npm run tailwind` in a separate terminal to watch for CSS changes).*

### 3. Run Automated Tests
```bash
npm test
```

### 4. Start the Application
- Normal mode:
  ```bash
  npm start
  ```
- Development mode (with auto-restart):
  ```bash
  npm run dev
  ```
Open `http://localhost:3000` in your browser.

---

## 🗄️ Database Setup: TiDB Cloud vs Local MySQL

### Option A: TiDB Cloud (Recommended for Deployment)
TiDB Cloud Serverless is a free, distributed, MySQL-compatible cloud database that requires TLS/SSL.

1. Create a free account at [tidbcloud.com](https://tidbcloud.com).
2. Create a free **Serverless Cluster**.
3. Open the **SQL Editor** in the TiDB Cloud console.
4. Run the schema file:
   ```text
   database/airbnb_tidb_schema.sql
   ```
5. *(Optional)* Run the demo seed file:
   ```text
   database/stayease_demo_seed.sql
   ```
6. Copy your connection parameters from the TiDB cluster dashboard and set them in `.env`:
   ```env
   DB_HOST=gateway01.us-east-1.prod.aws.tidbcloud.com
   DB_PORT=4000
   DB_USER=your_prefix.root
   DB_PASSWORD=your_password
   DB_NAME=air_bnb
   DB_SSL=true
   ```
   *(Or use the single `DATABASE_URL` string).*

> **Note on TiDB Compatibility:** TiDB Cloud does not support stored procedures or triggers. StayEase's application layer (`model/bookings.js`, `model/properties.js`, `model/reviews.js`, `controllers/authcontroller.js`) automatically detects TiDB and executes transactions, double-booking checks, calendar blocking, revenue analytics, and review rating updates directly in Node.js with 100% feature parity!

---

### Option B: Local MySQL 8.0+ / MySQL Workbench
If running locally with MySQL Server:
1. Open MySQL Workbench.
2. Run `database/airbnb_adbms_schema.sql` (creates schema, triggers, views, and stored procedures).
3. Run `database/stayease_demo_seed.sql`.
4. Update `.env`:
   ```env
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_USER=root
   DB_PASSWORD=root
   DB_NAME=air_bnb
   DB_SSL=false
   ```

---

## 🌐 Hosting Guide

StayEase can be hosted on **Render** (as a persistent Web Service) or on **Vercel** (as a Serverless Express app). Both configurations are pre-configured in this repository.

### Deploying to Render (Recommended for Full MVC Server)
Render runs the persistent Node.js server, handling file uploads, persistent sessions, and background connections.

1. Push this repository to GitHub:
   ```bash
   git add .
   git commit -m "Prepare StayEase for Render, Vercel, and TiDB"
   git push origin main
   ```
2. Log in to [render.com](https://render.com) and click **New +** -> **Web Service**.
3. Select your GitHub repository.
4. Fill in:
   - **Name**: `stayease-app`
   - **Environment**: `Node`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
5. Under **Environment Variables**, add:
   - `DB_HOST`: Your TiDB host (e.g. `gateway01.us-east-1.prod.aws.tidbcloud.com`)
   - `DB_PORT`: `4000`
   - `DB_USER`: Your TiDB user (e.g. `xxxx.root`)
   - `DB_PASSWORD`: Your TiDB password
   - `DB_NAME`: `air_bnb`
   - `DB_SSL`: `true`
   - `JWT_SECRET`: Any random 32+ character string
6. Click **Create Web Service**. Render will build the CSS, launch the server, and give you a live URL (`https://stayease-app.onrender.com`).

*(Alternatively, Render Blueprint `render.yaml` is already included for one-click setup).*

---

### Deploying to Vercel (Serverless)
`vercel.json` and `api/index.js` are already included in the repository.

1. Go to [vercel.com](https://vercel.com) and click **Add New...** -> **Project**.
2. Import your GitHub repository.
3. In **Build and Output Settings**, verify:
   - Build Command: `npm run build:css`
4. In **Environment Variables**, add:
   - `DB_HOST`: Your TiDB host
   - `DB_PORT`: `4000`
   - `DB_USER`: Your TiDB user
   - `DB_PASSWORD`: Your TiDB password
   - `DB_NAME`: `air_bnb`
   - `DB_SSL`: `true`
   - `JWT_SECRET`: Any random string
5. Click **Deploy**. Vercel will build and serve your app.

---

## 👥 Demo Accounts

All pre-seeded demo accounts share the password:
```text
sameer
```

| Email | Role | Features |
| :--- | :--- | :--- |
| `fakebarlas1@gmail.com` | **Admin** | View system KPIs, user lists, city revenues, and registration audit logs |
| `fakebarlas2@gmail.com` | **Host** | Host dashboard, revenue reports, property listings, block/unblock dates |
| `fakebarlas3@gmail.com` | **Guest** | Search homes, view details, book stays, manage bookings, write reviews |
| `fakebarlas4@gmail.com` | **Host** | Additional host with pre-seeded homes |
| `fakebarlas5@gmail.com` | **Guest** | Additional guest account |

---

## 📁 Project Structure

```text
├── api/
│   └── index.js             # Vercel serverless entry point
├── controllers/
│   ├── admincontroller.js   # Admin analytics & user status
│   ├── authcontroller.js    # JWT auth, signup validation, login/logout
│   ├── errorcontroller.js   # 404 and 500 error handlers
│   ├── hostcontroller.js    # Host home management & availability
│   └── usercontroller.js    # Guest discovery, booking & messaging
├── database/
│   ├── airbnb_adbms_schema.sql  # MySQL 8.0 schema (with triggers/stored procedures)
│   ├── airbnb_tidb_schema.sql   # TiDB Cloud Serverless schema
│   ├── stayease_demo_seed.sql   # Demo seed data
│   └── seed-images.js           # Image duplication utility
├── model/
│   ├── admin.js             # Admin stats queries
│   ├── bookings.js          # Booking & cancellation logic (with TiDB fallback)
│   ├── messages.js          # Direct messaging queries
│   ├── properties.js        # Search & property listings (with TiDB fallback)
│   ├── reviews.js           # Review submissions & rating updates
│   ├── users.js             # User queries & status
│   └── wishlists.js         # Guest favorites
├── public/
│   ├── input.css            # Tailwind CSS source
│   ├── output.css           # Compiled Tailwind CSS bundle
│   └── uploads/properties/  # Seeded & uploaded property cover images
├── routes/
│   ├── adminRoute.js        # /admin routes (RBAC: admin)
│   ├── authRoute.js         # /login, /signup, /logout routes
│   ├── hostRoute.js         # /host routes (RBAC: host)
│   └── userRoute.js         # Public & guest routes
├── test/
│   └── app.test.js          # Automated test suite (10 test groups)
├── utils/
│   ├── dbutils.js           # MySQL2 / TiDB connection pool & SSL config
│   ├── path.js              # Absolute root directory resolver
│   └── propertyImage.js     # Image URL resolution & safe saving
├── views/
│   ├── admin/               # Host & Admin dashboards (EJS)
│   ├── auth/                # Login & Signup pages (EJS)
│   ├── partials/            # Navbar, Head, and Footer partials
│   └── store/               # Home, Details, Book, Bookings, Messages (EJS)
├── app.js                   # Main Express application
├── render.yaml              # Render deployment configuration
├── vercel.json              # Vercel deployment configuration
└── .env.example             # Environment variable template
```
