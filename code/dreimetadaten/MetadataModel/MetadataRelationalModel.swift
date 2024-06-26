//
//  MetadataRelationalModel.swift
//  dreimetadaten
//
//  Created by YourMJK on 29.03.24.
//

import Foundation
import CodableCSV
import GRDB


struct MetadataRelationalModel {
	var serie: [SerieFolge]
	var spezial: [SpezialFolge]
	var kurzgeschichten: [KurzgeschichtenFolge]
	var dieDr3i: [DieDr3iFolge]
	
	var hörspiel: [Hörspiel]
	var hörspielTeil: [HörspielTeil]
	
	var medium: [Medium]
	var track: [Track]
	var kapitel: [Kapitel]
	
	var person: [Person]
	var pseudonym: [Pseudonym]
	var rolle: [Rolle]
	var sprechrolle: [Sprechrolle]
	var spricht: [Spricht]
	
	var hörspielBuchautor: [HörspielBuchautor]
	var hörspielSkriptautor: [HörspielSkriptautor]
}


extension MetadataRelationalModel {
	
	struct SerieFolge: Codable {
		var nummer: Int
		
		var hörspielID: Hörspiel.ID
	}
	
	struct SpezialFolge: Codable {
		var hörspielID: Hörspiel.ID
	}
	
	struct KurzgeschichtenFolge: Codable {
		var hörspielID: Hörspiel.ID
	}
	
	struct DieDr3iFolge: Codable {
		var nummer: Int
		
		var hörspielID: Hörspiel.ID
	}
	
	
	struct Hörspiel: Codable {
		typealias ID = UInt
		var hörspielID: ID
		
		var titel: String
		var kurzbeschreibung: String?
		var beschreibung: String?
		var metabeschreibung: String?
		var veröffentlichungsdatum: DatabaseDateComponents?
		var unvollständig: Bool
		var cover: Bool
		var urlCoverApple: String?
		var urlCoverKosmos: String?
	}
	
	struct HörspielTeil: Codable {
		var teil: Hörspiel.ID
		
		var hörspiel: Hörspiel.ID
		var position: UInt
		var buchstabe: String?
	}
	
	
	struct Medium: Codable {
		typealias ID = UInt
		var mediumID: ID
		
		var hörspielID: Hörspiel.ID
		var position: UInt
		var xldLog: Bool
	}
	
	struct Track: Codable {
		typealias ID = UInt
		var trackID: ID
		
		var mediumID: Medium.ID
		var position: UInt
		var titel: String
		var dauer: UInt
	}
	
	struct Kapitel: Codable {
		var trackID: Track.ID
		
		var hörspielID: Hörspiel.ID
		var position: UInt
		var abweichenderTitel: String?
	}
	
	
	struct Person: Codable {
		typealias ID = UInt
		var personID: ID
		
		var name: String
	}
	
	struct Pseudonym: Codable {
		typealias ID = UInt
		var pseudonymID: ID
		
		var name: String
	}
	
	struct Rolle: Codable {
		typealias ID = UInt
		var rolleID: ID
		
		var name: String
	}
	
	struct Sprechrolle: Codable {
		typealias ID = UInt
		var sprechrolleID: ID
		
		var hörspielID: Hörspiel.ID
		var rolleID: Rolle.ID
		var position: UInt
	}
	
	struct Spricht: Codable {
		var sprechrolleID: Sprechrolle.ID
		var personID: Person.ID
		
		var pseudonymID: Pseudonym.ID?
	}
	
	
	struct HörspielBuchautor: Codable {
		var hörspielID: Hörspiel.ID
		var buchautor: Person.ID
	}
	
	struct HörspielSkriptautor: Codable {
		var hörspielID: Hörspiel.ID
		var skriptautor: Person.ID
	}
	
}


// MARK: - TSV Encoding

extension MetadataRelationalModel {
	
	enum TSVError: LocalizedError {
		case encodingError(tableName: String, error: Error)
		case fileError(url: URL, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .encodingError(let tableName, let error):
					return "Couldn't encode TSV for table \"\(tableName)\": \(error.localizedDescription)"
				case .fileError(let url, let error):
					return "Couldn't write file \"\(url.relativePath)\": \(error.localizedDescription)"
			}
		}
	}
	
	
	static func tsvString<T: Encodable>(of table: [T]) throws -> String {
		let rowDelimiter: StringLiteralType = "¶"
		let encoder = CSVEncoder() {
			$0.headers = Mirror(reflecting: table.first!).children.map { $0.label! }
			$0.delimiters = (field: "\t", row: .init(stringLiteral: rowDelimiter))
			$0.escapingStrategy = .none
			$0.nilStrategy = .empty
			$0.encoding = .utf8
		}
		var string = try encoder.encode(table, into: String.self)
		
		// Escape newlines in records and replace temporary row delimiter with actual newline
		string = string.replacingOccurrences(of: "\n", with: "\\n")
		string = string.replacingOccurrences(of: rowDelimiter, with: "\n")
		
		return string
	}
	
	func tsvStrings() throws -> [(tableName: String, content: String)] {
		var result: [(tableName: String, content: String)] = []
		
		func encodeTable<T: Encodable>(_ name: String, _ keyPath: KeyPath<Self, [T]>) throws {
			let table = self[keyPath: keyPath]
			let tsv: String
			do {
				tsv = try Self.tsvString(of: table)
			}
			catch {
				throw TSVError.encodingError(tableName: name, error: error)
			}
			result.append((name, tsv))
		}
		try encodeTable("serie", \.serie)
		try encodeTable("spezial", \.spezial)
		try encodeTable("kurzgeschichten", \.kurzgeschichten)
		try encodeTable("dieDr3i", \.dieDr3i)
		try encodeTable("hörspiel", \.hörspiel)
		try encodeTable("hörspielTeil", \.hörspielTeil)
		try encodeTable("medium", \.medium)
		try encodeTable("track", \.track)
		try encodeTable("kapitel", \.kapitel)
		try encodeTable("person", \.person)
		try encodeTable("pseudonym", \.pseudonym)
		try encodeTable("rolle", \.rolle)
		try encodeTable("sprechrolle", \.sprechrolle)
		try encodeTable("spricht", \.spricht)
		try encodeTable("hörspielBuchautor", \.hörspielBuchautor)
		try encodeTable("hörspielSkriptautor", \.hörspielSkriptautor)
		
		return result
	}
	
	func writeTSVFiles(to directory: URL) throws {
		for (tableName, content) in try tsvStrings() {
			let file = directory.appendingPathComponent("\(tableName).tsv", isDirectory: false)
			do {
				try content.write(to: file, atomically: false, encoding: .utf8)
			}
			catch {
				throw TSVError.fileError(url: file, error: error)
			}
		}
	}
}
