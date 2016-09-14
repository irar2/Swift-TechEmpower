import Kitura
import Dispatch

let router = Router()

let mySema = DispatchSemaphore(value: 2)

// Test semaphores under load
router.get("/test") {
request, response, next in
    let ret = mySema.wait(timeout: .distantFuture)
    if (ret == DispatchTimeoutResult.timedOut) {
      response.status(.badRequest).send("Semaphore returned rc=\(ret)")
    } else {
      response.headers["Content-Type"] = "text/plain"
      response.status(.OK).send("Hello, world!")
    }
    mySema.signal()
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
