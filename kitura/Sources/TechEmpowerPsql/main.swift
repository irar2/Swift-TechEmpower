import Kitura
import KituraNet
import KituraSys
import SwiftyJSON
import Foundation
import SQL
import PostgreSQL

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

let dbHost = "localhost"
let dbPort = Int32(5432)
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"
var dbConn: PostgreSQL.Connection!

let dbRows = 100
let maxValue = 10000

// Connect to Postgres DB
let connectionString = try URI("postgres://\(dbUser):\(dbPass)@\(dbHost):\(dbPort)/\(dbName)")
do {
  dbConn = try PostgreSQL.Connection(connectionString)
  try dbConn.open()
  guard dbConn.internalStatus == PostgreSQL.Connection.InternalStatus.OK else {
    print("DB refused connection, status \(dbConn.internalStatus)")
    exit(1)
  }
} catch let error as PostgreSQL.Connection.Error {
  print("Failed to connect to DB \(connectionString) (\(#function) at \(#line)): \(error.description)")
  exit(1)
}

let router = Router()

// TechEmpower test 0: plaintext
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
    var result = JSON(["message":"Hello, World!"])
    response.headers["Server"] = "Kitura-TechEmpower"
    response.status(.OK).send(json: result)
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

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
    do {
      let query = "SELECT randomNumber FROM World WHERE id=\(rnd)"
      let result = try dbConn.execute(query)
      guard result.status == PostgreSQL.Result.Status.TuplesOK else {
        response.status(.badRequest).send("Failed query: '\(query)' - status \(result.status)")
        return
      }
      guard result.count == 1 else {
        response.status(.badRequest).send("Error: query '\(query)' returned \(result.count) rows, expected 1")
        return
      }
      guard let randomNumber = try Int(String(result[0].data("randomNumber"))) else {
        response.status(.badRequest).send("Error: could not parse result as a number")
        return
      }
      response.status(.OK).send(json: JSON(["id":rnd, "randomNumber":randomNumber]))
    } catch let error as PostgreSQL.Connection.Error {
      print("Failed to query DB (\(#function) at \(#line)): \(error.description)")
      return
    }
    // next()
    // Avoid slowdown walking remaining routes
    try response.end()
}

// Create table 
router.get("/create") {
request, response, next in
    do {
      let query = "CREATE TABLE World ("
        + "id integer NOT NULL,"
        + "randomNumber integer NOT NULL default 0,"
        + "PRIMARY KEY  (id)"
        + ");"
      let result = try dbConn.execute(query)
      guard result.status == PostgreSQL.Result.Status.CommandOK else {
          response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status)</pre>")
          return
      }
    } catch {
      response.status(.badRequest).send("Failed to query DB (\(#function) at \(#line))")
      return
    }
    response.send("<h3>Table 'World' created</h3>")
    next()
}

// Delete table
router.get("/delete") {
request, response, next in
    do {
      let query = "DROP TABLE IF EXISTS World;"
      let result = try dbConn.execute(query)
      guard result.status == PostgreSQL.Result.Status.CommandOK else {
          response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status)</pre>")
          return
      }
    } catch {
      response.status(.badRequest).send("Failed to query DB (\(#function) at \(#line))")
      return
    }
    response.send("<h3>Table 'World' deleted</h3>")
    next()
}

// Populate DB with 10k rows
router.get("/populate") {
request, response, next in
    response.status(.OK).send("<h3>Populating World table with \(dbRows) rows</h3><pre>")
    for i in 1...dbRows {
#if os(Linux)
        let rnd = Int(random() % maxValue)
#else
        let rnd = Int(arc4random_uniform(UInt32(maxValue)))
#endif
      do {
        let query = "INSERT INTO World (id, randomNumber) VALUES (\(i), \(rnd));"
        let result = try dbConn.execute(query)
        guard result.status == PostgreSQL.Result.Status.CommandOK else {
          response.status(.badRequest).send("<pre>Error: query '\(query)' - status \(result.status)</pre>")
          return
        }
        response.send(".")
      } catch {
        response.status(.badRequest).send("Failed to query DB (\(#function) at \(#line))")
        return
      }
    }
    response.send("</pre><p>Done.</p>")
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
