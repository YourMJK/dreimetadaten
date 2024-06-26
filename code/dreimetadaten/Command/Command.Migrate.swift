//
//  Command.Migrate.swift
//  dreimetadaten
//
//  Created by YourMJK on 28.03.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command {
	struct Migrate: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Migrate previous JSON dataset to new relational database.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the JSON dataset input file.", valueName: "json file"))
		var jsonFilePath: String
		
		@Argument(help: ArgumentHelp("The path to the SQLite database output file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Flag(help: ArgumentHelp("Only create schema."))
		var noValues: Bool = false
		
		@Flag(help: ArgumentHelp("Assume schema is already present in database and only insert values into tables."))
		var noSchema: Bool = false
		
		func run() throws {
			let jsonFileURL = URL(fileURLWithPath: jsonFilePath, isDirectory: false)
			
			let objectModel = try MetadataObjectModel(fromJSON: jsonFileURL)
			let migrator = Migrator(objectModel: objectModel)
			try migrator.migrate()
			let relationalModel = migrator.relationalModel
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.write { db in
				if !noSchema {
					try MetadataRelationalModel.createSchema(db: db)
				}
				if !noValues {
					try relationalModel.insertValues(db: db)
				}
			}
		}
	}
}
