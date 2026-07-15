exports.serverError = (err, req, res, next) => {
    console.log(err)
    res.status(500).render('404-error', {
        pageTitle: 'Something Went Wrong',
        currentPage: 'error'
    })
}

exports.error=(req,res,next)=>{
res.status(404).render("404-error",{
    pageTitle:"404 - Page Not Found",
    currentPage:"error"
})
}
