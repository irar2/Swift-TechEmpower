import Kitura
import KituraNet
import KituraSys
import SwiftyJSON
import Foundation
import CouchDB

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

// Connection properties for testing Cloudant or CouchDB instance
let connProperties = ConnectionProperties(
    host: "localhost",         // httpd address
    port: 5984,                // httpd port
    secured: false,            // https or http
    username: nil,             // username
    password: nil              // password
)
let couchDBClient = CouchDBClient(connectionProperties: connProperties)
let dbName = "world"
let dbRows = 100
let maxValue = 10000
let world = couchDBClient.database(dbName)

let router = Router()

// TechEmpower test 0: plaintext
router.get("/plaintext") {
request, response, next in
    response.headers["Content-Type"] = "text/plain"
    response.status(.OK).send("Hello, world!")
    next()
}

// TechEmpower test 1: JSON serialization
router.get("/json") {
request, response, next in
    var result = JSON(["message":"Hello, World!"])
    response.headers["Server"] = "Kitura-TechEmpower"
    response.status(.OK).send(json: result)
    next()
}

// Create DB
router.get("/create") {
request, response, next in
    couchDBClient.createDB(dbName) {
    (db: Database?, err: NSError?) in
      if let err = err {
          response.status(.badRequest).send("<pre>Error: \(err.localizedDescription) Code: \(err.code)</pre>")
      } else {
          response.status(.OK).send("<pre>OK</pre>")
      }
    }
    response.send("<h3>DB \(dbName) created</h3>")
    next()
}

// Create DB
router.get("/delete") {
request, response, next in
    couchDBClient.deleteDB(dbName) {
      (err: NSError?) in
      if let err = err {
          response.status(.badRequest).send("<pre>Error: \(err.localizedDescription) Code: \(err.code)</pre>")
      } else {
          response.status(.OK).send("<pre>OK</pre>")
      }
    }
    response.send("<h3>DB \(dbName) deleted</h3>")
    next()
}

// Populate DB with 10k rows
router.get("/populate") {
request, response, next in
    response.status(.OK).send("<h3>Populating database</h3><pre>")
    var keepGoing = true
    populate: for i in 1...dbRows {
#if os(Linux)
        let rnd = Int(random() % maxValue)
#else
        let rnd = Int(arc4random_uniform(UInt32(maxValue)))
#endif
      var document:JSON = JSON(["_id": "\(i)"])
      document["randomNumber"].int = rnd
      world.create(document, callback: {
        (id: String?, rev: String?, document: JSON?, error: NSError?) in
        if let error = error {
          response.status(.badRequest).send("Error: \(error.localizedDescription) Code: \(error.code)")
          keepGoing = false
          return
        }
        guard let myid = id else {
          response.status(.badRequest).send("Error: no id was returned (row \(i) of \(dbRows))")
          keepGoing = false
          return
        }
        response.send("id:\(myid)\n")
      })
      if (!keepGoing) { break populate }
    }
    response.send((keepGoing ? "</pre><p>Done.</p>" : "</pre><p>Failed.</p>"))
    next()
}

// TechEmpower test 2: Single database query
router.get("/db") {
request, response, next in
    // Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
    // Convert to object using object-relational mapping (ORM) tool
    // Serialize object to JSON - example: {"id":3217,"randomNumber":2149}

#if os(Linux)
        let rnd = Int(random() % dbRows)
#else
        let rnd = Int(arc4random_uniform(UInt32(dbRows)))
#endif
    world.retrieve("\(rnd)") {
      (json: JSON?, err: NSError?) in
      if let err = err {
        response.status(.badRequest).send("Error: \(err.localizedDescription) Code: \(err.code)")
        return
      }
      guard let json = json else {
        response.status(.badRequest).send("Error: no result returned for record \(rnd)")
        return
      }
      //response.status(.OK).send(json: json)
      // Dispose of '_rev' field
      response.status(.OK).send(json: JSON(["_id":json["_id"], "randomNumber":json["randomNumber"]]))
    }
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
