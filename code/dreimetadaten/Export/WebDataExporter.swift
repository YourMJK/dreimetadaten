//
//  WebDataExporter.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation
import CommandLineTool
import GRDB


struct WebDataExporter {
	let db: Database
	let webDataURL: URL
	let webDir: URL
	
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
		let objectModels = try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL).separateByCollectionType()
		var referencedFilePaths = Set<String>()
		
		for (objectModel, collectionType) in objectModels {
			guard let collection = objectModel[keyPath: collectionType.objectModelKeyPath] as? [MetadataObjectModel.Hörspiel] else {
				continue
			}
			
			for hörspiel in collection {
				// Export metadata of hörspiel
				do {
					let referencedFiles = try Self.export(hörspiel: hörspiel, type: collectionType, in: outputDir, localWebDir: webDir)
					referencedFilePaths.formUnion(referencedFiles.map(\.relativePath))
				}
				catch {
					throw ExporterError.hörspielExportFailed(hörspiel: hörspiel, error: error)
				}
			}
			
			// Export metadata of collection as JSON
			do {
				let jsonURL = outputDir.appendingPathComponent("\(collectionType.fileName).json")
				referencedFilePaths.insert(jsonURL.relativePath)
				let jsonString = try objectModel.jsonString()
				try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
			}
			catch {
				throw ExporterError.collectionExportFailed(collectionType: collectionType, error: error)
			}
		}
		
		// Check referenced files and existing files
		var existingFilePaths = Set<String>()
		guard let enumerator = FileManager.default.enumerator(at: outputDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .producesRelativePathURLs]) else {
			throw ExporterError.directoryEnumerationFailed(url: outputDir)
		}
		for case let url as URL in enumerator {
			let attributes = try url.resourceValues(forKeys:[.isRegularFileKey])
			guard attributes.isRegularFile! else {
				continue
			}
			existingFilePaths.append(outputDir.relativePath + "/" + url.relativePath)
		}
		
		let missingFiles = referencedFilePaths.subtracting(existingFilePaths)
		let extraFiles = existingFilePaths.subtracting(referencedFilePaths)
		missingFiles.forEach {
			stderr("Missing file: \($0)")
		}
		extraFiles.forEach {
			stderr("Extra file: \($0)")
		}
	}
	
	static func dirname(for hörspiel: MetadataObjectModel.Hörspiel, nummerFormat: String? = nil) throws -> String {
		if let folge = hörspiel as? MetadataObjectModel.Folge, folge.nummer >= 0 {
			return String(format: nummerFormat ?? "", folge.nummer)
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
	}
	
	
	private static func export(hörspiel: MetadataObjectModel.Hörspiel, type: CollectionType, in outputDir: URL, localWebDir webDir: URL) throws -> [URL] {
		var referencedFiles = [URL]()
		
		func fileURL(for urlString: String) throws -> URL {
			// Replace base URL with local directory path
			guard let url = URL(string: urlString) else {
				throw ExporterError.invalidURL(string: urlString)
			}
			var fileURL = webDir
			url.pathComponents.dropFirst().forEach {
				fileURL = fileURL.appendingPathComponent($0)
			}
			// Check and remember file path
			guard fileURL.path.hasPrefix(outputDir.path) else {
				throw ExporterError.filePathOutsideOfOutputDirectory(file: fileURL, outputDir: outputDir)
			}
			referencedFiles.append(fileURL)
			// Create intermediate directories for file
			let dirURL = fileURL.deletingLastPathComponent()
			try createDirectoryIfNeccessary(at: dirURL)
			return fileURL
		}
		
		func recursive(_ hörspiel: MetadataObjectModel.Hörspiel) throws {
			// Create metadata.json file
			if let jsonURLString = hörspiel.links?.json {
				let jsonURL = try fileURL(for: jsonURLString)
				let jsonString = try MetadataObjectModel.jsonString(of: hörspiel)
				try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
			}
			
			// Check cover file
			_ = try hörspiel.links?.cover.map(fileURL(for:))
			
			// Check XLD log file
			try hörspiel.medien?.forEach {
				_ = try $0.xld_log.map(fileURL(for:))
			}
			
			// Teile
			try hörspiel.teile?.forEach(recursive)
		}
		try recursive(hörspiel)
		let ffmetadataBase = FFmetadata.create(forCollectionItem: hörspiel, type: type)
		
		// Create ffmetadata.txt file if links.ffmetadata exists
		func write(ffmetadata: FFmetadata, for hörspiel: MetadataObjectModel.Hörspiel) throws {
			guard let urlString = hörspiel.links?.ffmetadata else { return }
			let url = try fileURL(for: urlString)
			try ffmetadata.formattedContent.write(to: url, atomically: true, encoding: .utf8)
		}
		
		// Base
		try write(ffmetadata: ffmetadataBase, for: hörspiel)
		
		// Teile
		if let teile = hörspiel.teile {
			let hasNestedTeile = teile.contains { !($0.teile ?? []).isEmpty }
			guard !hasNestedTeile else {
				throw ExporterError.unsupportedTeileNesting
			}
			let teileWithFFmetadata = teile.filter { $0.links?.ffmetadata != nil }
			let teileFFmetadata = FFmetadata.create(forTeile: teileWithFFmetadata, ofBase: ffmetadataBase)
			try zip(teileWithFFmetadata, teileFFmetadata).forEach { (teil, ffmetadata) in
				try write(ffmetadata: ffmetadata, for: teil)
			}
		}
		
		return referencedFiles
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
		case invalidURL(string: String)
		case filePathOutsideOfOutputDirectory(file: URL, outputDir: URL)
		case directoryCreationFailed(url: URL, error: Error)
		case directoryEnumerationFailed(url: URL)
		case unsupportedTeileNesting
		case missingTitel(hörspiel: MetadataObjectModel.Hörspiel)
		case hörspielExportFailed(hörspiel: MetadataObjectModel.Hörspiel, error: Error)
		case collectionExportFailed(collectionType: CollectionType, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
				case .filePathOutsideOfOutputDirectory(let file, let outputDir):
					return "File path \"\(file.path)\" derived from object model points outside of specified output directory \"\(outputDir.path)\""
				case .directoryCreationFailed(let url, let error):
					return "Couldn't create directory at \"\(url.relativePath)\": \(error.localizedDescription)"
				case .directoryEnumerationFailed(let url):
					return "Couldn't enumerate contents of directory \"\(url.relativePath)\""
				case .unsupportedTeileNesting:
					return "Unsupported nesting of teile (maximum allowed depth: 1)"
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

