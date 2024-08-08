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
	var serie: [SerieFolge] = []
	var spezial: [SpezialFolge] = []
	var kurzgeschichten: [KurzgeschichtenFolge] = []
	var dieDr3i: [DieDr3iFolge] = []
	var kids: [KidsFolge] = []
	
	var hörspiel: [Hörspiel] = []
	var hörspielTeil: [HörspielTeil] = []
	
	var medium: [Medium] = []
	var track: [Track] = []
	var kapitel: [Kapitel] = []
	
	var person: [Person] = []
	var pseudonym: [Pseudonym] = []
	var rolle: [Rolle] = []
	var sprechrolle: [Sprechrolle] = []
	var sprechrolleTeil: [SprechrolleTeil] = []
	var spricht: [Spricht] = []
	
	var hörspielBuchautor: [HörspielBuchautor] = []
	var hörspielSkriptautor: [HörspielSkriptautor] = []
}


extension MetadataRelationalModel {
	
	struct SerieFolge: Codable {
		var nummer: UInt
		
		var hörspielID: Hörspiel.ID
	}
	
	struct SpezialFolge: Codable {
		var hörspielID: Hörspiel.ID
		
		var position: UInt
	}
	
	struct KurzgeschichtenFolge: Codable {
		var hörspielID: Hörspiel.ID
	}
	
	struct DieDr3iFolge: Codable {
		var nummer: UInt?
		
		var hörspielID: Hörspiel.ID
	}
	
	struct KidsFolge: Codable {
		var nummer: UInt?
		
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
		var cover: UInt
		var urlCoverApple: String?
		var urlCoverKosmos: String?
		var urlDreifragezeichen: String?
		var urlAppleMusic: String?
		var urlSpotify: String?
		var urlBookbeat: String?
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
		var ripLog: Bool
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
	
	struct SprechrolleTeil: Codable {
		var sprechrolleID: Sprechrolle.ID
		var hörspielID: Hörspiel.ID
		
		var position: UInt
	}
	
	struct Spricht: Codable {
		var sprechrolleID: Sprechrolle.ID
		var personID: Person.ID
		
		var pseudonymID: Pseudonym.ID?
		var position: UInt
	}
	
	
	struct HörspielBuchautor: Codable {
		var hörspielID: Hörspiel.ID
		var personID: Person.ID
	}
	
	struct HörspielSkriptautor: Codable {
		var hörspielID: Hörspiel.ID
		var personID: Person.ID
	}
	
}


// MARK: - Database Protocols Conformance

typealias PersistableFetchableTableRecord = TableRecord & FetchableRecord & PersistableRecord

protocol UniquePrimaryKeyName {
	static var primaryKeyName: String { get }
}

extension MetadataRelationalModel.SerieFolge: PersistableFetchableTableRecord, Identifiable {
	static let databaseTableName = "serie"
	var id: UInt { nummer }
}
extension MetadataRelationalModel.SpezialFolge: PersistableFetchableTableRecord, Identifiable {
	static let databaseTableName = "spezial"
	var id: MetadataRelationalModel.Hörspiel.ID { hörspielID }
}
extension MetadataRelationalModel.KurzgeschichtenFolge: PersistableFetchableTableRecord, Identifiable {
	static let databaseTableName = "kurzgeschichten"
	var id: MetadataRelationalModel.Hörspiel.ID { hörspielID }
}
extension MetadataRelationalModel.DieDr3iFolge: PersistableFetchableTableRecord, Identifiable {
	static let databaseTableName = "dieDr3i"
	var id: MetadataRelationalModel.Hörspiel.ID { hörspielID }
}
extension MetadataRelationalModel.KidsFolge: PersistableFetchableTableRecord, Identifiable {
	static let databaseTableName = "kids"
	var id: MetadataRelationalModel.Hörspiel.ID { hörspielID }
}
extension MetadataRelationalModel.Hörspiel: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "hörspielID"
	var id: ID { hörspielID }
}
extension MetadataRelationalModel.HörspielTeil: PersistableFetchableTableRecord { }
extension MetadataRelationalModel.Medium: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "mediumID"
	var id: ID { mediumID }
}
extension MetadataRelationalModel.Track: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "trackID"
	var id: ID { trackID }
}
extension MetadataRelationalModel.Kapitel: PersistableFetchableTableRecord, Identifiable {
	var id: MetadataRelationalModel.Track.ID { trackID }
}
extension MetadataRelationalModel.Person: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "personID"
	var id: ID { personID }
}
extension MetadataRelationalModel.Pseudonym: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "pseudonymID"
	var id: ID { pseudonymID }
}
extension MetadataRelationalModel.Rolle: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "rolleID"
	var id: ID { rolleID }
}
extension MetadataRelationalModel.Sprechrolle: PersistableFetchableTableRecord, UniquePrimaryKeyName, Identifiable {
	static let primaryKeyName = "sprechrolleID"
	var id: ID { sprechrolleID }
}
extension MetadataRelationalModel.SprechrolleTeil: PersistableFetchableTableRecord { }
extension MetadataRelationalModel.Spricht: PersistableFetchableTableRecord { }
extension MetadataRelationalModel.HörspielBuchautor: PersistableFetchableTableRecord { }
extension MetadataRelationalModel.HörspielSkriptautor: PersistableFetchableTableRecord { }


