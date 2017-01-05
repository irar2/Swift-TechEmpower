import PackageDescription

let package = Package(
    name: "Zewo-TechEmpower",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTPServer.git", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/Zewo/PostgreSQL.git", majorVersion: 0, minor: 14),
    ]
)
