/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
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
