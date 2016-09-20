import KituraNet
import Dispatch
import CCurl
import HeliumLogger

HeliumLogger.use()

var queue = DispatchQueue(label: "foo", attributes: Dispatch.DispatchQueue.Attributes.concurrent)
var group = DispatchGroup()

func block(_ num: Int) -> () -> Void {
    return {
        var i=0
        while i < 1000 {
            i += 1
            let request = HTTP.request("http://localhost:8080/plaintext") {
                response in
                if let status = response?.statusCode {
                    if (i % 1000 == 0) {
                        print("\(num): \(i) requests, latest status = \(status)")
                    }
                } else {
                    print("Disaster")
                }
            }
            request.end()
        }
    }
}

while true {
    print("GO")
    for i in 1...4 {
        queue.async(group: group, execute: block(i))
    }
    _ = group.wait(timeout: .distantFuture)

    print("Hit enter to go again: ", terminator: "")
    let _ = readLine()
}
