// swift-tools-version: 5.7

import PackageDescription

let package = Package(
	name: "dreimetadaten",
	products: [
		.executable(name: "dreimetadaten", targets: ["dreimetadaten"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", from: "1.1.0"),
		.package(url: "https://github.com/dehesa/CodableCSV", from: "0.6.0"),
		.package(url: "https://github.com/groue/GRDB.swift", from: "6.27.0"),
	],
	targets: [
		.executableTarget(
			name: "dreimetadaten",
			dependencies: [
				"CommandLineTool",
				"CodableCSV",
				.product(name: "GRDB", package: "GRDB.swift"),
			],
			path: "dreimetadaten"
		)
	]
)
