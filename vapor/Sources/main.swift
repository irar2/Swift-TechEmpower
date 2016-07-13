import Vapor

let app = Application()
app.log.enabled = [.error, .fatal]

/**
	This first route will return the welcome.html
	view to any request to the root directory of the website.

	Views referenced with `app.view` are by default assumed
	to live in <workDir>/Resources/Views/ 

	You can override the working directory by passing
	--workDir to the application upon execution.
*/
app.get("/") { request in
	return try app.view("welcome.html")
}

// TechEmpower test 0: plaintext
app.get("plaintext") { request in
    var response = Response(status: .ok, body: "Hello, World!")
    response.headers["Content-Type"] = "text/plain"
    return response
}

// TechEmpower test 1: JSON serialization
app.get("json") { request in
    return JSON([
            "message":"Hello, World!"
        ])
}

// Print what link to visit for default port
print("Visit http://localhost:8080")
app.start()
