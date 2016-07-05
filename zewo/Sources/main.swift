import HTTPServer
import ContentNegotiationMiddleware
import JSONMediaType
import Router

let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [JSONMediaType()])

let router = Router(middleware: contentNegotiation) { router in

    router.get("/plaintext") { _ in
        return Response(body: "Hello, World!", headers: ["Content-Type": "text/plain"])
    }

    router.get("/json") { _ in
        let content: StructuredData = [
            "message": "Hello, World!"
        ]
        return Response(content: content)
    }
}
try Server(host: "0.0.0.0", port: 8080, reusePort: true, responder: router).start()
