//
//  MetadataCollector.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 13.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


class MetadataCollector {
	
	enum InputType: String {
		case csv = "csv"
		case ffmetadata = "ffmetadata"
		case dataDir = "dataDir"
		case mbDiscIDList = "mbDiscIDList"
	}
	enum CollectionType: String {
		case serie = "serie"
		case die_dr3i = "die_dr3i"
	}
	enum OutputType: String {
		case json = "json"
		case csv = "csv"
	}
	
	
	var metadata: Metadata
	
	
	convenience init(withPreviousFile previousFile: URL?) {
		self.init()
		if let previousFile = previousFile {
			self.metadata = Self.parseJSON(url: previousFile)
		}
	}
	init() {
		self.metadata = Metadata()
	}
	
	
	
	// MARK: Input & output final metadata archive 
	
	static func parseJSON(url: URL) -> Metadata {
		do {
			let jsonData = try Data(contentsOf: url)
			return try parseJSON(data: jsonData)
		}
		catch {
			exit(error: "Couldn't parse JSON file \"\(url.path)\":  \(error.localizedDescription)")
		}
	}
	static func parseJSON(data jsonData: Data) throws -> Metadata {
		let jsonDecoder = JSONDecoder()
		let metadata = try jsonDecoder.decode(Metadata.self, from: jsonData)
		return metadata
	}
	
	
	func output(outputType: OutputType) -> String {
		switch outputType {
			case .csv:
				exit(error: "Not implemented")
			
			case .json:
				do {
					let jsonEncoder = JSONEncoder()
					jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys /*, .withoutEscapingSlashes*/]
					jsonEncoder.keyEncodingStrategy = .custom({ Metadata.OrderedCodingKey($0.last!) })
					let jsonData = try jsonEncoder.encode(metadata)
					guard var jsonString = String(data: jsonData, encoding: .utf8) else {
						exit(error: "Invalid UTF8 format in output JSON")
					}
					
					// Replace prefixed ordered keys with normal keys again
					for key in Metadata.OrderedCodingKey.ordering {
						let prefixedKey = Metadata.OrderedCodingKey.prefixedKeyString(keyString: key)
						let target = "\"\(prefixedKey)\""
						let replacement = "\"\(key)\""
						jsonString = jsonString.replacingOccurrences(of: target, with: replacement)  // despite copy overhead 10x faster than range(of:) + mutating replaceSubrange()
					}
					jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
					
					return jsonString
				}
				catch {
					exit(error: "Couldn't generate output JSON: \(error)")
				}
		}
	}
	
	
	func applyCorrections() {
		/*
		metadata.serie.filter({ $0.nummer <= 60 && $0.nummer != 29 }).forEach { folge in
			folge.hörspielskriptautor = "H. G. Francis"
		}
		
		let autoren = [
			"Robert Arthur",
			"William Arden",
			"M. V. Carey",
			"William Arden",
			"Robert Arthur",
			"Robert Arthur",
			"Nick West",
			"Robert Arthur",
			"William Arden",
			"Robert Arthur",
			"Robert Arthur",
			"Robert Arthur",
			"William Arden",
			"M. V. Carey",
			"Nick West",
			"M. V. Carey",
			"William Arden",
			"Robert Arthur",
			"William Arden",
			"M. V. Carey",
			"William Arden",
			"Robert Arthur",
			"William Arden",
			"Robert Arthur",
			"M. V. Carey",
			"M. V. Carey",
			"M. V. Carey",
			"William Arden",
			nil,
			"William Arden",
			"M. V. Carey",
			"M. V. Carey",
			"M. V. Carey",
			"William Arden",
			"M. V. Carey",
			"Marc Brandel",
			"M. V. Carey",
			"M. V. Carey",
			"Marc Brandel",
			"William Arden",
			"Rose Estes",
			"Megan Stine",
			"M. V. Carey",
			"Marc Brandel",
			"William Arden",
			"M. V. Carey",
			"Megan & H. William Stine",
			"G. H. Stone"
		]
		for (i, autor) in autoren.enumerated() {
			metadata.serie[i].autor = autor
		}
		*/
	}
	
	
	
	// MARK: Parsing FFMetadata & CSV
	
	func addMetadata(fromURLs inputURLs: [URL], withType inputType: InputType, toCollection collectionType: CollectionType, overwrite: Bool) {
		func createEmptyIfNil<T>(_ collection: inout [T]?) {
			if collection == nil {
				collection = []
			}
		}
		
		switch collectionType {
			case .serie:
				createEmptyIfNil(&self.metadata.serie)
			case .die_dr3i:
				createEmptyIfNil(&self.metadata.die_dr3i)
		}
		
		createEmptyIfNil(&self.metadata.die_dr3i)
		
		for url in inputURLs {
			stderr("> \(url.path)")
			do {
				switch inputType {
					case .ffmetadata:
						let content = try String(contentsOf: url).split(separator: "\n")
						do {
							try handleFFMetadata(lines: content, collectionType: collectionType, overwrite: overwrite)
						}
						catch let error as FFMetadataParseError {
							stderr("Error parsing ffmetadata file \"\(url.path)\":  \(error.description)")
						}
					
					case .csv:
						let content = try String(contentsOf: url).split(separator: "\n")
						for (i, line) in content.dropFirst().enumerated() {
							let lineNumber = i+2
							do {
								try handleCSV(line: line, collectionType: collectionType, overwrite: overwrite)
							}
							catch let error as CSVParseError {
								stderr("Error parsing csv file \"\(url.path)\" at line \(lineNumber):  \(error.description)")
							}
						}
					
					case .dataDir:
						do {
							try handleDataDir(directory: url, collectionType: collectionType, overwrite: overwrite)
						}
						catch let error as FFMetadataParseError {
							stderr("Error parsing data directory \"\(url.path)\":  \(error.description)")
						}
					
					case .mbDiscIDList:
						let content = try String(contentsOf: url).split(separator: "\n")
						for (i, line) in content.enumerated() {
							let lineNumber = i+1
							do {
								try handleMBDiscIDList(line: line, collectionType: collectionType, overwrite: overwrite)
							}
							catch let error as MBDiscIDListParseError {
								stderr("Error parsing MusicBrainz discID list file \"\(url.path)\" at line \(lineNumber):  \(error.description)")
							}
						}
				}
			}
			catch {
				stderr("Error reading file \"\(url.path)\":  \(error.localizedDescription)")
			}
		}
	}
	
	
	enum FFMetadataParseError: Error, CustomStringConvertible {
		case missingRequiredTag(tag: String, range: Range<Int>?)
		case albumTagParseError
		case invalidTagFormat(tag: String, line: Int)
		
		var description: String {
			switch self {
				case .missingRequiredTag(let tag, let range):
					if let range = range {
						return "Missing required tag \"\(tag)\" in range \(range.lowerBound+1):\(range.upperBound)"
					}
					return "Missing required tag \"\(tag)\""
				case .albumTagParseError: return "Couldn't parse title"
				case .invalidTagFormat(let tag, let line): return "Invalid format for tag \"\(tag)\" at line \(line)"
			}
		}
	}
	
	func handleFFMetadata<T: StringProtocol>(lines: [T], collectionType: CollectionType, overwrite: Bool) throws {
		func findTagValue(tag: String, required: Bool = false, inRange range: Range<Int>? = nil) throws -> (tag: String, value: T.SubSequence, line: Int)? {
			guard let lineIndex = lines[range ?? lines.indices].firstIndex(where: { $0.hasPrefix(tag+"=") }) else {
				if required {
					throw FFMetadataParseError.missingRequiredTag(tag: tag, range: range)
				}
				else {
					return nil
				}
			}
			
			let line = lines[lineIndex]
			let seperatorIndex = line.firstIndex(of: "=")!
			let value = line[line.index(after: seperatorIndex)...]
			
			return (tag: tag, value: value, line: lineIndex)
		}
		
		// Parse "nummer" and "titel" from album tag 
		let (_, albumValue, _) = try findTagValue(tag: "album", required: true)!
		guard let nummerIdentifierRange = albumValue.range(of: "Nr. "), let titelIdentifierRange = albumValue.range(of: " – ") else {
			throw FFMetadataParseError.albumTagParseError
		}
		let folgenTitel = String(albumValue[titelIdentifierRange.upperBound...])
		
		let nummerStringStart = nummerIdentifierRange.upperBound
		let nummerStringEnd = titelIdentifierRange.lowerBound
		let nummerString = albumValue[nummerStringStart..<nummerStringEnd]
		guard let nummer = UInt(nummerString) else {
			throw FFMetadataParseError.albumTagParseError
		}
		
		// Parse track number to check if it's a "Teil"
		var teilNummer: UInt?
		var buchstabe: String?
		var teilTitel: String?
		if let track = try findTagValue(tag: "track") {
			let trackSeperator: Character = "/"
			guard let trackSeperatorIndex = track.value.firstIndex(of: trackSeperator) else {
				throw FFMetadataParseError.invalidTagFormat(tag: track.tag, line: track.line)
			}
			let trackValueComponents = track.value.split(separator: trackSeperator)
			guard trackValueComponents.count == 2, let trackIndex = UInt(trackValueComponents[0]), let trackTotal = UInt(trackValueComponents[1]), trackIndex > 0, trackIndex <= trackTotal else {
				throw FFMetadataParseError.invalidTagFormat(tag: track.tag, line: track.line)
			}
			
			teilNummer = trackIndex
			buchstabe = String(Character(UnicodeScalar(("A" as Character).asciiValue! + UInt8(trackIndex-1))))
			if let titleValue = try findTagValue(tag: "title")?.value {
				teilTitel = String(titleValue)
			}
		}
		
		// Parse chapter data
		var kapitels = [Kapitel]()
		let chapterIndices = lines.enumerated().filter({ $0.element == "[CHAPTER]" }).map({ $0.offset })
		let chapterRanges = zip(chapterIndices, chapterIndices.dropFirst() + [lines.endIndex]).map({ lines.index(after: $0.0) ..< $0.1 })
		for chapterRange in chapterRanges {
			let titleValue = try findTagValue(tag: "title", required: true, inRange: chapterRange)!.value
			let timebase = try findTagValue(tag: "TIMEBASE", required: true, inRange: chapterRange)!
			let start = try findTagValue(tag: "START", required: true, inRange: chapterRange)!
			let end = try findTagValue(tag: "END", required: true, inRange: chapterRange)!
			
			guard let timebaseDenomIdentifierIndex = timebase.value.firstIndex(of: "/"), let timebaseDenom = UInt(timebase.value.suffix(from: timebase.value.index(after: timebaseDenomIdentifierIndex))) else {
				throw FFMetadataParseError.invalidTagFormat(tag: timebase.tag, line: timebase.line)
			}
			guard let startValue = Int(start.value) else {
				throw FFMetadataParseError.invalidTagFormat(tag: start.tag, line: start.line)
			}
			guard let endValue = Int(end.value) else {
				throw FFMetadataParseError.invalidTagFormat(tag: end.tag, line: end.line)
			}
			func timestampInMilliseconds(_ value: Int) -> Int {
				return Int((Double(value) * 1000 / Double(timebaseDenom)).rounded())
			}
			let startMilliseconds = timestampInMilliseconds(startValue)
			let endMilliseconds = timestampInMilliseconds(endValue)
			
			let kapitel = Kapitel(titel: String(titleValue))
			kapitel.start = startMilliseconds
			kapitel.end = endMilliseconds
			kapitels.append(kapitel)
		}
		
		
		func update<T: Equatable>(_ oldValue: inout T?, to newValue: T?, description: String) {
			if !overwrite, let oldValue = oldValue {  // no-overwrite and value is non-nil
				if newValue != oldValue {
					stderr("Warning (Folge \(nummer)): New value for \"\(description)\" of \"\(newValue != nil ? String(describing: newValue!) : "(nil)"))\" differs from current value \"\(oldValue)\", but the overwrite option was not specified. New value is ignored.")
				}
				return
			}
			oldValue = newValue
		}
		func update(_ oldValue: inout String?, toValueOfTag tag: String, description: String) throws {
			if let (_, value, _) = try findTagValue(tag: tag) {
				update(&oldValue, to: String(value), description: description)
			}
		}
		
		
		switch collectionType {
			case .serie, .die_dr3i:
				// Find or create folge/teil based on nummer
				let folge = (collectionType == .serie ? findOrCreateFolge(nummer: nummer, in: &metadata.serie!) : findOrCreateFolge(nummer: nummer, in: &metadata.die_dr3i!))
				
				if let teilNummer = teilNummer {
					let teil = findOrCreateTeil(teilNummer: teilNummer, in: folge)
					
					update(&teil.buchstabe, to: buchstabe, description: "buchstabe")
					update(&teil.titel, to: teilTitel, description: "titel")
					update(&teil.kapitel, to: kapitels, description: "kapitel")
					try update(&teil.autor, toValueOfTag: "composer", description: "autor")
					try update(&teil.hörspielskriptautor, toValueOfTag: "album_artist", description: "hörspielskriptautor")
					update(&folge.titel, to: folgenTitel, description: "titel")
				}
				else {
					update(&folge.titel, to: folgenTitel, description: "titel")
					update(&folge.kapitel, to: kapitels, description: "kapitel")
					try update(&folge.autor, toValueOfTag: "composer", description: "autor")
					try update(&folge.hörspielskriptautor, toValueOfTag: "album_artist", description: "hörspielskriptautor")
				}
		}
	}
	
	
	enum CSVParseError: Error, CustomStringConvertible {
		case invalidCSVDataSet
		case invalidCSVComponentFormat(component: Int, info: String?)
		
		var description: String {
			switch self {
				case .invalidCSVDataSet: return "Invalid CSV data set"
				case .invalidCSVComponentFormat(let component, let info): return "Invalid format for CSV component \(component)" + (info != nil ? " (\(info!))" : "")
			}
		}
	}
	
	func handleCSV<T: StringProtocol>(line: T, collectionType: CollectionType, overwrite: Bool) throws {
		guard collectionType == .serie else { return }
		
		guard let startIdentifierIndex = line.firstIndex(of: "["), let endIndex = line.lastIndex(of: "]") else {
			throw CSVParseError.invalidCSVDataSet
		}
		let startIndex = line.index(after: startIdentifierIndex)
		let dataSetString = line[startIndex..<endIndex]
		
		// Parse CSV lines into components
		var components = [String]()
		var componentStartIndex = startIndex
		var currentIndex = startIndex
		func current() -> Character {
			return line[currentIndex]
		}
		func moveNext() {
			currentIndex = line.index(after: currentIndex)
		}
		@discardableResult func moveWhile(_ condition: (Character) -> Bool) throws -> Bool {
			repeat {
				if currentIndex >= endIndex {
					return false
				}
				moveNext()
			}
			while condition(current())
			return true
		}
		@discardableResult func moveTo(next character: Character) throws -> Bool {
			return try moveWhile({ $0 != character })
		}
		while currentIndex < endIndex {
			for quote in (["'", "\""] as [Character]) {
				if current() == quote {
					if !(try moveTo(next: quote)) {
						throw CSVParseError.invalidCSVDataSet
					}
					break;
				}
			}
			try moveTo(next: ";")
			components.append(String(line[componentStartIndex..<currentIndex]))
			try moveWhile { $0.isWhitespace }
			componentStartIndex = currentIndex
		}
		
		// Parse components
		guard components.count == 6 else {
			throw CSVParseError.invalidCSVDataSet
		}
		
		func convertString(component: Int) throws -> String {
			let rawString = components[component]
			guard rawString.count >= 2 else {
				throw CSVParseError.invalidCSVComponentFormat(component: component, info: nil)
			}
			let result = rawString.dropFirst().dropLast()
				.replacingOccurrences(of: ";", with: ",")
				.replacingOccurrences(of: "\\n", with: "\n")
				.trimmingCharacters(in: .whitespacesAndNewlines) 
			return result
		}
		
		guard let nummer = UInt(components[0]) else {
			throw CSVParseError.invalidCSVComponentFormat(component: 0, info: nil)
		}
		let folgenTitel = try convertString(component: 1)
		let beschreibung = try convertString(component: 2)
		//let folgenTitelLang = try convertString(component: 3)
		let datumValue = try convertString(component: 4)
		guard let datumIdentifierRange = datumValue.range(of: ": ") else {
			throw CSVParseError.invalidCSVComponentFormat(component: 4, info: "indentifier not found \"\(datumValue)\"")
		}
		let datumDMY = datumValue[datumIdentifierRange.upperBound...].split(separator: ".")
		guard datumDMY.count == 3, datumDMY[0].count == 2, datumDMY[1].count == 2, datumDMY[2].count == 4 else {
			throw CSVParseError.invalidCSVComponentFormat(component: 4, info: "invalid date format \"\(datumDMY)\"")
		}
		let veröffentlichungsdatum = datumDMY.reversed().joined(separator: "-")
		let sprecher: [[String]] = try convertString(component: 5).components(separatedBy: "\n").map { (sprecherRolleString) in
			let seperator = sprecherRolleString.contains(" - ") ? " - " : ": "
			let sprecherRolleComponents = sprecherRolleString.components(separatedBy: seperator)
			guard sprecherRolleComponents.count == 2 else {
				throw CSVParseError.invalidCSVComponentFormat(component: 5, info: "\"\(sprecherRolleComponents)\"")
			}
			return sprecherRolleComponents.map { $0.trimmingCharacters(in: .whitespaces)  }
		}
		
		
		func update<T: Equatable>(_ oldValue: inout T?, to newValue: T?, description: String) {
			if !overwrite, let oldValue = oldValue {  // no-overwrite and value is non-nil
				if newValue != oldValue {
					stderr("Warning (Folge \(nummer)): New value for \"\(description)\" of \"\(newValue != nil ? String(describing: newValue!) : "(nil)")\" differs from current value \"\(oldValue)\", but the overwrite option was not specified. New value is ignored.")
				}
				return
			}
			oldValue = newValue
		}
		
		// Find or create folge/teil based on nummer
		let folge = findOrCreateFolge(nummer: nummer, in: &metadata.serie!)
		
		update(&folge.titel, to: folgenTitel, description: "titel")
		update(&folge.beschreibung, to: beschreibung, description: "beschreibung")
		update(&folge.veröffentlichungsdatum, to: veröffentlichungsdatum, description: "veröffentlichungsdatum")
		update(&folge.sprecher, to: sprecher, description: "sprecher")
	}
	
	
	enum DataDirParseError: Error, CustomStringConvertible {
		case noSuchDirectory
		case invalidDirectoryName
		case invalidFilePath(path: String)
		case invalidURLFileFormat(path: String)
		
		var description: String {
			switch self {
				case .noSuchDirectory: return "No such directory"
				case .invalidDirectoryName: return "Directory name is not a valid number"
				case .invalidFilePath(let path): return "Couldn't find base component \"web\" in path \"\(path)\""
				case .invalidURLFileFormat(let path): return "Couldn't parse URL in file \"\(path)\""
			}
		}
	}
	
	func handleDataDir(directory: URL, collectionType: CollectionType, overwrite: Bool) throws {
		func directoryExists(_ url: URL) -> Bool {
			var isDirectory: ObjCBool = false
			return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
		}
		guard directoryExists(directory) else {
			throw DataDirParseError.noSuchDirectory
		}
		
		guard let nummer = UInt(directory.lastPathComponent) else {
			throw DataDirParseError.invalidDirectoryName
		}
		
		
		let höreinheit: Höreinheit = {
			switch collectionType {
				case .serie: return findOrCreateFolge(nummer: nummer, in: &metadata.serie!)
				case .die_dr3i: return findOrCreateFolge(nummer: nummer, in: &metadata.die_dr3i!) 
			}
		}()
		
		func parseDirectoryContents(url directoryURL: URL) throws -> Links {
			let links = Links()
			for directoryContentName in try FileManager.default.contentsOfDirectory(atPath: directoryURL.path) {
				let directoryContentURL = directoryURL.appendingPathComponent(directoryContentName)
				
				func absoluteWebsiteURL() throws -> String {
					guard let rootIndex = directoryContentURL.pathComponents.firstIndex(of: "web") else {
						throw DataDirParseError.invalidFilePath(path: directoryContentURL.path)
					}
					let relativePathStartIndex = directoryContentURL.pathComponents.index(after: rootIndex)
					let relativePath = directoryContentURL.pathComponents[relativePathStartIndex...].joined(separator: "/")
					return "http://dreimetadaten.de/\(relativePath)"
				}
				func parseURLFromURLFile() throws -> String {
					let prefix = "URL="
					let lines = try String(contentsOf: directoryContentURL, encoding: .utf8).split(separator: "\n")
					guard let lineIndex = lines.firstIndex(where: { $0.hasPrefix(prefix) }) else {
						throw DataDirParseError.invalidURLFileFormat(path: directoryContentURL.path)
					}
					return String(lines[lineIndex].dropFirst(prefix.count).trimmingCharacters(in: .whitespaces))
				}
				
				switch directoryContentName {
					case "metadata.json":
						links.json = try absoluteWebsiteURL()
					
					case "ffmetadata.txt":
						links.ffmetadata = try absoluteWebsiteURL()
					
					case "rip_log.txt":
						links.xld_log = try absoluteWebsiteURL()
					
					case _ where directoryContentName.hasPrefix("cover."):
						links.cover = try absoluteWebsiteURL()
					
					case "cover_itunes.url":
						links.cover_itunes = try parseURLFromURLFile()
					
					case "cover_kosmos.url":
						links.cover_kosmos = try parseURLFromURLFile()
					
					default:
						if let teilNummer = UInt(directoryContentName), directoryExists(directoryContentURL) {
							let teilLinks = try parseDirectoryContents(url: directoryContentURL)
							let teil = findOrCreateTeil(teilNummer: teilNummer, in: höreinheit)
							teil.links = teilLinks
						}
					}
				}
			return links
		}
		
		let links = try parseDirectoryContents(url: directory)
		höreinheit.links = links
	}
	
	
	enum MBDiscIDListParseError: Error, CustomStringConvertible {
		case invalidURL(urlString: String)
		case requestFailed(errorMsg: String)
		case jsonParsingFailed(errorMsg: String)
		case invalidTitleFormat
		case unexpectedTrackSequence(expected: Int, actual: Int)
		case trackAndOffsetCountDiffer(tracks: UInt, offsets: UInt)
		case zeroTracks
		case negativeTimestamp(timestamp: Int)
		
		var description: String {
			switch self {
				case .invalidURL(let urlString): return "Invalid URL:  \(urlString)"
				case .requestFailed(let errorMsg): return "Request to MusicBrainz failed:  \(errorMsg)"
				case .jsonParsingFailed(let errorMsg): return "Parsing MusicBrainz JSON response failed:  \(errorMsg)"
				case .invalidTitleFormat: return "Title value has an unexpected format; \"nummer\" couldn't be parsed"
				case .unexpectedTrackSequence(let expected, let actual): return "Expected next track position to be \(expected) but was \(actual)"
				case .trackAndOffsetCountDiffer(let tracks, let offsets): return "Number of tracks (\(tracks) and number of offsets (\(offsets) don't match"
				case .zeroTracks: return "No tracks were found"
				case .negativeTimestamp(let timestamp): return "Negative timestamp (\(timestamp) after conversion"
			}
		}
	}
	
	func handleMBDiscIDList<T: StringProtocol>(line: T, collectionType: CollectionType, overwrite: Bool) throws {
		guard collectionType == .serie else { return }
		
		func synchronousJSONRequest(to urlString: String) throws -> Any {
			guard let url = URL(string: urlString) else {
				throw MBDiscIDListParseError.invalidURL(urlString: urlString)
			}
			var result: Any?
			var errorToThrow: Error?
			let semphore = DispatchSemaphore(value: 0)
			let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
				defer {
					semphore.signal()
				}
				if let error = error {
					errorToThrow = MBDiscIDListParseError.requestFailed(errorMsg: error.localizedDescription)
					return
				}
				guard let data = data else {
					errorToThrow = MBDiscIDListParseError.requestFailed(errorMsg: "No data")
					return
				}
				let httpResponse = response as! HTTPURLResponse
				guard httpResponse.statusCode == 200 else {
					errorToThrow = MBDiscIDListParseError.requestFailed(errorMsg: "\(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "(nil)")")
					return
				}
				
				do {
					result = try JSONSerialization.jsonObject(with: data, options: [])
				}
				catch(let parseError) {
					errorToThrow = MBDiscIDListParseError.jsonParsingFailed(errorMsg: parseError.localizedDescription)
					return
				}
			}
			task.resume()
			semphore.wait()
			usleep(1_000_000)  // Wait 1000ms, to keep MusicBrainz' servers happy (https://wiki.musicbrainz.org/MusicBrainz_API/Rate_Limiting)
			
			if let error = errorToThrow {
				throw error
			}
			return result!
		}
		
		// Get disc data
		let discID = line.trimmingCharacters(in: .whitespaces)
		guard let disc = try synchronousJSONRequest(to: "https://musicbrainz.org/ws/2/discid/\(discID)?fmt=json") as? [String: Any] else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Disc top level not a dictionary")
		}
		guard let discRelease = (disc["releases"] as? [[String: Any]])?.first else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Release object not found")
		}
		guard let sectorOffsets = disc["offsets"] as? [Int], let sectorCount = disc["sectors"] as? Int else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Sector data not found")
		}
		guard let releaseID = discRelease["id"] as? String else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Release ID not found")
		}
		
		// Get release data
		guard let release = try synchronousJSONRequest(to: "https://musicbrainz.org/ws/2/release/\(releaseID)?inc=recordings&fmt=json") as? [String: Any] else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Release top level not a dictionary")
		}
		guard let medium = (release["media"] as? [[String: Any]])?.first else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Medium not found")
		}
		guard let tracks = medium["tracks"] as? [[String: Any]] else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Tracks not found")
		}
		guard let title = release["title"] as? String else {
			throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Title not found")
		}
		
		// Parse nummer
		guard let nummerEndIndex = title.firstIndex(of: ":"), let nummerIdentifierIndex = title[..<nummerEndIndex].lastIndex(of: " ") else {
			throw MBDiscIDListParseError.invalidTitleFormat
		}
		let nummerStartIndex = title.index(after: nummerIdentifierIndex)
		let nummerString = title[nummerStartIndex..<nummerEndIndex]
		guard let nummer = UInt(nummerString) else {
			throw MBDiscIDListParseError.invalidTitleFormat
		}
		
		// Generate chapters
		var previousPosition = 0
		let kapitels: [Kapitel] = try tracks.map { track in
			guard let position = track["position"] as? Int else {
				throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Track position not found")
			}
			let expectedPosition = previousPosition + 1
			guard position == expectedPosition else {
				throw MBDiscIDListParseError.unexpectedTrackSequence(expected: expectedPosition, actual: position)
			}
			previousPosition = expectedPosition
			
			guard let trackTitle = (track["title"] as? String)?.trimmingCharacters(in: .whitespaces) else {
				throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Track title not found")
			}
			return Kapitel(titel: trackTitle)
		}
		
		guard kapitels.count == sectorOffsets.count else {
			throw MBDiscIDListParseError.trackAndOffsetCountDiffer(tracks: UInt(kapitels.count), offsets: UInt(sectorOffsets.count))
		}
		guard kapitels.count > 0 else {
			throw MBDiscIDListParseError.zeroTracks
		}
		
		let startOffset = sectorOffsets.first!
		let timestamps: [Int] = try (sectorOffsets + [sectorCount]).map { 
			let sectors = $0 - startOffset
			let samples = sectors * 2352 / 4  // sectorSize=2352B ; sampleSize=2*16bit=4B
			let milliseconds = Int((Double(samples) / 44.1).rounded())  // sampleRate=44.1kHz
			guard milliseconds >= 0 else {
				throw MBDiscIDListParseError.negativeTimestamp(timestamp: milliseconds)
			}
			return Int(milliseconds)
		}
		for (i, (start, end)) in zip(timestamps.dropLast(), timestamps.dropFirst()).enumerated() {
			let kapitel = kapitels[i]
			kapitel.start = start
			kapitel.end = end
		}
		
		// Find or create folge based on nummer & update chapters
		let folge = findOrCreateFolge(nummer: nummer, in: &metadata.serie!)
		if folge.kapitel == nil {
			folge.kapitel = kapitels
		}
	}
	
	
	
	func findOrCreateFolge(nummer: UInt, in collection: inout [Folge]) -> Folge {
		if let folge = collection.first(where: { $0.nummer == nummer }) {
			return folge
		}
		else {
			let folge = Folge(nummer: nummer)
			let indexOfSuccessor = collection.firstIndex { $0.nummer > nummer }
			collection.insert(folge, at: indexOfSuccessor ?? collection.endIndex)
			return folge
		}
	}
	func findOrCreateTeil(teilNummer: UInt, in höreinheit: Höreinheit) -> Teil {
		if höreinheit.teile == nil {
			höreinheit.teile = [Teil]()
		}
		else {
			if let teil = höreinheit.teile!.first(where: { $0.teilNummer == teilNummer }) {
				return teil
			}
		}
		
		let teil = Teil(teilNummer: teilNummer)
		let indexOfSuccessor = höreinheit.teile!.firstIndex { $0.teilNummer > teilNummer }
		höreinheit.teile!.insert(teil, at: indexOfSuccessor ?? höreinheit.teile!.endIndex)
		return teil
	}
	
}

