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

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Foundation
import PostgreSQL

// Set logger
let log = ConsoleLogger()

// Create HTTP server.
let server = HTTPServer()

let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "host=\(dbHost) port=\(dbPort) dbname=\(dbName) user=\(dbUser) password=\(dbPass)"
var connectionCounter = 0
let dbRows = 10000
let maxValue = 10000

var jsonRes: String!
//log.debug(message: "connectionString: \(connectionString)\n")

// Create a connection pool suitable for driving high load
let dbConnPool = Pool<PGConnection>(capacity: 20, limit: 50, timeout: 10000) {

	let dbConn = PGConnection()
    let status = dbConn.connectdb(connectionString)

    guard status == .ok else {
    	log.warning(message: "DB refused connection, status \(status)")
    	exit(1)
    }

    //connectionCounter = connectionCounter + 1
    //log.debug(message: "Sucessfully established pool connection #\(connectionCounter) to \(dbName)")

    return dbConn

}

fileprivate func getRandomRow() -> (Any?, AppError?) {

    var errRes: AppError? = nil

    #if os(Linux)
        let rnd = Int(random() % dbRows) + 1
    #else
        let rnd = Int(arc4random_uniform(UInt32(dbRows))) + 1
    #endif

    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      errRes = AppError.OtherError("Timed out waiting for a DB connection from the pool")
      log.critical(message: "Timed out waiting for a DB connection from the pool")
      return (jsonRes, errRes)
    }

    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }

    let query = "SELECT randomNumber FROM \"World\" WHERE id=\(rnd)"
    let result = dbConn.exec(statement: query)

    //log.debug(message: "query: \(query)")

    guard result.status() == PGResult.StatusType.tuplesOK else {
      errRes = AppError.DBError("Query failed - status \(result.status())", query: query)
      log.error(message: "Query failed - status \(result.status())")
      return (jsonRes, errRes)
    }

    guard result.numTuples() == 1 else {
      errRes = AppError.DBError("Query returned \(result.numTuples()) rows, expected 1", query: query)
      log.error(message: "Query returned \(result.numTuples()) rows, expected 1")
      return (jsonRes, errRes)
    }

    guard result.numFields() == 1 else {
      errRes = AppError.DBError("Expected single randomNumber field but query returned: \(result.numFields()) fields", query: query)
      log.error(message: "Expected single randomNumber field but query returned: \(result.numFields()) fields")
      return (jsonRes, errRes)
    }

    guard let randomStr = result.getFieldString(tupleIndex: 0, fieldIndex: 0) else {
      errRes = AppError.DBError("Error: could not get field as a String", query: query)
      log.error(message: "Error: could not get field as a String")
      return (jsonRes, errRes)
    }

    if let randomNumber = Int(randomStr) {

      let jsonString: [String:Any] = ["id":rnd, "randomNumber":randomNumber]

      do {
      	try jsonRes = jsonString.jsonEncodedString()
      } catch {
      	errRes = AppError.DataFormatError("Error cannot convert encodedString to JSON")
      	log.error(message: "Error cannot convert encodedString to JSON")
      }
                 
    } else {
      errRes = AppError.DataFormatError("Error: could not parse result as a number: \(randomStr)")
      log.error(message: "Error: could not parse result as a number: \(randomStr)")
    }

    return (jsonRes, errRes)
}

// Register your own routes and handlers
var routes = Routes()

// TechEmpower test #6: Plaintext
routes.add(method: .get, uri: "/plaintext", handler: {
	request, response in
		response.setHeader(.contentType, value: "text/plain")
		response.appendBody(string: "Hello, World!")
		response.completed()
	}
)

// TechEmpower test #1: JSON 
routes.add(method: .get, uri: "/json", handler: {
    request, response in
        response.setHeader(.custom(name: "Server"), value: "Perfect")
        response.setHeader(.contentType, value: "application/json")
        do { 
            try response.setBody(json: ["message":"Hello, World!"])
        } catch let error {
            log.error(message: "Could not encode JSON: \(error)")
        }
        response.completed()
})

// TechEmpower test
routes.add(method: .get, uri: "/db", handler: {
	request, response in

	// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}

    var result = getRandomRow()
    //log.debug(message: "\(result)")

    let encoded = result.0 as? String
    
    //log.debug(message: "encoded: \(encoded)")
    response.status = .ok   
    response.setHeader(.contentType, value: "application/json")

    if let decoded = try? encoded?.jsonDecode() as? [String:Int] {

    	do {

    		//log.info(message: "\(decoded)")
    		try response.setBody(json: decoded!) 

    		} catch {

    			log.error(message: "Unable to decode json body in http response")
    			response.status = .badRequest
    			response.setBody(string: "Unknown error")
    			response.completed()

    		}
    }

    response.completed()
})

// Add the routes to the server.
server.addRoutes(routes)
server.serverPort = 8080

// Set a document root.
// This is optional. If you do not want to serve static content then do not set this.
// Setting the document root will automatically add a static file handler for the route /**
server.documentRoot = "./webroot"

do {
	// Launch the HTTP server.
	try server.start()
} catch PerfectError.networkError(let err, let msg) {
	print("Network error thrown: \(err) \(msg)")
}
