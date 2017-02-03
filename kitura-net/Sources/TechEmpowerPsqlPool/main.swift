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
import SwiftyJSON

import Glibc

Log.logger = HeliumLogger(.info)

class TechEmpowerDelegate: ServerDelegate {

    // Send String data as a response. 
    func send(_ response: ServerResponse, string: String, statusCode: HTTPStatusCode = .OK) {
        do { 
            response.headers["Content-Type"] = ["text/plain"]
            response.headers["Content-Length"] = [String(string.characters.count)]
	    response.statusCode = statusCode
            try response.write(from: string)
        } catch { 
            Log.error("Failed to write the response '\(string)'. Error=\(error)")
        }
        do { 
            try response.end()
        } catch { 
            Log.error("Failed to close the response. Error=\(error)")
        }
    }
    
    // Send JSON data as a response. 
    func send(_ response: ServerResponse, json: JSON, statusCode: HTTPStatusCode = .OK) {
        do {
            let jsonData = try json.rawData(options:.prettyPrinted)
            response.headers["Content-Type"] = ["application/json"]
            response.headers["Content-Length"] = [String(jsonData.count)]
	    response.statusCode = statusCode
            try response.write(from: jsonData)
        } catch { 
            Log.error("Failed to write JSON response. Error=\(error)")
        }
        do { 
            try response.end()
        } catch { 
            Log.error("Failed to close the response. Error=\(error)")
        }
    }

    func handle(request: ServerRequest, response: ServerResponse) {

      switch (request.urlString) {

        // TechEmpower test 6: plaintext
        case "/plaintext":
	    let payload = "Hello, world!"
	    send(response, string: payload)
            return

        // TechEmpower test 1: JSON serialization
        case "/json":
            let result = JSON(["message":"Hello, World!"])
            response.headers["Server"] = ["Kitura"]
            send(response, json: result)
            return
        
        //
        // TechEmpower test 2: Single database query (raw, no ORM)
        //
        case "/db":
            let result = getRandomRow()
            guard let dict = result.0 else {
                guard let err = result.1 else {
                    Log.error("Unknown Error")
                    send(response, string: "Unknown error", statusCode: .badRequest)
                    return
                }
                Log.error("\(err)")
                send(response, string: "Error: \(err)", statusCode: .badRequest)
                return
            }
            response.headers["Server"] = ["Kitura"]
            send(response, json: JSON(dict))
            return

        default:
            // URL doesn't match a simple path, try parsing fully
            break
      }

      let parsedURL = URLParser(url: request.url, isConnect: false)
      guard let queryPath = parsedURL.path else {
          send(response, string: "Unknown route", statusCode: .notFound)
          return
      }

      switch (queryPath) {
        //
        // TechEmpower test 3: Multiple database queries (raw, no ORM)
        // Get param provides number of queries: /queries?queries=N
        //
        case "/queries":
            let queriesParam = parsedURL.queryParameters["queries"] ?? "1"
            let numQueries = max(1, min(Int(queriesParam) ?? 1, 500))      // Snap to range of 1-500 as per test spec
            var results: [[String:Int]] = []
            for _ in 1...numQueries {
                let result = getRandomRow()
                guard let dict = result.0 else {
                    guard let err = result.1 else {
                        Log.error("Unknown Error")
                        send(response, string: "Unknown error", statusCode: .badRequest)
                        return
                    }
                    Log.error("\(err)")
                    send(response, string: "Error: \(err)", statusCode: .badRequest)
                    return
                }
                results.append(dict)
            }
            // Return JSON representation of array of results
            response.headers["Server"] = ["Kitura"]
            send(response, json: JSON(results))
            return

        //
        // TechEmpower test 4: fortunes (TODO)
        //
        case "/fortunes":
            response.headers["Server"] = ["Kitura"]
            send(response, string: "Not yet implemented", statusCode: .badRequest)
            return

        //
        // TechEmpower test 5: updates (raw, no ORM)
        //
        case "/updates":
            let queriesParam = parsedURL.queryParameters["queries"] ?? "1"
            let numQueries = max(1, min(Int(queriesParam) ?? 1, 500))      // Snap to range of 1-500 as per test spec
            var results: [[String:Int]] = []
            for _ in 1...numQueries {
                let result = getRandomRow()
                guard let dict = result.0 else {
                    guard let err = result.1 else {
                        Log.error("Unknown Error")
                        send(response, string: "Unknown error", statusCode: .badRequest)
                        return
                    }
                    Log.error("\(err)")
                    send(response, string: "Error: \(err)", statusCode: .badRequest)
                    return
                }
                do {
                    try updateRow(id: dict["id"]!)
                } catch {
                    send(response, string: "Error: \(error)", statusCode: .badRequest)
                    return
                }
                results.append(dict)
            }
            response.headers["Server"] = ["Kitura"]
            send(response, json: JSON(results))
            return

        default:
          send(response, string: "Unknown route", statusCode: .notFound)
          return
      }

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

