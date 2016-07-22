# Swift-TechEmpower
(work in progress) Swift implementation of the TechEmpower benchmarks running on Kitura

## Prereqs
Swiftenv - not required but highly recommended: https://github.com/kylef/swiftenv
### Linux
`apt-get install libpq-dev`
### Mac
`brew install postgresql`

## Building the Kitura example
Use the provided `build.sh` script, either `./build.sh debug` or `./build.sh release`

Or, the following command depending on platform:
### Linux
`swift build -Xcc -fblocks -Xcc -I/usr/include/postgresql` and optionally `-c release`
### Mac
`swift build -Xcc -I/usr/local/include -Xlinker -L/usr/local/lib/` and optionally `-c release`

## Running
To test that the Kitura implementation is running:
`.build/release/TechEmpower`
`curl http://127.0.0.1:8080/plaintext` should return `Hello, World!`

## Benchmarking
