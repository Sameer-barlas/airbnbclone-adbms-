require("dotenv").config();
const express = require('express');
const cookieParser = require('cookie-parser');
const path = require('path');
const rootDir = require('./utils/path');
const userRouter = require('./routes/userRoute');
const hostRouter = require('./routes/hostRoute');
const authRouter = require('./routes/authRoute');
const adminRouter = require('./routes/adminRoute');
const errorcontroller = require('./controllers/errorcontroller');
const authcontroller = require('./controllers/authcontroller');

const app = express();

// Trust reverse proxy for deployment on Render, Vercel, etc.
app.set('trust proxy', 1);

app.set('view engine', 'ejs');
app.set('views', 'views');

app.use(express.static(path.join(rootDir, 'public')));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(authcontroller.verifyToken);

app.use(authRouter);
app.use('/', userRouter);
app.use('/host', hostRouter);
app.use('/admin', adminRouter);

// 404 Not Found handler
app.use(errorcontroller.error);

// Central error handler
app.use(errorcontroller.serverError);

const port = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(port, () => {
    console.log(`server is running on port ${port}`);
  });
}

module.exports = app;

