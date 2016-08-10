import Kitura
import KituraNet
import KituraSys
import Dispatch

let router = Router()

#if os(Linux)
let mySema = dispatch_semaphore_create(2)
#else
let mySema = DispatchSemaphore(value: 2)
#endif

// Test semaphores under load
router.get("/test") {
request, response, next in
#if os(Linux)
    let ret = dispatch_semaphore_wait(mySema, DISPATCH_TIME_FOREVER)
    if (ret != 0) {
      response.status(.badRequest).send("Semaphore returned rc=\(ret)")
    } else {
      response.headers["Content-Type"] = "text/plain"
      response.status(.OK).send("Hello, world!")
    }
    dispatch_semaphore_signal(mySema)
#else
    let ret = mySema.wait(timeout: .distantFuture)
    if (ret == DispatchTimeoutResult.timedOut) {
      response.status(.badRequest).send("Semaphore returned rc=\(ret)")
    } else {
      response.headers["Content-Type"] = "text/plain"
      response.status(.OK).send("Hello, world!")
    }
    mySema.signal()
#endif
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
