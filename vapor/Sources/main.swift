import Vapor
import HTTP

let app = Droplet()
app.log.enabled = [.error, .fatal]

// TechEmpower test 0: plaintext
app.get("plaintext") { request in
    var response = Response(status: .ok, body: "Hello, World!")
    response.headers["Content-Type"] = "text/plain"
    return response
}

// TechEmpower test 1: JSON serialization
app.get("json") { request in
    return try JSON(node: [
            "message":"Hello, World!"
        ])
}

// Print what link to visit for default port
print("Visit http://localhost:8080")
app.run()
