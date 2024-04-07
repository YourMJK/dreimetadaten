//
//  Command.Migrate.swift
//  dreimetadaten
//
//  Created by YourMJK on 28.03.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command {
	struct Migrate: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Migrate previous JSON dataset to new relational database.",
			alwaysCompactUsageOptions: true
		)
		
		@Argument(help: ArgumentHelp("The path to the JSON dataset input file.", valueName: "json file"))
		var jsonFilePath: String
		
		@Argument(help: ArgumentHelp("The path to the TSV output directory.", valueName: "output directory"))
		var tsvDirectoryPath: String
		
		func run() throws {
			let jsonFileURL = URL(fileURLWithPath: jsonFilePath, isDirectory: false)
			let tsvDirectoryURL = URL(fileURLWithPath: tsvDirectoryPath, isDirectory: true)
			
			if !FileManager.default.fileExists(atPath: tsvDirectoryURL.path) {
				try FileManager.default.createDirectory(at: tsvDirectoryURL, withIntermediateDirectories: false)
			}
			
			let objectModel = try MetadataObjectModel(fromJSON: jsonFileURL)
			let migrator = Migrator(objectModel: objectModel)
			try migrator.migrate()
			let relationalModel = migrator.relationalModel
			
			try relationalModel.writeTSVFiles(to: tsvDirectoryURL)
		}
	}
}
