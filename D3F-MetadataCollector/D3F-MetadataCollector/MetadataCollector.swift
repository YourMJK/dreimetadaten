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
	}
	enum OutputType: String {
		case json = "json"
		case csv = "csv"
	}
	
	
	var metadata: Metadata
	
	
	init(withPreviousFile previousFile: URL?) {
		if let previousFile = previousFile {
			self.metadata = Self.parsePreviousJSON(url: previousFile)
		}
		else {
			self.metadata = Metadata(serie: [])
		}
	}
	init(metadata: Metadata) {
		self.metadata = metadata
	}
	
	
	
	// MARK: Input & output final metadata archive 
	
	static func parsePreviousJSON(url: URL) -> Metadata {
		do {
			let jsonData = try Data(contentsOf: url)
			let jsonDecoder = JSONDecoder()
			let metadata = try jsonDecoder.decode(Metadata.self, from: jsonData)
			return metadata
		}
		catch {
			exit(error: "Couldn't parse current JSON file \"\(url.path)\":  \(error.localizedDescription)")
		}
	}
	
	
	func output(outputType: OutputType) -> String {
		switch outputType {
			case .csv:
				exit(error: "Not implemented")
			
			case .json:
				do {
					let jsonEncoder = JSONEncoder()
					jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
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
					
					return jsonString
				}
				catch {
					exit(error: "Couldn't generate output JSON: \(error)")
				}
		}
	}
	
	
	
	// MARK: Parsing FFMetadata & CSV
	
	func addMetadata(fromFiles inputFiles: [URL], withType inputType: InputType, overwrite: Bool) {
		for url in inputFiles {
			stderr("> \(url.path)")
			do {
				let content = try String(contentsOf: url).split(separator: "\n")
				
				switch inputType {
					case .ffmetadata: 
						do {
							try handleFFMetadata(lines: content, overwrite: overwrite)
						}
						catch let error as FFMetadataParseError {
							stderr("Error parsing ffmetadata file \"\(url.path)\":  \(error.description)")
						}
					
					case .csv:
						for (i, line) in content.dropFirst().enumerated() {
							let lineNumber = i+2
							do {
								try handleCSV(line: line, overwrite: overwrite)
							}
							catch let error as CSVParseError {
								stderr("Error parsing csv file \"\(url.path)\" at line \(lineNumber):  \(error.description)")
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
	
	func handleFFMetadata<T: StringProtocol>(lines: [T], overwrite: Bool) throws {
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
		guard let nummerStringEnd = albumValue.index(nummerStringStart, offsetBy: 3, limitedBy: albumValue.endIndex) else {
			throw FFMetadataParseError.albumTagParseError
		}
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
		
		// Find or create folge/teil based on nummer
		let folge = findOrCreateFolge(nummer: nummer)
		
		if let teilNummer = teilNummer {
			let teil = findOrCreateTeil(teilNummer: teilNummer, inFolge: folge)
			
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
	
	func handleCSV<T: StringProtocol>(line: T, overwrite: Bool) throws {
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
		let folge = findOrCreateFolge(nummer: nummer)
		
		update(&folge.titel, to: folgenTitel, description: "titel")
		update(&folge.beschreibung, to: beschreibung, description: "beschreibung")
		update(&folge.veröffentlichungsdatum, to: veröffentlichungsdatum, description: "veröffentlichungsdatum")
		update(&folge.sprecher, to: sprecher, description: "sprecher")
	}
	
	
	
	func findOrCreateFolge(nummer: UInt) -> Folge {
		if let folge = metadata.serie.first(where: { $0.nummer == nummer }) {
			return folge
		}
		else {
			let folge = Folge(nummer: nummer)
			let indexOfSuccessor = metadata.serie.firstIndex { $0.nummer > nummer }
			metadata.serie.insert(folge, at: indexOfSuccessor ?? metadata.serie.endIndex)
			return folge
		}
	}
	func findOrCreateTeil(teilNummer: UInt, inFolge folge: Folge) -> Teil {
		if folge.teile == nil {
			folge.teile = [Teil]()
		}
		else {
			if let teil = folge.teile!.first(where: { $0.teilNummer == teilNummer }) {
				return teil
			}
		}
		
		let teil = Teil(teilNummer: teilNummer)
		let indexOfSuccessor = folge.teile!.firstIndex { $0.teilNummer > teilNummer }
		folge.teile!.insert(teil, at: indexOfSuccessor ?? folge.teile!.endIndex)
		return teil
	}
	
}

