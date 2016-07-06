import Curassow
import Inquiline


serve { request in
  return Response(.Ok, contentType: "text/plain", content: "Hello, World!")
}
