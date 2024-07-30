//
//  Command.Export.TSV.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.06.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Export {
	struct TSV: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Export database as TSV files.",
			alwaysCompactUsageOptions: true
		)
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Argument(help: ArgumentHelp("The path to the TSV output directory.", valueName: "output directory"))
		var tsvDirectoryPath: String = Command.tsvDir.relativePath
		
		func run() throws {
			let tsvDirectoryURL = URL(fileURLWithPath: tsvDirectoryPath, isDirectory: true)
			
			if !FileManager.default.fileExists(atPath: tsvDirectoryURL.path) {
				try FileManager.default.createDirectory(at: tsvDirectoryURL, withIntermediateDirectories: false)
			}
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.read { db in
				let relationalModel = try MetadataRelationalModel(fromDatabase: db)
				try relationalModel.writeTSVFiles(to: tsvDirectoryURL)
			}
		}
	}
}

