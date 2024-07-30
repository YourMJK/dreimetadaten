//
//  Command.Export.JSON.swift
//  dreimetadaten
//
//  Created by YourMJK on 29.06.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Export {
	struct JSON: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Export object model as JSON files.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the JSON output directory.", valueName: "output directory"))
		var jsonDirectoryPath: String = Command.jsonDir.relativePath
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Option(name: .customLong("webDataURL"), help: ArgumentHelp("The URL pointing to the web data directory. Used as the base URL for generated metadata links.", valueName: "URL"))
		var webDataURLString: String = Command.webDataURL.absoluteString
		
		func run() throws {
			let jsonDirectoryURL = URL(fileURLWithPath: jsonDirectoryPath, isDirectory: true)
			guard let webDataURL = URL(string: webDataURLString) else {
				throw ArgumentsError.invalidURL(string: webDataURLString)
			}
			
			if !FileManager.default.fileExists(atPath: jsonDirectoryURL.path) {
				try FileManager.default.createDirectory(at: jsonDirectoryURL, withIntermediateDirectories: false)
			}
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.read { db in
				let exporter = JSONExporter(db: db, webDataURL: webDataURL)
				try exporter.export(to: jsonDirectoryURL)
			}
		}
	}
}


extension Command.Export.JSON {
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
