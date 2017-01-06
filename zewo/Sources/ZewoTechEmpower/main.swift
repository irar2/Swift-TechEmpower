import Foundation
import HTTPServer

// Set port based on environment
let port = Int(ProcessInfo.processInfo.environment["PORT"] ?? "8080") ?? 8080

// Select middleware
//let log = LogMiddleware()
//let recover = RecoveryMiddleware()
let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json])
//let middleware: [Middleware] = [contentNegotiation, recover, log]
let middleware: [Middleware] = [contentNegotiation]

// Define routes
let router = BasicRouter() { route in

    //
    // TechEmpower test 6: plaintext
    //
    route.get("/plaintext") { _ in
        let headers: Headers = ["Content-Type": "text/plain",
                       "Server": "zewo"]
        let body = "Hello, World!"
        return Response(headers: headers, body: body)
    }

    //
    // TechEmpower test 1: JSON serialization
    //
    route.get("/json") { _ in
        let headers: Headers = ["Server": "zewo"]
        let content = [
            "message": "Hello, World!"
        ]
        return Response(headers: headers, content: content, contentType: .json)
    }

    //
    // TechEmpower test 2: Single database query (raw, no ORM)
    //
    route.get("/db") { _ in
        let headers: Headers = ["Server": "zewo"]
        var dict = try getRandomRow()
        return Response(headers: headers, content: dict, contentType: .json)
    }   

    //
    // TechEmpower test 3: Multiple database queries (raw, no ORM)
    // Get param provides number of queries: /queries?queries=N
    //
    route.get("/queries") {
    request in
        let headers: Headers = ["Server": "zewo"]
        var queriesParam = 1
        for queryItem in request.queryItems {
            if queryItem.name == "queries" {
                queriesParam = Int(queryItem.value ?? "1") ?? 1
                break
            }
        }
        let numQueries = max(1, min(queriesParam, 500))      // Snap to range of 1-500 as per test spec
        var results: [[String:Int]] = []
        for i in 1...numQueries {
            var dict = try getRandomRow()
            results.append(dict)
        }
        // Return JSON representation of array of results
        return try Response(headers: headers, content: results, contentType: .json)
    }
    
    //
    // TechEmpower test 4: fortunes (TODO)
    //
    route.get("/fortunes") {
    request in
        let headers: Headers = ["Server": "zewo"]
        return Response(status: .badRequest, headers: headers, body: "Unimplemented")
    }
    
    //
    // TechEmpower test 5: updates (raw, no ORM)
    //
    route.get("/updates") {
    request in
        let headers: Headers = ["Server": "zewo"]
        var queriesParam = 1
        for queryItem in request.queryItems {
            if queryItem.name == "queries" {
                queriesParam = Int(queryItem.value ?? "1") ?? 1
                break
            }
        }
        let numQueries = max(1, min(queriesParam, 500))      // Snap to range of 1-500 as per test spec
        var results: [[String:Int]] = []
        for i in 1...numQueries {
            var dict = try getRandomRow()
            try updateRow(id: dict["id"]!)
            results.append(dict)
        }
        // Return JSON representation of array of results
        return try Response(headers: headers, content: results, contentType: .json)
    }

}

// Connect to database
try connect()

// Start HTTP server
try Server(host: "0.0.0.0", port: port, reusePort: true, middleware: middleware, responder: router).start()
