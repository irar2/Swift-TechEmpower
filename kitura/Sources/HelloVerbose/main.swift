import Kitura
import SwiftyJSON
import LoggerAPI
import HeliumLogger
import Foundation

// Enable warnings
Log.logger = HeliumLogger(.verbose)

let router = Router()

// Simple plaintext response
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    try response.end()
}

// Artificially expensive function to call while interpolating a log message
func expensiveFunction() -> String {
    var data = Data()
    for i in 1...20 {
      data.append("Foo Bar \(i) ".data(using: .utf8)!)
    }
    return "Blah"
}

// Simple plaintext response with an expensive debug level log message
router.get("/plaintext2") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    Log.debug("Expensive function says: \(expensiveFunction())")
    try response.end()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
