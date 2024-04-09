//
//  WebDataExporter.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation
import CommandLineTool


struct WebDataExporter {
	let objectModel: MetadataObjectModel
	
	private static let filenameAllowed =
		CharacterSet(charactersIn: "a"..."z")
		.union(CharacterSet(charactersIn: "A"..."Z"))
		.union(CharacterSet(charactersIn: "0"..."9"))
		.union(CharacterSet(["-", "_"]))
	private static let filenameReplacements: [Character: String] = [
		"ä": "ae",
		"Ä": "Ae",
		"ö": "oe",
		"Ö": "Oe",
		"ü": "ue",
		"Ü": "Ue",
		"ß": "ss",
		" ": "-"
	]
	
	
	func export(to outputDir: URL) throws {
		for collectionType in CollectionType.allCases {
			guard let collection = objectModel[keyPath: collectionType.objectModelKeyPath] as? [MetadataObjectModel.Hörspiel] else {
				continue
			}
			
			let collectionURL = outputDir.appendingPathComponent(collectionType.fileName, isDirectory: true)
			try Self.createDirectoryIfNeccessary(at: collectionURL)
			
			let numberOfDigts: UInt = {
				var number = collection.count
				var orderOfMagnitude: UInt = 0
				while number != 0 {
					orderOfMagnitude += 1
					number /= 10
				}
				return orderOfMagnitude
			}()
			
			for hörspiel in collection {
				// Generate directory name for hörspiel
				let name: String = try {
					if let folge = hörspiel as? MetadataObjectModel.Folge, folge.nummer >= 0 {
						return String(format: "%0\(numberOfDigts)d", folge.nummer)
					}
					
					guard let titel = hörspiel.titel else {
						throw ExporterError.missingTitel(hörspiel: hörspiel)
					}
					var name = ""
					for character in titel {
						if character.unicodeScalars.allSatisfy(Self.filenameAllowed.contains(_:)) {
							name.append(character)
						}
						else if let replacement = Self.filenameReplacements[character] {
							name.append(replacement)
						}
					}
					return name
				}()
				let url = collectionURL.appendingPathComponent(name, isDirectory: true)
				
				// Export metadata of hörspiel
				do {
					try Self.export(hörspiel: hörspiel, type: collectionType, to: url)
				}
				catch {
					throw ExporterError.hörspielExportFailed(hörspiel: hörspiel, error: error)
				}
			}
			
			// Export metadata of collection as JSON
			do {
				var maskedObjectModel = MetadataObjectModel()
				switch collectionType.objectModelKeyPath {
					case let keyPath as WritableKeyPath<MetadataObjectModel, [MetadataObjectModel.Folge]?>:
						maskedObjectModel[keyPath: keyPath] = objectModel[keyPath: keyPath]
					case let keyPath as WritableKeyPath<MetadataObjectModel, [MetadataObjectModel.Hörspiel]?>:
						maskedObjectModel[keyPath: keyPath] = objectModel[keyPath: keyPath]
					default:
						fatalError("Unrecognized type for CollectionType.objectModelKeyPath")
				}
				
				let jsonURL = outputDir.appendingPathComponent("\(collectionType.fileName).json")
				stderr("> \(jsonURL.relativePath)")
				let jsonString = try maskedObjectModel.jsonString()
				try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
			}
			catch {
				throw ExporterError.collectionExportFailed(collectionType: collectionType, error: error)
			}
		}
	}
	
	
	private static func export(hörspiel: MetadataObjectModel.Hörspiel, type: CollectionType, to baseDirectory: URL) throws {
		var teileByDepth: [Int: [(teil: MetadataObjectModel.Teil, url: URL)]] = [:]
		
		func recursive(_ hörspiel: MetadataObjectModel.Hörspiel, to baseDirectory: URL, depth: Int = 0) throws {
			stderr("> \(baseDirectory.relativePath)")
			try Self.createDirectoryIfNeccessary(at: baseDirectory)
			
			func writeFile(filename: String, content: String) throws {
				let fileURL = baseDirectory.appendingPathComponent(filename)
				try content.write(to: fileURL, atomically: true, encoding: .utf8)
			}
			
			// Create metadata.json file
			let jsonString = try MetadataObjectModel.jsonString(of: hörspiel)
			try writeFile(filename: "metadata.json", content: jsonString)
			
			// Teile
			if let teile = hörspiel.teile {
				for teil in teile {
					let teilURL = baseDirectory.appendingPathComponent(String(teil.teilNummer))
					teileByDepth[depth, default: []].append((teil, teilURL))
					try recursive(teil, to: teilURL, depth: depth+1)
				}
			}
		}
		try recursive(hörspiel, to: baseDirectory)
		let ffmetadataBase = FFmetadata.create(forCollectionItem: hörspiel, type: type)
		
		// Create ffmetadata.txt file if links.ffmetadata exists
		func writeFile(ffmetadata: FFmetadata, at url: URL, for hörspiel: MetadataObjectModel.Hörspiel) throws {
			guard hörspiel.links?.ffmetadata != nil else {
				return
			}
			let content = ffmetadata.formattedContent
			let filename = "ffmetadata.txt"
			let fileURL = url.appendingPathComponent(filename)
			try content.write(to: fileURL, atomically: true, encoding: .utf8)
		}
		
		// Base
		try writeFile(ffmetadata: ffmetadataBase, at: baseDirectory, for: hörspiel)
		
		// Teile
		for teile in teileByDepth.values {
			let teileWithFFmetadata = teile.filter { $0.teil.links?.ffmetadata != nil }
			guard !teileWithFFmetadata.isEmpty else { continue }
			let teileFFmetadata = FFmetadata.create(forTeile: teileWithFFmetadata.map { $0.teil }, ofBase: ffmetadataBase)
			
			try zip(teileWithFFmetadata, teileFFmetadata).forEach { (teilTuple, ffmetadata) in
				try writeFile(ffmetadata: ffmetadata, at: teilTuple.url, for: teilTuple.teil)
			}
		}
	}
	
	private static func createDirectoryIfNeccessary(at url: URL) throws {
		do {
			try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
		}
		catch {
			throw ExporterError.directoryCreationFailed(url: url, error: error)
		}
	}
}


extension WebDataExporter {
	enum ExporterError: LocalizedError {
		case directoryCreationFailed(url: URL, error: Error)
		case missingTitel(hörspiel: MetadataObjectModel.Hörspiel)
		case hörspielExportFailed(hörspiel: MetadataObjectModel.Hörspiel, error: Error)
		case collectionExportFailed(collectionType: CollectionType, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .directoryCreationFailed(let url, let error):
					return "Couldn't create directory at \"\(url.relativePath)\": \(error.localizedDescription)"
				case .missingTitel(let hörspiel):
					var hörspielDump = String()
					dump(hörspiel, to: &hörspielDump, maxDepth: 2)
					return "Missing \"titel\" for hörspiel:\n\(hörspielDump)"
				case .hörspielExportFailed(let hörspiel, let error):
					return "Couldn't export metadata for hörspiel\(hörspiel.titel.map { " \"\($0)\"" } ?? "" ): \(error.localizedDescription)"
				case .collectionExportFailed(let collectionType, let error):
					return "Couldn't export metadata for \"\(collectionType)\": \(error.localizedDescription)"
			}
		}
	}
}

