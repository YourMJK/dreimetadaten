// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "dreimetadaten",
	platforms: [.macOS(.v13)],
	products: [
		.executable(name: "dreimetadaten", targets: ["dreimetadaten"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", from: "1.1.0"),
		.package(url: "https://github.com/YourMJK/swift-HTML", from: "1.0.1"),
		.package(url: "https://github.com/dehesa/CodableCSV", from: "0.6.0"),
		.package(url: "https://github.com/groue/GRDB.swift", from: "6.27.0"),
		.package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
		.package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
	],
	targets: [
		.executableTarget(
			name: "dreimetadaten",
			dependencies: [
				"CommandLineTool",
				.product(name: "HTML", package: "swift-HTML"),
				"CodableCSV",
				.product(name: "GRDB", package: "GRDB.swift"),
				.product(name: "Collections", package: "swift-collections"),
				"SwiftSoup",
			],
			path: "dreimetadaten"
		)
	]
)
