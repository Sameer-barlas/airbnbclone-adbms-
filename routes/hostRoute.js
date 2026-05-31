const express=require('express')
const multer=require('multer')
const hostRouter=express.Router()
const hostcontroller=require('../controllers/hostcontroller')
const authcontroller=require('../controllers/authcontroller')
const upload=multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
    fileFilter: (req,file,cb)=>{
        if(['image/jpeg','image/png','image/webp'].includes(file.mimetype)){
            cb(null,true)
        }else{
            cb(new Error('Only JPG, PNG, and WEBP images are allowed.'))
        }
    }
})

hostRouter.use(authcontroller.requireRole('host'))

hostRouter.get("/homes",hostcontroller.gethosthomes)
hostRouter.get("/properties",hostcontroller.gethosthomes)
hostRouter.get("/add-home",hostcontroller.getaddhome)
hostRouter.post("/add-home",upload.single('houseImage'),hostcontroller.postaddhome)
hostRouter.get("/edit-home/:id",hostcontroller.getedithome)
hostRouter.post("/edit-home/",upload.single('houseImage'),hostcontroller.postedithome)
hostRouter.post("/delete-home",hostcontroller.deletehome)
hostRouter.post("/availability",hostcontroller.setavailability)
module.exports=hostRouter
