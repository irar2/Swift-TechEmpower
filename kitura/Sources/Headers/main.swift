import Kitura
import Foundation

let router = Router()

// Headers experiment
router.get("/headers") {
request, response, next in

  // Multiple Set-Cookie headers
  response.cookies["Boo"] = HTTPCookie(properties: [.path: "/blah", .name: "Boo", .value: "Yah", .domain: "foo.bar.com"])
  response.cookies["Foo"] = HTTPCookie(properties: [.path: "/fred", .name: "Foo", .value: "Bar", .domain: "foo.bar.com"])
  response.cookies["Baz"] = HTTPCookie(properties: [.path: "/wibble", .name: "Baz", .value: "Off", .domain: "foo.bar.com"])

  // A header with multiple values
  response.headers.append("MultipleValues", value: "Foo")
  response.headers.append("MultipleValues", value: "Bar")
  response.headers.append("MultipleValues", value: "Baz")

  // Respond with a list of headers sent in the request  
  var result = "<h3>Request Headers:</h3>\n<pre>"
  for header in request.headers {
    if let value = header.1 {
      result += "\n\t\(header.0): \(value)"
    } else {
      result += "\n\t\(header.0)"
    }
  }

  // Respond with a list of headers being sent in the response
  result += "</pre>\n<h3>Response Headers:</h3>\n<pre>"
  for header in response.headers {
    if let value = header.1 {
      result += "\n\t\(header.0): \(value)"
    } else {
      result += "\n\t\(header.0)"
    }
  }

  // Respond with a list of cookies being sent in the response
  result += "</pre>\n<h3>Cookies:</h3>\n<pre>"
  for cookie in response.cookies {
    result += "\n\t\(cookie.0): \(cookie.1.properties!)"
  }
  result += "</pre>"

  response.status(.OK).send(result)
  next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
