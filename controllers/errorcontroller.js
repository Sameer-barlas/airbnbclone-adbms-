exports.error=(req,res,next)=>{
res.status(404).render("404-error",{
    pageTitle:"404 - Page Not Found",
    currentPage:"error"
})
}