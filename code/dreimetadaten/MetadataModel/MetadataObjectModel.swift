//
//  MetadataObjectModel.swift
//  dreimetadaten
//
//  Created by YourMJK on 28.03.24.
//

import Foundation


struct MetadataObjectModel: Codable {
	var serie: [Folge]?
	var spezial: [Hörspiel]?
	var kurzgeschichten: [Hörspiel]?
	var die_dr3i: [Folge]?
}


extension MetadataObjectModel {
	
	class Hörspiel: Codable {
		var teile: [Teil]?
		var titel: String?
		var autor: String?
		var hörspielskriptautor: String?
		var beschreibung: String?
		var metabeschreibung: String?
		var veröffentlichungsdatum: String?
		var kapitel: [Kapitel]?
		var sprechrollen: [Sprechrolle]?
		var links: Links?
		var unvollständig: Bool?
	}
	
	class Folge: Hörspiel {
		var nummer: Int
		
		// Codable
		enum CodingKeys: CodingKey {
			case nummer
		}
		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			nummer = try container.decode(Int.self, forKey: .nummer)
			try super.init(from: decoder)
		}
		override func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(nummer, forKey: .nummer)
			try super.encode(to: encoder)
		}
	}
	
	class Teil: Hörspiel {
		var teilNummer: UInt
		var buchstabe: String?
		
		// Codable
		enum CodingKeys: CodingKey {
			case teilNummer
			case buchstabe
		}
		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			teilNummer = try container.decode(UInt.self, forKey: .teilNummer)
			buchstabe = try container.decodeIfPresent(String.self, forKey: .buchstabe)
			try super.init(from: decoder)
		}
		override func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(teilNummer, forKey: .teilNummer)
			try container.encodeIfPresent(buchstabe, forKey: .buchstabe)
			try super.encode(to: encoder)
		}
	}
	
	struct Kapitel: Codable {
		var titel: String
		var start: Int?
		var end: Int?
	}
	
	struct Sprechrolle: Codable {
		var rolle: String
		var sprecher: String
		var pseudonym: String?
	}
	
	struct Links: Codable {
		var json: String?
		var ffmetadata: String?
		var xld_log: String?
		var cover: String?
		var cover_itunes: String?
		var cover_kosmos: String?
	}
	
}


// MARK: - JSON Encoding & Decoding

extension MetadataObjectModel {
	
	struct OrderedCodingKey: CodingKey {
		var stringValue: String
		var intValue: Int?
		
		init(_ key: CodingKey) {
			self.stringValue = Self.prefixedKeyString(keyString: key.stringValue)
			self.intValue = key.intValue
		}
		init?(stringValue: String) {
			self.stringValue = stringValue
		}
		init?(intValue: Int) {
			self.stringValue = "\(intValue)"
			self.intValue = intValue
		}
		
		static let ordering: [String] = [
			"serie",
			"spezial",
			"kurzgeschichten",
			"die_dr3i",
			
			"nummer",
			"teile",
			
			"teilNummer",
			"buchstabe",
			
			"titel",
			"autor",
			"hörspielskriptautor",
			"beschreibung",
			"metabeschreibung",
			"veröffentlichungsdatum",
			"kapitel",
			"sprechrollen",
			"links",
			"unvollständig",
			
			"titel",
			"start",
			"end",
			
			"rolle",
			"sprecher",
			"pseudonym",
			
			"json",
			"ffmetadata",
			"xld_log",
			"cover",
			"cover_itunes",
			"cover_kosmos"
		]
		static func prefixedKeyString(keyString: String) -> String {
			let number = Self.ordering.firstIndex(of: keyString) ?? 99
			return String(format: "%02d_%@", number, keyString)
		}
	}
	
	enum JSONError: LocalizedError {
		case encodingError(error: Error)
		case decodingError(error: Error)
		case fileError(url: URL, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .encodingError(let error):
					return "Couldn't encode JSON: \(error.localizedDescription)"
				case .decodingError(let error):
					return "Couldn't decode JSON: \(error.localizedDescription)"
				case .fileError(let url, let error):
					return "Couldn't read file \"\(url.relativePath)\": \(error.localizedDescription)"
			}
		}
	}
	
	
	// MARK: - Encoding
	
	static func jsonString<T: Encodable>(of object: T) throws -> String {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys /*, .withoutEscapingSlashes*/]
		jsonEncoder.keyEncodingStrategy = .custom({ Self.OrderedCodingKey($0.last!) })
		let jsonData: Data
		do {
			jsonData = try jsonEncoder.encode(object)
		}
		catch {
			throw JSONError.encodingError(error: error)
		}
		var jsonString = String(data: jsonData, encoding: .utf8)!
		
		// Replace prefixed ordered keys with normal keys again
		for key in Self.OrderedCodingKey.ordering {
			let prefixedKey = Self.OrderedCodingKey.prefixedKeyString(keyString: key)
			let target = "\"\(prefixedKey)\""
			let replacement = "\"\(key)\""
			jsonString = jsonString.replacingOccurrences(of: target, with: replacement)  // despite copy overhead 10x faster than range(of:) + mutating replaceSubrange()
		}
		jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
		
		// Normalize Unicode characters into NFC, e.g. replacing "\u{0061}\u{0308}" (LATIN SMALL LETTER A + COMBINING DIAERESIS) with "\u{00E4}" (LATIN SMALL LETTER A WITH DIAERESIS)
		jsonString = jsonString.precomposedStringWithCanonicalMapping
		
		// Add trailing newline
		jsonString.append("\n")
		
		return jsonString
	}
	
	func jsonString() throws -> String {
		try Self.jsonString(of: self)
	}
	
	
	// MARK: - Decoding
	
	init(fromJSON url: URL) throws {
		let jsonData: Data
		do {
			jsonData = try Data(contentsOf: url)
		}
		catch {
			throw JSONError.fileError(url: url, error: error)
		}
		try self.init(fromJSON: jsonData)
	}
	
	init(fromJSON data: Data) throws {
		let jsonDecoder = JSONDecoder()
		do {
			self = try jsonDecoder.decode(Self.self, from: data)
		}
		catch {
			throw JSONError.decodingError(error: error)
		}
	}
	
}
