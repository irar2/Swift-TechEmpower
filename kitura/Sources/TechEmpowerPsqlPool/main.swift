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

let dbHost = "localhost"
let dbPort = Int32(5432)
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
let connectionString = "host=\(dbHost) port=\(dbPort) dbname=\(dbName) user=\(dbUser) password=\(dbPass)"

let dbRows = 10000
let maxValue = 10000

// Create a connection pool suitable for driving high load
let dbConnPool = Pool<PGConnection>(capacity: 20, limit: 50, timeout: 10000) {
//let dbConnPool = Pool<PGConnection>(capacity: 4, limit: 4, timeout: 10000) {
 let dbConn = PGConnection()
 let status = dbConn.connectdb(connectionString)
  guard status == .ok else {
    print("DB refused connection, status \(status)")
    exit(1)
  }
  return dbConn
}

let router = Router()

// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
// Convert to object using object-relational mapping (ORM) tool
// Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
fileprivate func getRandomRow() -> (JSON?, AppError?) {
    var jsonRes: JSON? = nil
    var errRes: AppError? = nil
    #if os(Linux)
        let rnd = Int(random() % dbRows) + 1
    #else
        let rnd = Int(arc4random_uniform(UInt32(dbRows))) + 1
    #endif
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.take() else {
      errRes = AppError.OtherError("Timed out waiting for a DB connection from the pool")
      return (jsonRes, errRes)
    }
    // Ensure that when we complete, the connection is returned to the pool
    defer {
      dbConnPool.give(dbConn)
    }
    let query = "SELECT \"randomNumber\" FROM \"World\" WHERE id=\(rnd)"
    let result = dbConn.exec(statement: query)
    guard result.status() == PGResult.StatusType.tuplesOK else {
      errRes = AppError.DBError("Query failed - status \(result.status())", query: query)
      return (jsonRes, errRes)
    }
    guard result.numTuples() == 1 else {
      errRes = AppError.DBError("Query returned \(result.numTuples()) rows, expected 1", query: query)
      return (jsonRes, errRes)
    }
    guard result.numFields() == 1 else {
      errRes = AppError.DBError("Expected single randomNumber field but query returned: \(result.numFields()) fields", query: query)
      return (jsonRes, errRes)
    }
    guard let randomStr = result.getFieldString(tupleIndex: 0, fieldIndex: 0) else {
      errRes = AppError.DBError("Error: could not get field as a String", query: query)
      return (jsonRes, errRes)
    }
    if let randomNumber = Int(randomStr) {
      jsonRes = JSON(["id":"\(rnd)", "randomNumber":"\(randomNumber)"])
    } else {
      errRes = AppError.DataFormatError("Error: could not parse result as a number: \(randomStr)")
    }
    return (jsonRes, errRes)
}

// TechEmpower test 2: Single database query
router.get("/db") {
request, response, next in
    // Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}

    var result = getRandomRow()
    guard let json = result.0 else {
        guard let err = result.1 else {
            Log.error("Unknown Error")
            try response.status(.badRequest).send("Unknown error").end()
            return
        }
        Log.error("\(err)")
        try response.status(.badRequest).send("Error: \(err)").end()
        return
    }
    try response.status(.OK).send(json: json).end()
}

// TechEmpower test 3: Multiple database queries
// Get param provides number of queries: /queries?queries=N
// N times { 
//   Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
//   Convert to object using object-relational mapping (ORM) tool
// }
// Serialize objects to JSON - example: [{"id":4174,"randomNumber":331},{"id":51,"randomNumber":6544},{"id":4462,"randomNumber":952},{"id":2221,"randomNumber":532},{"id":9276,"randomNumber":3097},{"id":3056,"randomNumber":7293},{"id":6964,"randomNumber":620},{"id":675,"randomNumber":6601},{"id":8414,"randomNumber":6569},{"id":2753,"randomNumber":4065}]
router.get("/queries") {
request, response, next in
    //var numQueries = 10
    guard let queriesParam = request.queryParameters["queries"] else {
        Log.error("queries param missing")
        try response.status(.badRequest).send("Error: queries param missing").end()
        return
    }
    guard let numQueries = Int(queriesParam) else {
        Log.error("could not parse \(queriesParam) as an integer")
        try response.status(.badRequest).send("Error: could not parse \(queriesParam) as an integer").end()
        return
    }
    var results: [JSON] = []
    for i in 1...numQueries {
        var result = getRandomRow()
        guard let json = result.0 else {
            guard let err = result.1 else {
                Log.error("Unknown Error")
                try response.status(.badRequest).send("Unknown error").end()
                return
            }
            Log.error("\(err)")
            try response.status(.badRequest).send("Error: \(err)").end()
            return
        }
        results.append(json)
    }
    // Return JSON representation of array of results
    try response.status(.OK).send(json: JSON(results)).end()
}

// Create table 
router.get("/create") {
request, response, next in
    let dbConn = dbConnPool.take()!
    let query = "CREATE TABLE \"World\" ("
        + "id integer NOT NULL,"
        + "\"randomNumber\" integer NOT NULL default 0,"
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
      let query = "INSERT INTO \"World\" (id, \"randomNumber\") VALUES (\(i), \(rnd));"
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
