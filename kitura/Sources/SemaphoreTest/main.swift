import Kitura
import KituraNet
import KituraSys
import Dispatch

let router = Router()

let mySema = dispatch_semaphore_create(2)

// Test semaphores under load
router.get("/test") {
request, response, next in
    let ret = dispatch_semaphore_wait(mySema, DISPATCH_TIME_FOREVER)
    if (ret != 0) {
      response.status(.badRequest).send("Semaphore returned rc=\(ret)")
    } else {
      response.headers["Content-Type"] = "text/plain"
      response.status(.OK).send("Hello, world!")
    }
    dispatch_semaphore_signal(mySema)
    next()
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
