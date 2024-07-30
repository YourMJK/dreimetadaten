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
			let databaseFile = URL(fileURLWithPath: databaseFilePath, isDirectory: false)
			let sqlFile = URL(fileURLWithPath: sqlFilePath, isDirectory: false)
			let sqliteBinary = URL(fileURLWithPath: sqliteBinaryPath, isDirectory: false)
			
			let porter = SQLPorter(databaseFile: databaseFile, sqliteBinary: sqliteBinary)
			try porter.export(to: sqlFile)
		}
	}
}

