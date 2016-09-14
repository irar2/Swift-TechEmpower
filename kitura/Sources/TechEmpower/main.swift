import Kitura
import SwiftyJSON

let router = Router()

// TechEmpower test 0: plaintext
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
    var result = JSON(["message":"Hello, World!"])
    response.headers["Server"] = "Kitura-TechEmpower"
    response.status(.OK).send(json: result)
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
