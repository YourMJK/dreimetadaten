//
//  Command.Import.swift
//  dreimetadaten
//
//  Created by YourMJK on 13.09.24.
//

import Foundation
import ArgumentParser
import GRDB


extension Command {
	struct Import: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Import foreign dataset.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the JSON input file.", valueName: "json file"))
		var jsonFilePath: String
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		func run() throws {
			let jsonFileURL = URL(fileURLWithPath: jsonFilePath, isDirectory: false)
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.write { db in
				let importer = Importer(db: db)
				try importer.importData(from: jsonFileURL)
			}
		}
	}
}
