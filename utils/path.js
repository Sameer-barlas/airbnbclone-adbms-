const path=require('path')
const rootDir=require.main ? path.dirname(require.main.filename) : process.cwd()
module.exports=rootDir
