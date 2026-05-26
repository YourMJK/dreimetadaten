//
//  Command.Export.SQL.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.06.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Export {
	struct SQL: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Dump database to SQL format.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the SQL dump output file.", valueName: "sql dump file"))
		var sqlFilePath: String = Command.sqlFile.relativePath
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Option(name: .customLong("sqlite"), help: ArgumentHelp("The path to the SQLite CLI binary.", valueName: "sqlite binary"))
		var sqliteBinaryPath: String = SQLPorter.defaultSqliteBinaryPath
		
		func run() throws {
			let databaseFile = URL(filePath: databaseFilePath, directoryHint: .notDirectory)
			let sqlFile = URL(filePath: sqlFilePath, directoryHint: .notDirectory)
			let sqliteBinary = URL(filePath: sqliteBinaryPath, directoryHint: .notDirectory)
			
			let porter = try SQLPorter(databaseFile: databaseFile, sqliteBinary: sqliteBinary)
			try porter.export(to: sqlFile)
		}
	}
}

