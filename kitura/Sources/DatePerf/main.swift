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
