//
//  Command.WebBuild.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command {
	struct WebBuild: ParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "webbuild",
			abstract: "Generate HTML code for the web page using a template file.",
			alwaysCompactUsageOptions: true
		)
		
		struct IOOptions: ParsableArguments {
			private static let argumentHelpAutomaticDefault = "(default: automatic based on <collection type>)"
			
			@Option(name: .customLong("json"), help: ArgumentHelp("The path to the JSON dataset input file. \(argumentHelpAutomaticDefault)", valueName: "json file"))
			var jsonFilePath: String?
			
			@Option(name: .customLong("template"), help: ArgumentHelp("The path to the template HTML input file to use for filling in the placeholders. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var templateFilePath: String?
			
			@Option(name: .customLong("output"), help: ArgumentHelp("The path to the HTML output file. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var outputFilePath: String?
		}
		
		@Argument(help: ArgumentHelp("The collection type to generate the HTML code for.", valueName: "collection type"))
		var collectionType: CollectionType
		
		@OptionGroup(title: "IO Options")
		var ioOptions: IOOptions
		
		func run() throws {
			func automaticDefault(_ optionKeyPath: KeyPath<IOOptions, String?>, defaultFile defaultFileKeyPath: KeyPath<CollectionType, String>, in defaultDir: URL) throws -> URL {
				let url = ioOptions[keyPath: optionKeyPath]
					.map { URL(fileURLWithPath: $0, isDirectory: false) }
					?? defaultDir.appendingPathComponent(collectionType[keyPath: defaultFileKeyPath], isDirectory: false)
				
				var directory: ObjCBool = false
				guard FileManager.default.fileExists(atPath: url.path, isDirectory: &directory), !directory.boolValue else {
					throw IOError.noSuchFile(url: url)
				}
				return url
			}
			
			let jsonFileURL = try automaticDefault(\.jsonFilePath, defaultFile: \.jsonFile, in: Command.jsonDir)
			let templateFileURL = try automaticDefault(\.templateFilePath, defaultFile: \.htmlFile, in: Command.webTemplatesDir)
			let outputFileURL = try automaticDefault(\.outputFilePath, defaultFile: \.htmlFile, in: Command.webDir)
			
			let templateContent: String
			do {
				templateContent = try String(contentsOf: templateFileURL, encoding: .utf8)
			}
			catch {
				throw IOError.fileReadingFailed(url: templateFileURL, error: error)
			}
			
			let objectModel = try MetadataObjectModel(fromJSON: jsonFileURL)
			let webBuilder = WebBuilder(
				objectModel: objectModel,
				collectionType: collectionType,
				templateContent: templateContent,
				host: Command.webURL.host!
			)
			try webBuilder.build()
			
			do {
				try webBuilder.content.write(to: outputFileURL, atomically: false, encoding: .utf8)
			}
			catch {
				throw IOError.fileWritingFailed(url: outputFileURL, error: error)
			}
		}
	}
}


extension Command.WebBuild {
	enum IOError: LocalizedError {
		case noSuchFile(url: URL)
		case fileReadingFailed(url: URL, error: Error)
		case fileWritingFailed(url: URL, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .noSuchFile(let url):
					return "No such file \"\(url.relativePath)\""
				case .fileReadingFailed(let url, let error):
					return "Couldn't read file \"\(url.relativePath)\": \(error.localizedDescription)"
				case .fileWritingFailed(let url, let error):
					return "Couldn't write to file \"\(url.relativePath)\": \(error.localizedDescription)"
			}
		}
	}
}
