import Kitura

let router = Router()

func myHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) {
  response.headers["Content-Type"] = "text/plain";
  response.status(.OK).send("Hello, world!");
  next()
}

func myEndHandler(request: RouterRequest, response: RouterResponse, next: ()->Void) throws {
  response.headers["Content-Type"] = "text/plain";
  response.status(.OK).send("Hello, world!");
  try response.end()
}

// Evaluate performance penalty of having a large number of routes present
for i in 0...99 {
  router.get("/route\(i)", handler: myHandler)
}

// TechEmpower test 0: plaintext
router.get("/plaintext", handler: myEndHandler)

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
