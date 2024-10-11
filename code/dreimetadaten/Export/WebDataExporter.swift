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
	private let objectModel: MetadataObjectModel
	private let webDir: URL
	private let host: String
	
	
	init(db: Database, webDataURL: URL, webDir: URL) throws {
		self.objectModel = try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL)
		self.webDir = webDir
		guard let host = webDataURL.host else {
			throw FileError.invalidURL(string: webDataURL.absoluteString)
		}
		self.host = host
	}
	
	
	// MARK: - Export
	
	func export(to outputDir: URL) throws {
		try Self.createDirectoryIfNeccessary(at: outputDir)
		
		let objectModels = objectModel.separateByCollectionType(withDBInfo: true)
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
			throw FileError.directoryEnumerationFailed(url: outputDir)
		}
		for case let url as URL in enumerator {
			let attributes = try url.resourceValues(forKeys:[.isRegularFileKey])
			guard attributes.isRegularFile! else {
				continue
			}
			existingFilePaths.insert(outputDir.relativePath + "/" + url.relativePath)
		}
		
		let missingFiles = referencedFilePaths.subtracting(existingFilePaths).sorted()
		let extraFiles = existingFilePaths.subtracting(referencedFilePaths).sorted()
		missingFiles.forEach {
			stderr("Missing file: \($0)")
		}
		extraFiles.forEach {
			stderr("Extra file: \($0)")
		}
	}
	
	private static func export(hörspiel: MetadataObjectModel.Hörspiel, type: CollectionType, in outputDir: URL, localWebDir webDir: URL) throws -> [URL] {
		var referencedFiles = [URL]()
		
		func fileURL(for urlString: String) throws -> URL {
			// Replace base URL with local directory path
			guard let url = URL(string: urlString) else {
				throw FileError.invalidURL(string: urlString)
			}
			var fileURL = webDir
			url.pathComponents.dropFirst().forEach {
				fileURL = fileURL.appendingPathComponent($0)
			}
			// Check and remember file path
			guard fileURL.path.hasPrefix(outputDir.path) else {
				throw FileError.filePathOutsideOfOutputDirectory(file: fileURL, outputDir: outputDir)
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
			
			// Check cover files
			_ = try hörspiel.links?.cover.map(fileURL(for:))
			try hörspiel.links?.cover2?.forEach {
				_ = try fileURL(for: $0)
			}
			
			// Check rip log files
			try hörspiel.medien?.forEach {
				_ = try $0.ripLog.map(fileURL(for:))
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
	
	
	// MARK: - Index
	
	func createIndex(at outputDir: URL) throws {
		try Self.createDirectoryIfNeccessary(at: outputDir)
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		
		let hörspiele = CollectionType.allCases
			.map {
				objectModel[keyPath: $0.objectModelKeyPath] as! [MetadataObjectModel.Hörspiel]
			}
			.joined()
		
		func fileURLForLink(_ link: String) throws -> URL {
			guard let url = URL(string: link) else {
				throw FileError.invalidURL(string: link)
			}
			guard url.host == host else {
				throw IndexerError.mismatchedHostInURL(url: url.absoluteString, host: host)
			}
			let relativePath = String(url.relativePath.dropFirst())
			return URL(fileURLWithPath: relativePath, relativeTo: webDir)
		}
		
		func index(named name: String, _ mapClosure: (MetadataObjectModel.Hörspiel) throws -> String?) throws {
			let indexDir = outputDir.appendingPathComponent(name)
			try Self.createDirectoryIfNeccessary(at: indexDir)
			var keys = Set<String>()
			var dictionary = [String: String]()
			
			for hörspiel in hörspiele {
				guard let key = try mapClosure(hörspiel) else {
					continue
				}
				guard keys.insert(key).inserted else {
					throw IndexerError.keyAlreadyExists(key: key, index: name)
				}
				guard let jsonLink = hörspiel.links?.json else {
					throw IndexerError.noDestinationJSON(hörspiel: hörspiel)
				}
				let sourceFile = indexDir.appendingPathComponent(key)
				let destinationFile = try fileURLForLink(jsonLink)
				let destinationRelativePath = Command.relativePath(of: destinationFile, toDirectory: indexDir)
				try Self.createAndOverwriteSymlink(at: sourceFile, to: destinationRelativePath)
				
				dictionary[key] = jsonLink
			}
			
			let jsonFile = outputDir.appendingPathComponent("\(name).json")
			var jsonData = try jsonEncoder.encode(dictionary)
			jsonData.append("\n".data(using: .utf8)!)
			try jsonData.write(to: jsonFile)
		}
		
		try index(named: "dreimetadaten") { hörspiel in
			let id = hörspiel.ids?.dreimetadaten
			return id.map { String($0) }
		}
		try index(named: "apple-music", \.ids?.appleMusic)
		try index(named: "spotify", \.ids?.spotify)
		try index(named: "bookbeat", \.ids?.bookbeat)
		try index(named: "amazon-music", \.ids?.amazonMusic)
		try index(named: "amazon", \.ids?.amazon)
	}
	
	
	// MARK: - Filename and file system
	
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
	
	static func filenameSafe(string: String) -> String {
		var name = ""
		for character in string {
			if character.unicodeScalars.allSatisfy(Self.filenameAllowed.contains(_:)) {
				name.append(character)
			}
			else if let replacement = Self.filenameReplacements[character] {
				name.append(replacement)
			}
		}
		return name
	}
	
	static func dirname(for hörspiel: MetadataObjectModel.Hörspiel, nummerFormat: String? = nil) throws -> String {
		if let folge = hörspiel as? MetadataObjectModel.Folge {
			return String(format: nummerFormat ?? "", folge.nummer)
		}
		guard let titel = hörspiel.titel else {
			throw ExporterError.missingTitel(hörspiel: hörspiel)
		}
		return filenameSafe(string: titel)
	}
	
	
	private static func createDirectoryIfNeccessary(at url: URL) throws {
		do {
			try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
		}
		catch {
			throw FileError.directoryCreationFailed(url: url, error: error)
		}
	}
	
	private static func createAndOverwriteSymlink(at sourceURL: URL, to destinationRelativePath: String) throws {
		let manager = FileManager.default
		if manager.fileExists(atPath: sourceURL.path) {
			let values = try sourceURL.resourceValues(forKeys: [.isSymbolicLinkKey])
			guard values.isSymbolicLink! else {
				throw FileError.symlinkCreationOverwritesFile(url: sourceURL)
			}
			try manager.removeItem(at: sourceURL)
		}
		try manager.createSymbolicLink(atPath: sourceURL.path, withDestinationPath: destinationRelativePath)
	}
	
}


extension WebDataExporter {
	enum FileError: LocalizedError {
		case invalidURL(string: String)
		case filePathOutsideOfOutputDirectory(file: URL, outputDir: URL)
		case directoryCreationFailed(url: URL, error: Error)
		case directoryEnumerationFailed(url: URL)
		case symlinkCreationOverwritesFile(url: URL)
		
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
				case .symlinkCreationOverwritesFile(let url):
					return "Creating a symlink at \"\(url.path)\" would overwrite existing non-symlink file"
			}
		}
	}
	
	enum ExporterError: LocalizedError {
		case unsupportedTeileNesting
		case missingTitel(hörspiel: MetadataObjectModel.Hörspiel)
		case hörspielExportFailed(hörspiel: MetadataObjectModel.Hörspiel, error: Error)
		case collectionExportFailed(collectionType: CollectionType, error: Error)
		
		var errorDescription: String? {
			switch self {
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
	
	enum IndexerError: LocalizedError {
		case invalidAppleMusicURL(url: String)
		case invalidSpotifyURL(url: String)
		case invalidBookbeatURL(url: String)
		case mismatchedHostInURL(url: String, host: String)
		case keyAlreadyExists(key: String, index: String)
		case noDestinationJSON(hörspiel: MetadataObjectModel.Hörspiel)
		
		var errorDescription: String? {
			switch self {
				case .invalidAppleMusicURL(let url):
					return "Invalid Apple Music URL \"\(url)\""
				case .invalidSpotifyURL(let url):
					return "Invalid Spotify URL \"\(url)\""
				case .invalidBookbeatURL(let url):
					return "Invalid Bookbeat URL \"\(url)\""
				case .mismatchedHostInURL(let url, let host):
					return "Host in URL \"\(url)\" doesn't match specified host \"\(host)\""
				case .keyAlreadyExists(let key, let index):
					return "Key \"\(key)\" already exists in index \"\(index)\""
				case .noDestinationJSON(let hörspiel):
					return "No destination JSON file for hörspiel \(hörspiel.titel.map { " \"\($0)\"" } ?? "(nil titel)" )"
			}
		}
	}
}

