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

import Foundation
import PostgreSQL
import HTTPServer

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432

let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "postgres://\(dbUser):\(dbPass)@\(dbHost):\(dbPort)/\(dbName)"

let dbRows = 10000
let maxValue = 10000

let info = Connection.ConnectionInfo(uri: URL(string: connectionString)!)!
let connection = PostgreSQL.Connection(info: info)

func connect() throws {
print("Connecting to: \(connectionString)")
    try connection.open()
    // Prepare SQL statements
    try connection.execute("PREPARE tfbquery (int) AS SELECT randomNumber FROM World WHERE id=$1")
    try connection.execute("PREPARE tfbupdate (int, int) AS UPDATE World SET randomNumber=$2 WHERE id=$1")
}

func randomNumber(_ maxVal: Int) -> Int {
#if os(Linux)
    return Int(random() % maxVal) + 1
#else
    return Int(arc4random_uniform(UInt32(maxVal))) + 1
#endif
}

// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
// Convert to object using object-relational mapping (ORM) tool
// Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
func getRandomRow() throws -> [String:Int] {
    let rnd = randomNumber(dbRows)
    let dbConn = connection

    let query = "EXECUTE tfbquery(\(rnd))"
    let result = try dbConn.execute(query)
    guard result.status.successful else {
      throw AppError.DBError("Query failed - status \(result.status)", query: query)
    }
    guard result.count == 1 else {
      throw AppError.DBError("Query returned \(result.count) rows, expected 1", query: query)
    }
    let row = result[0]
    let randomStr: String = try row.value("randomnumber") 
    if let randomNumber = Int(randomStr) {
      return ["id":rnd, "randomNumber":randomNumber]
    } else {
      throw AppError.DataFormatError("Error: could not parse result as a number: \(randomStr)")
    }
}

// Updates a row of World to a new value.
func updateRow(id: Int) throws {
    let rndValue = randomNumber(maxValue)
    let dbConn = connection

    let query = "EXECUTE tfbupdate(\(id), \(rndValue))"
    let result = try dbConn.execute(query)
    guard result.status.successful else {
      throw AppError.DBError("Query failed - status \(result.status)", query: query)
    }
}

