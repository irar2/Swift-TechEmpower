import PackageDescription

let package = Package(
    name: "Zewo-TechEmpower",
    dependencies: [
        .Package(url: "https://github.com/Zewo/HTTPServer.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/Zewo/Router.git", majorVersion: 0, minor: 7),
	.Package(url: "https://github.com/Zewo/ContentNegotiationMiddleware.git", majorVersion: 0, minor: 7),
	.Package(url: "https://github.com/Zewo/JSONMediaType.git", majorVersion: 0, minor: 7),
    ]
)
