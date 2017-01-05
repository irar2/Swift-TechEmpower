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
    // TechEmpower test 2: Single database query
    //
    route.get("/db") { _ in
        let headers: Headers = ["Server": "zewo"]
        var dict = try getRandomRow()
        return Response(headers: headers, content: dict, contentType: .json)
    }   

}

// Connect to database
try connect()

// Start HTTP server
try Server(host: "0.0.0.0", port: port, reusePort: true, middleware: middleware, responder: router).start()