// MARK: - Database Writing

extension MetadataRelationalModel {
	
	static func createSchema(db: Database) throws {
		@discardableResult
		func foreignKeyReference<T: UniquePrimaryKeyName & TableRecord>(
			_ t: TableDefinition,
			to tableType: T.Type,
			name: String? = nil,
			type: Database.ColumnType? = .integer,
			onDelete deleteAction: Database.ForeignKeyAction? = .cascade,
			onUpdate updateAction: Database.ForeignKeyAction? = .cascade
		) -> ColumnDefinition {
			t.column(name ?? tableType.primaryKeyName, type)
				.references(
					tableType.databaseTableName,
					onDelete: deleteAction,
					onUpdate: updateAction
				)
				.notNull()
		}
		@discardableResult
		func positionColumn(_ t: TableDefinition) -> ColumnDefinition {
			t.column("position", .integer)
				.check { $0 > 0 }
				.notNull()
		}
		
		// Hörspiel
		try db.create(table: Hörspiel.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Hörspiel.primaryKeyName)
				.notNull()
			t.column("titel", .text)
				.notNull()
			t.column("kurzbeschreibung", .text)
			t.column("beschreibung", .text)
			t.column("metabeschreibung", .text)
			t.column("veröffentlichungsdatum", .date)
			t.column("unvollständig", .boolean)
				.notNull()
			t.column("cover", .integer)
				.check { $0 >= 0 }
				.notNull()
			t.column("urlCoverApple", .text)
			t.column("urlCoverKosmos", .text)
			t.column("urlDreifragezeichen", .text)
			t.column("urlAppleMusic", .text)
			t.column("urlSpotify", .text)
			t.column("urlBookbeat", .text)
		}
		// HörspielTeil
		try db.create(table: HörspielTeil.databaseTableName) { t in
			foreignKeyReference(t, to: Hörspiel.self, name: "teil")
				.primaryKey()
			foreignKeyReference(t, to: Hörspiel.self, name: "hörspiel")
			positionColumn(t)
			t.column("buchstabe", .text)
				.check { length($0) == 1 }
			t.uniqueKey(["hörspiel", "position"])
			t.uniqueKey(["hörspiel", "buchstabe"])
		}
		
		// SerieFolge
		try db.create(table: SerieFolge.databaseTableName) { t in
			t.primaryKey("nummer", .integer)
				.notNull()
			foreignKeyReference(t, to: Hörspiel.self)
				.unique()
		}
		// SpezialFolge
		try db.create(table: SpezialFolge.databaseTableName) { t in
			foreignKeyReference(t, to: Hörspiel.self)
				.primaryKey()
			positionColumn(t)
				.unique()
		}
		// KurzgeschichtenFolge
		try db.create(table: KurzgeschichtenFolge.databaseTableName) { t in
			foreignKeyReference(t, to: Hörspiel.self)
				.primaryKey()
		}
		// DieDr3iFolge
		try db.create(table: DieDr3iFolge.databaseTableName) { t in
			t.column("nummer", .integer)
			foreignKeyReference(t, to: Hörspiel.self)
				.primaryKey()
		}
		// KidsFolge
		try db.create(table: KidsFolge.databaseTableName) { t in
			t.column("nummer", .integer)
			foreignKeyReference(t, to: Hörspiel.self)
				.primaryKey()
		}
		
