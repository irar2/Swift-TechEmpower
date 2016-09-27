import Kitura
import KituraNet
import Foundation

let router = Router()

// Return Hello, World! followed by the current date constructed from a Date() instance
router.get("/date") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    var myDate = SPIUtils.httpDate(Date())
    response.status(.OK).send("Hello, world! \(myDate)")
    try response.end()
}

// Return Hello, World! followed by the current date
router.get("/httpdate") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    var myDate = SPIUtils.httpDate()
    response.status(.OK).send("Hello, world! \(myDate)")
    try response.end()
}

// Serve up files from /public, eg: /public/hello.txt
router.all("/file", middleware: StaticFileServer())

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
