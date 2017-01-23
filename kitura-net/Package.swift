import PackageDescription

let package = Package(
    name: "KituraNet-TechEmpower",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", majorVersion: 1, minor: 5),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1, minor: 5),
    ])

