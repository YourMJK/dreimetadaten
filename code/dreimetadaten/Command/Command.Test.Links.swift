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
		
		@Option(name: .shortAndLong, help: ArgumentHelp("The number retries before considering a link failed.", valueName: "count"))
		var retries: UInt = 1
		
		@Option(name: .customLong("skip"), help: ArgumentHelp("The number of items to skip at the start.", valueName: "count"))
		var skipCount: UInt = 0
		
		@Flag(name: .long, help: ArgumentHelp("Only check whether the strings are valid URLs."))
		var syntaxOnly: Bool = false
		
		@Flag(name: .long, help: ArgumentHelp("Run tests for different link types in parallel (only if more than one type specified)."))
		var parallel: Bool = false
		
		mutating func run() async throws {
			guard let webDataURL = URL(string: webDataURLString) else {
				throw ArgumentsError.invalidURL(string: webDataURLString)
			}
			let linkTypes = OrderedSet(linkTypeArgument.map(\.linkTypes).joined())
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			let objectModel = try await dbQueue.read { db in
				try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL)
			}
			let linkTester = LinkTester(objectModel: objectModel, syntaxOnly: syntaxOnly, retries: retries)
			
			if parallel && linkTypes.count > 1 {
				await parallelLinkTests(tester: linkTester, types: linkTypes)
			} else {
				await sequentialLinkTests(tester: linkTester, types: linkTypes)
			}
		}
		
		private func sequentialLinkTests(tester: LinkTester, types: OrderedSet<LinkTester.LinkType>) async {
			for linkType in types {
				do {
					defer {
						stderr("")
					}
					
					// Test link type
					try await tester.test(linkType: linkType, startIndex: skipCount) { progress in
						let progressLine = Self.formatProgress(progress, details: true)
						stderr("\(Self.clearLineSequence)\(linkType):  \(progressLine)", terminator: "")
					} failedLink: { result in
						stderr("")
						Self.printFailedLink(result: result)
					}
				}
				catch {
					Self.printError(error)
				}
			}
		}
		
		private func parallelLinkTests(tester: LinkTester, types: OrderedSet<LinkTester.LinkType>) async {
			// Prepare columns
			let maxNumber = 999
			let minColumnWidth = Self.formatProgress((maxNumber, maxNumber, nil), details: false).count
			let headerRow = types.map { "\($0)" }
			var tableFormatter = TableFormatter(separator: "  ", minimumColumnWidth: minColumnWidth)
			tableFormatter.updateColumnWidths(row: headerRow)
			
			// Print header
			let header = tableFormatter.format(row: headerRow)
			stderr(header)
			
			// Test link types
			await tester.test(linkTypes: Set(types), progressHandler: .init { totalProgress in
				let progressRow = types.map {
					guard let progress = totalProgress[$0] else {
						return ""
					}
					return Self.formatProgress(progress, details: false)
				}
				let progressLine = tableFormatter.format(row: progressRow)
				stderr("\(Self.clearLineSequence)\(progressLine)", terminator: "")
			} failedLink: { linkType, result in
				stderr("")
				Self.printFailedLink(result: result)
			} failedType: { error in
				stderr("")
				Self.printError(error)
			} completed: { _ in
				stderr("")
			})
			stderr("")
		}
		
		
		private static let clearLineSequence = "\u{1B}[2K\r"
		
		private static func formatProgress(_ progress: LinkTester.Progress, details: Bool) -> String {
			let item = details ? progress.current : nil
			let itemDetails = item.map { " (ID=\($0.hörspielID), URL=\($0.url))" } ?? ""
			return "\(progress.checked)/\(progress.total)\(itemDetails)"
		}
		
		private static func printFailedLink(result: LinkTester.Result) {
			let statusCode = result.statusCode.map { "\($0.value)" } ?? ""
			stdout("> FAILED: \(result.hörspielID)\t\(result.url)\t\(statusCode)")
		}
		
		private static func printError(_ error: Error) {
			stderr(error.localizedDescription)
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
		case amazonMusic
		case amazon
		case youTubeMusic
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
				case .amazonMusic: [.amazonMusic]
				case .amazon: [.amazon]
				case .youTubeMusic: [.youTubeMusic]
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
					.amazonMusic,
					.amazon,
					.youTubeMusic,
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
