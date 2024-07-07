//
//  Command.Export.Web.swift
//  dreimetadaten
//
//  Created by YourMJK on 08.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Export {
	struct Web: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Export dataset for the web data directory.",
			alwaysCompactUsageOptions: true,
			examples: [
				.example(arguments: "metadata/json/Serie.json")
			]
		)
		
		@Argument(help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Argument(help: ArgumentHelp("The path to the output directory.", valueName: "output directory"))
		var outputDirectoryPath: String = Command.webDataDir.relativePath
		
		@Option(name: .customLong("webDataURL"), help: ArgumentHelp("The URL pointing to the web data directory. Used as the base URL for generated metadata links.", valueName: "URL"))
		var webDataURLString: String = Command.webDataURL.absoluteString
		
		@Option(name: .customLong("webDir"), help: ArgumentHelp("The path to the local web directory. Used to derive a local file path by replacing the base URL in metadata links.", valueName: "directory"))
		var webDirPath: String = Command.webDir.relativePath
		
		func run() throws {
			let outputDirectoryURL = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
			guard let webDataURL = URL(string: webDataURLString) else {
				throw ArgumentsError.invalidURL(string: webDataURLString)
			}
			let webDir = URL(fileURLWithPath: webDirPath, isDirectory: true)
			
			if !FileManager.default.fileExists(atPath: outputDirectoryURL.path) {
				try FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: false)
			}
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.read { db in
				let exporter = WebDataExporter(db: db, webDataURL: webDataURL, webDir: webDir)
				try exporter.export(to: outputDirectoryURL)
			}
		}
	}
}


extension Command.Export.Web {
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
