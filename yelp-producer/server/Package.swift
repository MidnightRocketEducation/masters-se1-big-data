// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "yelp-producer",
	platforms: [
		.macOS(.v15),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
		.package(url: "https://github.com/swift-server/swift-kafka-client", branch: "main"),
		.package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
		.package(url: "https://github.com/zijievv/CodingKeysGenerator", revision: "0a963c41d6d19f9e1521d2badc3f613b2bb92217"),
		.package(url: "https://github.com/flexlixrup/avro-swift", revision: "035628e09b7842623dfe1733d4aa0934581d2ec0"),
		.package(url: "https://github.com/lynixliu/SwiftAvroCore", from: "0.5.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "yp-daemon",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "CodingKeysGenerator", package: "CodingKeysGenerator"),
				.product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
				.product(name: "Kafka", package: "swift-kafka-client"),
				.product(name: "Avro", package: "avro-swift"),
				.product(name: "SwiftAvroCore", package: "SwiftAvroCore"),
			],
			swiftSettings: [
				.define("KAFKA_DEBUG_TOPIC", .when(configuration: .debug))
			]
		),
	]
)
