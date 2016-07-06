import Blackfish

let app = BlackfishApp()

app.get("/plaintext") {
request, response in
  response.status = .OK
  response.send(text: "Hello, World!")
}

app.listen(port: 8080) { error in
    if error == nil {
        print("App listening on port \(app.port)")
    } else {
        print(error)
    }
}
