import Kitura
import KituraNet
import KituraSys
import SwiftyJSON

let router = Router()

// TechEmpower test 0: plaintext
router.get("/plaintext") {
request, response, next in
    response.setHeader("Content-Type", value: "text/plain")
    response.status(.OK).send("Hello, world!")
    next()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
    var result = JSON(["message":"Hello, World!"])
    response.setHeader("Server", value: "Kitura-TechEmpower")
    response.status(.OK).send(json: result)
    next()
}

// TechEmpower test 2: Single database query
router.get("/db") {
request, response, next in
    // Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}

    var result = JSON(["message":"TODO"])
    response.status(.OK).send(json: result)
    next()
}

//router.get("/headers") {
//request, response, next in
//for header in request.headers


let server = HTTPServer.listen(port: 8080, delegate: router)
Server.run()
