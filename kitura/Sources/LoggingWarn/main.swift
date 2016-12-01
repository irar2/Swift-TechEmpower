/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
