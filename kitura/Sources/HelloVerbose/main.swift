import Kitura
import SwiftyJSON
import LoggerAPI
import HeliumLogger

#if os(Linux)
    import SwiftGlibc

    public func arc4random_uniform(_ max: UInt32) -> Int32 {
        return (SwiftGlibc.rand() % Int32(max-1)) + 1
    }
#else
    import Darwin
#endif

// Enable warnings
Log.logger = HeliumLogger(.verbose)

let router = Router()

// Simple plaintext response
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// Simple plaintext response with an expensive debug level log message
router.get("/plaintext2") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    Log.debug("This might be expensive \(arc4random_uniform(100))")
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
