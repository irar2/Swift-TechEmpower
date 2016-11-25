import Kitura
import SwiftyJSON
import LoggerAPI
import HeliumLogger
import Foundation

#if os(Linux)
    import SwiftGlibc

    public func arc4random_uniform(_ max: UInt32) -> Int32 {
        return (SwiftGlibc.rand() % Int32(max-1)) + 1
    }
#else
    import Darwin
#endif

// Enable warnings
Log.logger = HeliumLogger(.warning)

let router = Router()

func banana() -> String {
    var data = Data()
    data.append("Foo Bar".data(using: .utf8)!)
    data.append("Foo Bar".data(using: .utf8)!)
    data.append("Foo Bar".data(using: .utf8)!)
    data.append("Foo Bar".data(using: .utf8)!)
    data.append("Foo Bar".data(using: .utf8)!)
    data.append("Foo Bar".data(using: .utf8)!)
    return String(data: data, encoding: .utf8)!
}

// Simple plaintext response with an expensive debug level log message
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    Log.debug("This might be expensive \(banana())")
    try response.end()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
