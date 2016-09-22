import HTTP
import Transport

final class Responder: HTTP.Responder {
    func respond(to request: Request) throws -> Response {
        let body = "Hello, World!".makeBody()
        return Response(body: body)
    }
}

let port = 8080
let server = try Server<TCPServerStream, Parser<Request>, Serializer<Response>>(port: port)

print("visit http://localhost:\(port)/")
try server.start(responder: Responder()) { error in
    print("Got error: \(error)")
}
