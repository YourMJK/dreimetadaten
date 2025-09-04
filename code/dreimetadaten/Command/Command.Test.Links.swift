//
//  Command.Test.Links.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB
import OrderedCollections


extension Command.Test {
	struct Links: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Test URLs to detect invalid or dead links/IDs.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The links to test.", valueName: "link type"))
		var linkTypeArgument: [LinkTypeArgument]
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Option(name: .customLong("webDataURL"), help: ArgumentHelp("The URL pointing to the web data directory. Used as the base URL for generated metadata links.", valueName: "URL"))
		var webDataURLString: String = Command.webDataURL.absoluteString
		
		@Option(name: .customLong("skip"), help: ArgumentHelp("The number of items to skip at the start.", valueName: "count"))
		var skipCount: UInt = 0
		
		@Flag(name: .long, help: ArgumentHelp("Only check whether the strings are valid URLs."))
		var syntaxOnly: Bool = false
		
		mutating func run() async throws {
			guard let webDataURL = URL(string: webDataURLString) else {
				throw ArgumentsError.invalidURL(string: webDataURLString)
			}
			let linkTypes = OrderedSet(linkTypeArgument.map(\.linkTypes).joined())
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			let objectModel = try await dbQueue.read { db in
				try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL)
			}
			let linkTester = LinkTester(objectModel: objectModel)
			
			for linkType in linkTypes {
				try await linkTester.test(linkType: linkType, startIndex: skipCount, syntaxOnly: syntaxOnly) { progress in
					let clearLine = "\u{1B}[2K\r"
					let id = progress.current.map { " (ID=\($0.hörspielID), URL=\($0.url))" } ?? ""
					stderr("\(clearLine)\(linkType):  \(progress.checked)/\(progress.total)\(id)", terminator: "")
				} failedLink: { result in
					let statusCode = result.statusCode.map { "\($0.value)" } ?? ""
					stderr("")
					stdout("> FAILED: \(result.hörspielID)\t\(result.url)\t\(statusCode)")
				}
				stderr("")
			}
		}
	}
}


extension Command.Test.Links {
	enum LinkTypeArgument: String, ArgumentEnum {
		case cover_itunes
		case cover_kosmos
		case dreifragezeichen
		case appleMusic
		case spotify
		case bookbeat
		//case amazonMusic
		case amazon
		//case youTubeMusic
		case deezer
		
		case all
		case covers
		case platforms
		
		var linkTypes: [LinkTester.LinkType] {
			switch self {
				case .cover_itunes: [.cover_itunes]
				case .cover_kosmos: [.cover_kosmos]
				case .dreifragezeichen: [.dreifragezeichen]
				case .appleMusic: [.appleMusic]
				case .spotify: [.spotify]
				case .bookbeat: [.bookbeat]
				//case .amazonMusic: [.amazonMusic]
				case .amazon: [.amazon]
				//case .youTubeMusic: [.youTubeMusic]
				case .deezer: [.deezer]
					
				case .all: LinkTester.LinkType.allCases
				case .covers: [
					.cover_itunes,
					.cover_kosmos,
				]
				case .platforms: [
					.dreifragezeichen,
					.appleMusic,
					.spotify,
					.bookbeat,
					//.amazonMusic,
					.amazon,
					//.youTubeMusic,
					.deezer,
				]
			}
		}
	}
	
	enum ArgumentsError: LocalizedError {
		case invalidURL(string: String)
		
		var errorDescription: String? {
			switch self {
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
			}
		}
	}
}
