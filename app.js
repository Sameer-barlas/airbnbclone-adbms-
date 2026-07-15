const express=require('express')
const cookieParser=require('cookie-parser')
const app=express()
const path=require('path')
const rootDir=require('./utils/path')
const userRouter=require('./routes/userRoute')
const hostRouter=require('./routes/hostRoute')
const authRouter=require('./routes/authRoute')
const adminRouter=require('./routes/adminRoute')
const errorcontroller=require('./controllers/errorcontroller')
const authcontroller=require('./controllers/authcontroller')

app.set('view engine','ejs')
app.set('views','views')

app.use(express.static(path.join(rootDir,'public')))
// app.use(express.json())                                 ye baad mn use hoga jab user ya host ki traf se api ki calls hongi so right now it is of no use 
app.use(express.urlencoded({extended:true}))    
app.use(cookieParser())
app.use(authcontroller.verifyToken)
app.use(authRouter)
app.use('/',userRouter)
app.use('/host',hostRouter)
app.use('/admin',adminRouter)
app.use(errorcontroller.serverError)
app.use(errorcontroller.error)
require("dotenv").config();

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`server is running on port ${port}`);
});
