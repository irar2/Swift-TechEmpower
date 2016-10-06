import HTTPServer

let router = BasicRouter() { route in

    route.get("/plaintext") { _ in
        return Response(headers: ["Content-Type": "text/plain"], body: "Hello, World!")
    }

    route.get("/json") { _ in
        let content = [
            "message": "Hello, World!"
        ]
        return Response(content: content, contentType: .json)
    }
}

let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json])

try Server(host: "0.0.0.0", port: 8080, reusePort: true, middleware: [contentNegotiation], responder: router).start()
