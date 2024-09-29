//
//  Command.WebBuild.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command {
	struct WebBuild: ParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "webbuild",
			abstract: "Generate HTML code for the web page using a template file.",
			alwaysCompactUsageOptions: true
		)
		
		struct IOOptions: ParsableArguments {
			private static let argumentHelpAutomaticDefault = "(default: automatic based on <page>)"
			
			@Option(name: .customLong("template"), help: ArgumentHelp("The path to the template HTML input file to use for filling in the placeholders. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var templateFilePath: String?
			
			@Option(name: .customLong("output"), help: ArgumentHelp("The path to the HTML output file. \(argumentHelpAutomaticDefault)", valueName: "html file"))
			var outputFilePath: String?
		}
		
		@Argument(help: ArgumentHelp("The page to generate the HTML code for.", valueName: "page"))
		var pageArgument: PageArgument
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		@Option(name: .customLong("webDataURL"), help: ArgumentHelp("The URL pointing to the web data directory. Used as the base URL for generated metadata links.", valueName: "URL"))
		var webDataURLString: String = Command.webDataURL.absoluteString
		
		@OptionGroup(title: "IO Options")
		var ioOptions: IOOptions
		
		func run() throws {
			guard let webDataURL = URL(string: webDataURLString) else {
				throw ArgumentError.invalidURL(string: webDataURLString)
			}
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.read { db in
				let needsObjectModel = pageArgument.pages.contains { page in
					if case .collection(_) = page { return true } else { return false }
				}
				let objectModel = needsObjectModel ? try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL) : nil
				
				for page in pageArgument.pages {
					func automaticDefault(_ optionKeyPath: KeyPath<IOOptions, String?>, defaultIn defaultDir: URL) throws -> URL {
						if let path = ioOptions[keyPath: optionKeyPath] {
							return URL(fileURLWithPath: path, isDirectory: false)
						}
						let defaultFile = page.htmlFile
						return defaultDir.appendingPathComponent(defaultFile, isDirectory: false)
					}
					let templateFileURL = try automaticDefault(\.templateFilePath, defaultIn: Command.webTemplatesDir)
					let outputFileURL = try automaticDefault(\.outputFilePath, defaultIn: Command.webDir)
					
					var isDirectory: ObjCBool = false
					guard FileManager.default.fileExists(atPath: templateFileURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
						throw ArgumentError.noSuchFile(url: templateFileURL)
					}
					
					let pageBuilder: PageBuilder
					switch page {
						case .collection(let collectionType):
							pageBuilder = try CollectionPageBuilder(
								objectModel: objectModel!,
								collectionType: collectionType,
								templateFile: templateFileURL,
								host: webDataURL.host!
							)
							
						case .statistik:
							pageBuilder = try StatisticsPageBuilder(db: db, templateFile: templateFileURL)
					}
					
					try pageBuilder.build()
					try pageBuilder.content.write(to: outputFileURL, atomically: false, encoding: .utf8)
				}
			}
		}
	}
}


extension Command.WebBuild {
	enum PageArgument: String, ArgumentEnum {
		case serie
		case spezial
		case kurzgeschichten
		case die_dr3i
		case kids
		
		case statistik
		case all
		
		var pages: [Page] {
			switch self {
				case .serie: return [.collection(type: .serie)]
				case .spezial: return [.collection(type: .spezial)]
				case .kurzgeschichten: return [.collection(type: .kurzgeschichten)]
				case .die_dr3i: return [.collection(type: .die_dr3i)]
				case .kids: return [.collection(type: .kids)]
				case .statistik: return [.statistik]
				case .all:
					return CollectionType.allCases.map(Page.collection(type:)) + [
						.statistik
					]
			}
		}
	}
	enum Page {
		case collection(type: CollectionType)
		case statistik
		
		var htmlFile: String {
			switch self {
				case .collection(let type): return type.htmlFile
				case .statistik: return "statistik.html"
			}
		}
	}
	
	enum ArgumentError: LocalizedError {
		case noSuchFile(url: URL)
		case invalidURL(string: String)
		
		var errorDescription: String? {
			switch self {
				case .noSuchFile(let url):
					return "No such file \"\(url.relativePath)\""
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
			}
		}
	}
}
