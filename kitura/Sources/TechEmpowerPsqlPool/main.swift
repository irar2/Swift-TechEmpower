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

//Log.logger = HeliumLogger(.info)

let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "host=\(dbHost) port=\(dbPort) dbname=\(dbName) user=\(dbUser) password=\(dbPass)"

let dbRows = 10000
let maxValue = 10000

// Prepare SQL statements
var queryPrep = "PREPARE tfbquery (int) AS SELECT randomNumber FROM World WHERE id=$1"
var updatePrep = "PREPARE tfbupdate (int, int) AS UPDATE World SET randomNumber=$2 WHERE id=$1"

// Create a connection pool suitable for driving high load
let dbConnPool = Pool<PGConnection>(capacity: 20, limit: 50, timeout: 10000) {
  let dbConn = PGConnection()
  let status = dbConn.connectdb(connectionString)
  guard status == .ok else {
    fatalError("DB refused connection, status \(status)")
  }
  var result = dbConn.exec(statement: queryPrep)
  guard result.status() == PGResult.StatusType.commandOK else {
    fatalError("Unable to prepare tfbquery - status \(result.status())")
  }
  result = dbConn.exec(statement: updatePrep)
  guard result.status() == PGResult.StatusType.commandOK else {
    fatalError("Unable to prepare tfbupdate - status \(result.status())")
  }
  return dbConn
}

// Return a random number within the range of rows in the database
private func randomNumber(_ maxVal: Int) -> Int {
#if os(Linux)
    return Int(random() % maxVal) + 1
#else
    return Int(arc4random_uniform(UInt32(maxVal))) + 1
#endif
}

// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
// Convert to object using object-relational mapping (ORM) tool
// Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
private func getRandomRow() -> ([String:Int]?, AppError?) {
    var resultDict: [String:Int]? = nil
    var errRes: AppError? = nil
    let rnd = randomNumber(dbRows)
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      errRes = AppError.OtherError("Timed out waiting for a DB connection from the pool")
      return (resultDict, errRes)
    }
    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }
    let query = "EXECUTE tfbquery(\(rnd))"
    let result = dbConn.exec(statement: query)
    //Log.info("\(query) => \(result.status())")
    guard result.status() == PGResult.StatusType.tuplesOK else {
      errRes = AppError.DBError("Query failed - status \(result.status())", query: query)
      return (resultDict, errRes)
    }
    guard result.numTuples() == 1 else {
      errRes = AppError.DBError("Query returned \(result.numTuples()) rows, expected 1", query: query)
      return (resultDict, errRes)
    }
    guard result.numFields() == 1 else {
      errRes = AppError.DBError("Expected single randomNumber field but query returned: \(result.numFields()) fields", query: query)
      return (resultDict, errRes)
    }
    guard let randomStr = result.getFieldString(tupleIndex: 0, fieldIndex: 0) else {
      errRes = AppError.DBError("Error: could not get field as a String", query: query)
      return (resultDict, errRes)
    }
    if let randomNumber = Int(randomStr) {
      resultDict = ["id":rnd, "randomNumber":randomNumber]
    } else {
      errRes = AppError.DataFormatError("Error: could not parse result as a number: \(randomStr)")
    }
    return (resultDict, errRes)
}

// Updates a row of World to a new value.
private func updateRow(id: Int) throws {
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      throw AppError.OtherError("Timed out waiting for a DB connection from the pool")
    }
    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }
    let rndValue = randomNumber(maxValue)
    let query = "EXECUTE tfbupdate(\(id), \(rndValue))"
    let result = dbConn.exec(statement: query)
    //Log.info("\(query) => \(result.status())")
    guard result.status() == PGResult.StatusType.commandOK else {
      throw AppError.DBError("Query failed - status \(result.status())", query: query)
    }
}

let router = Router()

//
// TechEmpower test 6: plaintext
//
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    try response.status(.OK).send("Hello, world!").end()
}

//
// TechEmpower test 1: JSON serialization
//
router.get("/json") {
request, response, next in
    var result = JSON(["message":"Hello, World!"])
    response.headers["Server"] = "Kitura-TechEmpower"
    try response.status(.OK).send(json: result).end()
}

//
// TechEmpower test 2: Single database query (raw, no ORM)
//
router.get("/db") {
request, response, next in
    var result = getRandomRow()
    guard let dict = result.0 else {
        guard let err = result.1 else {
            Log.error("Unknown Error")
            try response.status(.badRequest).send("Unknown error").end()
            return
        }
        Log.error("\(err)")
        try response.status(.badRequest).send("Error: \(err)").end()
        return
    }
    try response.status(.OK).send(json: JSON(dict)).end()
}

//
// TechEmpower test 3: Multiple database queries (raw, no ORM)
// Get param provides number of queries: /queries?queries=N
//
router.get("/queries") {
request, response, next in
    let queriesParam = request.queryParameters["queries"] ?? "1"
    let numQueries = min(Int(queriesParam) ?? 1, 500)
    var results: [[String:Int]] = []
    for i in 1...numQueries {
        var result = getRandomRow()
        guard let dict = result.0 else {
            guard let err = result.1 else {
                Log.error("Unknown Error")
                try response.status(.badRequest).send("Unknown error").end()
                return
            }
            Log.error("\(err)")
            try response.status(.badRequest).send("Error: \(err)").end()
            return
        }
        results.append(dict)
    }
    // Return JSON representation of array of results
    try response.status(.OK).send(json: JSON(results)).end()
}

//
// TechEmpower test 4: fortunes (TODO)
//
router.get("/fortunes") {
request, response, next in
    try response.status(.badRequest).send("Not yet implemented").end()
}

//
// TechEmpower test 5: updates (raw, no ORM)
//
router.get("/updates") {
request, response, next in
    let queriesParam = request.queryParameters["queries"] ?? "1"
    let numQueries = min(Int(queriesParam) ?? 1, 500)
    var results: [[String:Int]] = []
    for i in 1...numQueries {
        var result = getRandomRow()
        guard let dict = result.0 else {
            guard let err = result.1 else {
                Log.error("Unknown Error")
                try response.status(.badRequest).send("Unknown error").end()
                return
            }
            Log.error("\(err)")
            try response.status(.badRequest).send("Error: \(err)").end()
            return
        }
        do {
            try updateRow(id: dict["id"]!)
        } catch let err as AppError {
            try response.status(.badRequest).send("Error: \(err)").end()
            return
        }
        results.append(dict)
    }

    // Return JSON representation of array of results
    try response.status(.OK).send(json: JSON(results)).end()
}

// Create table 
router.get("/create") {
request, response, next in
    let dbConn = dbConnPool.take()!
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
    dbConnPool.give(dbConn)
    response.send("<h3>Table 'World' created</h3>")
    next()
}

// Delete table
router.get("/delete") {
request, response, next in
    let dbConn = dbConnPool.take()!
    let query = "DROP TABLE IF EXISTS \"World\";"
    let result = dbConn.exec(statement: query)
    guard result.status() == PGResult.StatusType.commandOK else {
      try response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status())</pre>").end()
      return
    }
    dbConnPool.give(dbConn)
    response.send("<h3>Table 'World' deleted</h3>")
    next()
}

// Populate DB with 10k rows
router.get("/populate") {
request, response, next in
    let dbConn = dbConnPool.take()!
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
    dbConnPool.give(dbConn)
    response.send("</pre><p>Done.</p>")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
