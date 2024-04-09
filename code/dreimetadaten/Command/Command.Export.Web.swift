//
//  Command.Export.Web.swift
//  dreimetadaten
//
//  Created by YourMJK on 08.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command.Export {
	struct Web: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Export dataset for the web data directory.",
			alwaysCompactUsageOptions: true,
			examples: [
				.example(arguments: "metadata/json/Serie.json")
			]
		)
		
		@Argument(help: ArgumentHelp("The path to the JSON dataset input file.", valueName: "json file"))
		var jsonFilePath: String
		
		@Argument(help: ArgumentHelp("The path to the output directory.", valueName: "output directory"))
		var outputDirectoryPath: String = Command.url(projectRelativePath: "web/data").relativePath
		
		func run() throws {
			let jsonFileURL = URL(fileURLWithPath: jsonFilePath, isDirectory: false)
			let outputDirectoryURL = URL(fileURLWithPath: outputDirectoryPath, isDirectory: true)
			
			var directory: ObjCBool = false
			guard FileManager.default.fileExists(atPath: outputDirectoryURL.path, isDirectory: &directory), directory.boolValue else {
				throw ArgumentsError.noSuchDirectory(url: outputDirectoryURL)
			}
			
			let objectModel = try MetadataObjectModel(fromJSON: jsonFileURL)
			let exporter = WebDataExporter(objectModel: objectModel)
			try exporter.export(to: outputDirectoryURL)
		}
	}
}


extension Command.Export.Web {
	enum ArgumentsError: LocalizedError {
		case noSuchDirectory(url: URL)
		
		var errorDescription: String? {
			switch self {
				case .noSuchDirectory(let url):
					return "No such directory \"\(url.relativePath)\""
			}
		}
	}
}
