import PackageDescription

let package = Package(
    name: "BlackfishApp",
    dependencies: [
        .Package(url: "https://github.com/djones6/blackfish.git", 
                 majorVersion: 0, minor: 8),
    ]
)
