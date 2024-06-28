//
//  Command.Load.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.06.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command {
	struct Load: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Load database from SQL dump.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Argument(help: ArgumentHelp("The path to the SQL dump input file.", valueName: "sql dump file"))
		var sqlFilePath: String = Command.sqlFile.relativePath
		
		@Option(name: .customLong("sqlite"), help: ArgumentHelp("The path to the SQLite CLI binary.", valueName: "sqlite binary"))
		var sqliteBinaryPath: String = SQLPorter.defaultSqliteBinaryPath
		
		@Flag(name: .shortAndLong, help: ArgumentHelp("Overwrite database file if it already exists."))
		var force: Bool = false
		
		func run() throws {
			let databaseFile = URL(fileURLWithPath: databaseFilePath, isDirectory: false)
			let sqlFile = URL(fileURLWithPath: sqlFilePath, isDirectory: false)
			let sqliteBinary = URL(fileURLWithPath: sqliteBinaryPath, isDirectory: false)
			
			if FileManager.default.fileExists(atPath: databaseFile.path) {
				guard force else {
					throw ArgumentsError.databaseExists(url: databaseFile)
				}
				// Clear existing database file
				do {
					try Data().write(to: databaseFile)
				}
				catch {
					throw SQLPorter.IOError.fileWritingFailed(url: databaseFile, error: error)
				}
			}
			
			let porter = SQLPorter(databaseFile: databaseFile, sqliteBinary: sqliteBinary)
			try porter.import(from: sqlFile)
		}
	}
}


extension Command.Load {
	enum ArgumentsError: LocalizedError {
		case databaseExists(url: URL)
		
		var errorDescription: String? {
			switch self {
				case .databaseExists(let url):
					return "Database file \"\(url.relativePath)\" already exists. Use option -f to overwrite it."
			}
		}
	}
}

