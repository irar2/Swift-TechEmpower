/*
 * Copyright IBM Corporation 2017
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

import KituraNet
import LoggerAPI
import HeliumLogger
import Foundation

import Glibc

//Log.logger = HeliumLogger(.info)

class TechEmpowerDelegate: ServerDelegate {
    func handle(request: ServerRequest, response: ServerResponse) {

        // TechEmpower test 6: plaintext
        if request.urlString == "/plaintext" {
	    let payload = "Hello, world!"
	    response.headers["Content-Type"] = ["text/plain"]
	    response.headers["Content-Length"] = [String(payload.characters.count)]
	    response.statusCode = .OK
	    do {
	        try response.write(from: payload)
		try response.end()
	    }
	    catch {
		print("Failed to write the response. Error=\(error)")
	    }
        }

// TechEmpower test 1: JSON serialization
// router.get("/json") {
// request, response, next in
//     var result = JSON(["message":"Hello, World!"])
//     response.headers["Server"] = "Kitura"
//     response.status(.OK).send(json: result)
//     try response.end()
// }

    }
}

let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

let server = HTTP.createServer()

server.delegate = TechEmpowerDelegate()

do {
    try server.listen(on: port)
} catch {
    print("Error listening on port \(port): \(error). Use server.failed(callback:) to handle")
}

ListenerGroup.waitForListeners()

