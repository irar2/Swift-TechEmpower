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
import Foundation
import PostgreSQL
import LoggerAPI
import HeliumLogger

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

//Log.logger = HeliumLogger(.warning)

let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "host=\(dbHost) port=\(dbPort) dbname=\(dbName) user=\(dbUser) password=\(dbPass)"

let dbRows = 10000
let maxValue = 10000

// Connect to Postgres DB
func newConn() -> PGConnection {
  let dbConn = PGConnection()
  let status = dbConn.connectdb(connectionString)
  guard status == .ok else {
    print("DB refused connection, status \(status)")
    exit(1)
  }
  return dbConn
}

let router = Router()

// TechEmpower test 2: Single database query
router.get("/db") {
request, response, next in
    // Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
#if os(Linux)
        let rnd = Int(random() % dbRows) + 1
#else
        let rnd = Int(arc4random_uniform(UInt32(dbRows)))
#endif
    let dbConn = newConn()
    let query = "SELECT randomNumber FROM World WHERE id=\(rnd)"
    let result = dbConn.exec(statement: query)
    guard result.status() == PGResult.StatusType.tuplesOK else {
      try response.status(.badRequest).send("Failed query: '\(query)' - status \(result.status())").end()
      return
    }
    guard result.numTuples() == 1 else {
      try response.status(.badRequest).send("Error: query '\(query)' returned \(result.numTuples()) rows, expected 1").end()
      return
    }
    guard result.numFields() == 1 else {
      try response.status(.badRequest).send("Error: expected single randomNumber field but query returned: \(result.numFields()) fields").end()
      return
    }
    guard let randomStr = result.getFieldString(tupleIndex: 0, fieldIndex: 0) else {
      try response.status(.badRequest).send("Error: could not get field as a String").end()
      return
    }
    if let randomNumber = Int(randomStr) {
      response.status(.OK).send(json: JSON(["id":"\(rnd)", "randomNumber":"\(randomNumber)"]))
    } else {
      try response.status(.badRequest).send("Error: could not parse result as a number: \(randomStr)").end()
      return
    }
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// Create table 
router.get("/create") {
request, response, next in
    let dbConn = newConn()
    let query = "CREATE TABLE World ("
        + "id integer NOT NULL,"
        + "randomNumber integer NOT NULL default 0,"
        + "PRIMARY KEY  (id)"
        + ");"
    let result = dbConn.exec(statement: query)
    guard result.status() == PGResult.StatusType.commandOK else {
      try response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status())</pre>").end()
      return
    }
    response.send("<h3>Table 'World' created</h3>")
    next()
}

// Delete table
router.get("/delete") {
request, response, next in
    let dbConn = newConn()
    let query = "DROP TABLE IF EXISTS \"World\";"
    let result = dbConn.exec(statement: query)
    guard result.status() == PGResult.StatusType.commandOK else {
      try response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status())</pre>").end()
      return
    }
    response.send("<h3>Table 'World' deleted</h3>")
    next()
}

// Populate DB with 10k rows
router.get("/populate") {
request, response, next in
    let dbConn = newConn()
    response.status(.OK).send("<h3>Populating World table with \(dbRows) rows</h3><pre>")
    for i in 1...dbRows {
#if os(Linux)
      let rnd = Int(random() % maxValue)
#else
      let rnd = Int(arc4random_uniform(UInt32(maxValue)))
#endif
      let query = "INSERT INTO World (id, randomNumber) VALUES (\(i), \(rnd));"
      let result = dbConn.exec(statement: query)
      guard result.status() == PGResult.StatusType.commandOK else {
        try response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status())</pre>").end()
        return
      }
      response.send(".")
    }
    response.send("</pre><p>Done.</p>")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
