import Frank
import Inquiline

get("plaintext") { request in
  return Response(.Ok, headers: [("Content-Type", "text/plain")], content: "Hello, World!")
}