		// Medium
		try db.create(table: Medium.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Medium.primaryKeyName)
				.notNull()
			foreignKeyReference(t, to: Hörspiel.self)
			positionColumn(t)
			t.column("ripLog", .boolean)
				.notNull()
			t.uniqueKey([Hörspiel.primaryKeyName, "position"])
		}
		// Track
		try db.create(table: Track.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Track.primaryKeyName)
				.notNull()
			foreignKeyReference(t, to: Medium.self)
			positionColumn(t)
			t.column("titel", .text)
				.notNull()
			t.column("dauer", .integer)
				.check { $0 > 0 }
				.notNull()
			t.uniqueKey([Medium.primaryKeyName, "position"])
		}
		// Kapitel
		try db.create(table: Kapitel.databaseTableName) { t in
			foreignKeyReference(t, to: Track.self)
				.primaryKey()
			foreignKeyReference(t, to: Hörspiel.self)
			positionColumn(t)
			t.column("abweichenderTitel", .text)
			t.uniqueKey([Hörspiel.primaryKeyName, "position"])
		}
		
		// Person
		try db.create(table: Person.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Person.primaryKeyName)
				.notNull()
			t.column("name", .text)
				.notNull()
				.unique()
		}
		// Pseudonym
		try db.create(table: Pseudonym.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Pseudonym.primaryKeyName)
				.notNull()
			t.column("name", .text)
				.notNull()
				.unique()
		}
		// Rolle
		try db.create(table: Rolle.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Rolle.primaryKeyName)
				.notNull()
			t.column("name", .text)
				.notNull()
				.unique()
		}
		// Sprechrolle
		try db.create(table: Sprechrolle.databaseTableName) { t in
			t.autoIncrementedPrimaryKey(Sprechrolle.primaryKeyName)
				.notNull()
			foreignKeyReference(t, to: Hörspiel.self)
			foreignKeyReference(t, to: Rolle.self)
			positionColumn(t)
			t.uniqueKey([Hörspiel.primaryKeyName, Rolle.primaryKeyName])
			t.uniqueKey([Hörspiel.primaryKeyName, "position"])
		}
		// SprechrolleTeil
		try db.create(table: SprechrolleTeil.databaseTableName) { t in
			t.primaryKey {
				foreignKeyReference(t, to: Sprechrolle.self)
				foreignKeyReference(t, to: Hörspiel.self)
			}
			positionColumn(t)
			t.uniqueKey([Hörspiel.primaryKeyName, "position"])
		}
		// Spricht
		try db.create(table: Spricht.databaseTableName) { t in
			t.primaryKey {
				foreignKeyReference(t, to: Sprechrolle.self)
				foreignKeyReference(t, to: Person.self)
			}
			
			t.column(Pseudonym.primaryKeyName, .integer)
				.references(
					Pseudonym.databaseTableName,
					onDelete: .setNull,
					onUpdate: .cascade
				)
			positionColumn(t)
			t.uniqueKey([Sprechrolle.primaryKeyName, "position"])
		}
		
		// HörspielBuchautor
		try db.create(table: HörspielBuchautor.databaseTableName) { t in
			t.primaryKey {
				foreignKeyReference(t, to: Hörspiel.self)
				foreignKeyReference(t, to: Person.self)
			}
		}
		// HörspielSkriptautor
		try db.create(table: HörspielSkriptautor.databaseTableName) { t in
			t.primaryKey {
				foreignKeyReference(t, to: Hörspiel.self)
				foreignKeyReference(t, to: Person.self)
			}
		}
	}
	
	func insertValues(db: Database) throws {
		func insertAll<T: PersistableRecord>(_ collection: [T]) throws {
			try collection.forEach { try $0.insert(db) }
		}
		try insertAll(hörspiel)
		try insertAll(hörspielTeil)
		try insertAll(serie)
		try insertAll(spezial)
		try insertAll(kurzgeschichten)
		try insertAll(dieDr3i)
		try insertAll(kids)
		try insertAll(medium)
		try insertAll(track)
		try insertAll(kapitel)
		try insertAll(person)
		try insertAll(pseudonym)
		try insertAll(rolle)
		try insertAll(sprechrolle)
		try insertAll(sprechrolleTeil)
		try insertAll(spricht)
		try insertAll(hörspielBuchautor)
		try insertAll(hörspielSkriptautor)
	}
	
}


// MARK: - Database Reading

extension MetadataRelationalModel {
	
	init(fromDatabase db: Database) throws {
		self.init()
		func fetchAll<T: FetchableRecord & TableRecord>(_ keyPath: WritableKeyPath<Self, [T]>) throws {
			self[keyPath: keyPath] = try T.fetchAll(db)
		}
		try fetchAll(\.hörspiel)
		try fetchAll(\.hörspielTeil)
		try fetchAll(\.serie)
		try fetchAll(\.spezial)
		try fetchAll(\.kurzgeschichten)
		try fetchAll(\.dieDr3i)
		try fetchAll(\.kids)
		try fetchAll(\.medium)
		try fetchAll(\.track)
		try fetchAll(\.kapitel)
		try fetchAll(\.person)
		try fetchAll(\.pseudonym)
		try fetchAll(\.rolle)
		try fetchAll(\.sprechrolle)
		try fetchAll(\.sprechrolleTeil)
		try fetchAll(\.spricht)
		try fetchAll(\.hörspielBuchautor)
		try fetchAll(\.hörspielSkriptautor)
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
		// Empty result without headers if table is empty
		guard let firstItem = table.first else { return "" }
		
		let rowDelimiter: StringLiteralType = "¶"
		let encoder = CSVEncoder() {
			$0.headers = Mirror(reflecting: firstItem).children.map { $0.label! }
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
		
		func encodeTable<T: Encodable & TableRecord>(_ table: [T]) throws {
			let name = T.databaseTableName
			let tsv: String
			do {
				tsv = try Self.tsvString(of: table)
			}
			catch {
				throw TSVError.encodingError(tableName: name, error: error)
			}
			result.append((name, tsv))
		}
		try encodeTable(serie)
		try encodeTable(spezial)
		try encodeTable(kurzgeschichten)
		try encodeTable(dieDr3i)
		try encodeTable(kids)
		try encodeTable(hörspiel)
		try encodeTable(hörspielTeil)
		try encodeTable(medium)
		try encodeTable(track)
		try encodeTable(kapitel)
		try encodeTable(person)
		try encodeTable(pseudonym)
		try encodeTable(rolle)
		try encodeTable(sprechrolle)
		try encodeTable(sprechrolleTeil)
		try encodeTable(spricht)
		try encodeTable(hörspielBuchautor)
		try encodeTable(hörspielSkriptautor)
		
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
