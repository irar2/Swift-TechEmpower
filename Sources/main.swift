import Kitura
import KituraNet
import KituraSys
import SwiftyJSON

let router = Router()

#if os(OSX)
    typealias JSONDictionary = [String: AnyObject]
#else
    typealias JSONDictionary = [String: Any]
#endif

// Return a simple JSON dictionary with one element
func helloWorldDict() -> JSONDictionary {
  var result = JSONDictionary()
  result["message"] = "Hello, World!"
  return result
}

// Hello World
router.get("/plaintext") {
request, response, next in
    response.setHeader("Content-Type", value: "text/plain")
    response.status(.OK).send("Hello, world!")
    next()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
// Basic implementation
//    var jsonObject = JSONDictionary()
//    jsonObject["message"] = "Hello, World!"
//    var result = JSON(jsonObject)
// or:
//    var result = JSON(helloWorldDict())
// or:
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
