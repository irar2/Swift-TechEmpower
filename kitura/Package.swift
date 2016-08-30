import PackageDescription

let package = Package(
    name: "Kitura-TechEmpower",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 0, minor: 28),
        .Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", majorVersion: 0, minor: 28),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 0, minor: 15),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 0, minor: 7),
    ])

