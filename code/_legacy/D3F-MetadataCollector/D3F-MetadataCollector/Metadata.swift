//
//  Metadata.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 13.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


struct Metadata: Codable {
	var serie: [Folge]?
	var spezial: [Höreinheit]?
	var kurzgeschichten: [Höreinheit]?
	var die_dr3i: [Folge]?
}


class Höreinheit: Codable {
	var teile: [Teil]?
	var titel: String?
	var autor: String?
	var hörspielskriptautor: String?
	var beschreibung: String?
	var veröffentlichungsdatum: String?
	var kapitel: [Kapitel]?
	var sprechrollen: [Sprechrolle]?
	var links: Links?
	var unvollständig: Bool?
}


class Folge: Höreinheit {
	let nummer: Int
	
	init(nummer: Int) {
		self.nummer = nummer
		super.init()
	}
	
	
	// Codable
	enum CodingKeys: CodingKey {
		case nummer
		case teile
	}
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		nummer = try container.decode(Int.self, forKey: .nummer)
		try super.init(from: decoder)
	}
	override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(nummer, forKey: .nummer)
		try container.encodeIfPresent(teile, forKey: .teile)
		try super.encode(to: encoder)
	}
}


class Teil: Höreinheit {
	let teilNummer: UInt
	var buchstabe: String?
	
	init(teilNummer: UInt) {
		self.teilNummer = teilNummer
		super.init()
	}
	
	
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



class Kapitel: Codable, Equatable {
	let titel: String
	var start: Int?
	var end: Int?
	
	init(titel: String) {
		self.titel = titel
	}
	
	static func == (lhs: Kapitel, rhs: Kapitel) -> Bool {
		return lhs.titel == rhs.titel && lhs.start == rhs.start && lhs.end == rhs.end 
	}
}


class Sprechrolle: Codable, Equatable {
	var rolle: String
	var sprecher: String
	var pseudonym: String?
	
	init(rolle: String, sprecher: String) {
		self.rolle = rolle
		self.sprecher = sprecher
	}
	
	static func == (lhs: Sprechrolle, rhs: Sprechrolle) -> Bool {
		return lhs.rolle == rhs.rolle && lhs.sprecher == rhs.sprecher && lhs.pseudonym == rhs.pseudonym
	}
}


class Links: Codable {
	var json: String?
	var ffmetadata: String?
	var xld_log: String?
	var cover: String?
	var cover_itunes: String?
	var cover_kosmos: String?
}



// MARK: OrderedCodingKey

extension Metadata {
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
	
	
	static func createJSONString<T: Encodable>(of object: T) throws -> String {
		do {
			let jsonEncoder = JSONEncoder()
			jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys /*, .withoutEscapingSlashes*/]
			jsonEncoder.keyEncodingStrategy = .custom({ Self.OrderedCodingKey($0.last!) })
			let jsonData = try jsonEncoder.encode(object)
			guard var jsonString = String(data: jsonData, encoding: .utf8) else {
				exit(error: "Invalid UTF8 format in output JSON")
			}
			
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
		catch {
			exit(error: "Couldn't generate output JSON: \(error)")
		}
	}
	
	func createJSONString() -> String {
		do {
			return try Self.createJSONString(of: self)
		}
		catch {
			exit(error: "Couldn't generate master JSON: \(error)")
		}
	}
}



// MARK: Updatable

extension Metadata {
	static func updateJSON(old oldJSON: inout Any?, new newJSON: Any?, overwrite: Bool) {
		guard oldJSON != nil else {
			oldJSON = newJSON
			return
		}
		
		var foundType = false
		func tryType<U>(_ type: U.Type, _ handler: (inout U, U) -> Void) {
			if !foundType, var oldCast = oldJSON as? U {
				foundType = true
				guard let newCast = newJSON as? U else {
					stderr("Non-matching types found while updating")
					return
				}
				handler(&oldCast, newCast)
				oldJSON = oldCast
			}
		}
		func updateEquatable<U: Equatable>(oldValue: inout U, newValue: U) {
			oldValue.update(with: newValue, overwrite: overwrite)
		}
		
		tryType([String: Any].self) { (oldDict, newDict) in
			for key in newDict.keys {
				updateJSON(old: &oldDict[key], new: newDict[key], overwrite: overwrite)
			}
		}
		tryType([Any?].self) { (oldArray, newArray) in
			if oldArray.count == newArray.count {
				for (i, newValue) in newArray.enumerated() {
					updateJSON(old: &oldArray[i], new: newValue, overwrite: overwrite)
				}
			}
			else {
				stderr("Cannot update arrays of differing lengths")
			}
		}
		tryType(String.self, updateEquatable(oldValue:newValue:))
		tryType(Int.self, updateEquatable(oldValue:newValue:))
		
		if !foundType {
			stderr("Couldn't match type while updating")
		}
	}
}

protocol Updatable: Codable {
	mutating func update(with new: Self, overwrite: Bool)
}
extension Updatable {
	mutating func update(with new: Self, overwrite: Bool = false) {
		let encoder = JSONEncoder()
		let decoder = JSONDecoder()
		func jsonObject(_ obj: Self) -> Any {
			let data = try! encoder.encode(obj)
			return try! JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
		}
		var oldJSON: Any? = jsonObject(self)
		let newJSON = jsonObject(new)
		
		Metadata.updateJSON(old: &oldJSON, new: newJSON, overwrite: overwrite)
		let oldData = try! JSONSerialization.data(withJSONObject: oldJSON!, options: [.fragmentsAllowed])
		let updateSelf = try! decoder.decode(Self.self, from: oldData)
		self = updateSelf
	}
}

extension Equatable {
	mutating func update(with newValue: Self, overwrite: Bool) {
		if self != newValue {
			if overwrite {
				self = newValue
			}
			else {
				stderr("\"\(self)\" not overwritten with \"\(newValue)\"")
			}
		}
	}
}

