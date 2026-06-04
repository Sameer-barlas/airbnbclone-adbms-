# StayEase Setup Guide

StayEase is an MVC-based Airbnb-style web app built with Node.js, Express, EJS, Tailwind CSS, and MySQL.

## Requirements

- Node.js 18 or newer
- MySQL Server
- MySQL Workbench
- VS Code or any code editor

## 1. Install Project Packages

Open the project folder in terminal and run:

```bash
npm install
```

## 2. Create And Import Database

Open MySQL Workbench and run the schema file:

```text
database/airbnb_adbms_schema.sql
```

Then run the demo seed file:

```text
database/stayease_demo_seed.sql
```

The seed file creates:

- 1 admin
- 2 guests
- 2 hosts
- 12 active homes
- amenities linked with homes

Images are already available in:

```text
public/uploads/properties
```

The app expects home images in this format:

```text
property-1.png
property-2.png
...
property-12.png
```

## 3. Check Database Connection

Open:

```text
utils/dbutils.js
```

Update these values according to your local MySQL setup:

```js
host: "127.0.0.1",
port: 3306,
user: "root",
password: "root",
database: "air_bnb"
```

If your MySQL password is empty, set:

```js
password: ""
```

## 4. Build Tailwind CSS

Run this once before starting the project:

```bash
npm run build:css
```

During design changes, keep Tailwind watching in a separate terminal:

```bash
npm run tailwind
```

## 5. Start The Server

For normal run:

```bash
npm start
```

For development with auto-restart:

```bash
npm run dev
```

Open the app:

```text
http://localhost:3000
```

## Demo Accounts

All accounts use the same password:

```text
sameer
```

| Email | Role |
| --- | --- |
| fakebarlas1@gmail.com | admin |
| fakebarlas2@gmail.com | guest |
| fakebarlas3@gmail.com | host |
| fakebarlas4@gmail.com | guest |
| fakebarlas5@gmail.com | host |

## Useful MySQL Checks

Show all tables:

```sql
USE air_bnb;
SHOW TABLES;
```

Check users:

```sql
SELECT user_id, full_name, email, role, is_active FROM users;
```

Check host homes:

```sql
SELECT u.email, COUNT(p.property_id) AS total_homes
FROM users u
JOIN properties p ON p.host_id = u.user_id
WHERE u.role = 'host'
GROUP BY u.user_id, u.email;
```

## Common Issues

If the app cannot connect to MySQL, check `utils/dbutils.js`.

If styling does not appear, run:

```bash
npm run build:css
```

If images do not appear, make sure the `public/uploads/properties` folder is present.
