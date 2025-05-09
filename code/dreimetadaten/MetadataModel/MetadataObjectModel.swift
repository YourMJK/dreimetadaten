//
//  MetadataObjectModel.swift
//  dreimetadaten
//
//  Created by YourMJK on 28.03.24.
//

import Foundation
import GRDB
import Collections


struct MetadataObjectModel: Codable {
	var serie: [Folge]?
	var spezial: [Hörspiel]?
	var kurzgeschichten: [Hörspiel]?
	var die_dr3i: [Hörspiel]?
	var kids: [Hörspiel]?
	var sonstige: [Hörspiel]?
	
	var dbInfo: DBInfo?
}


extension MetadataObjectModel {
	
	class Hörspiel: Codable {
		var titel: String?
		var autor: String?
		var hörspielskriptautor: String?
		var gesamtbeschreibung: String?
		var kurzbeschreibung: String?
		var beschreibung: String?
		var metabeschreibung: String?
		var veröffentlichungsdatum: String?
		var kapitel: [Kapitel]?
		var sprechrollen: [Sprechrolle]?
		var links: Links?
		var ids: IDs?
		var unvollständig: Bool?
		var medien: [Medium]?
		var teile: [Teil]?
	}
	
	class Folge: Hörspiel {
		var nummer: UInt
		
		init(nummer: UInt) {
			self.nummer = nummer
			super.init()
		}
		
		// Codable
		enum CodingKeys: CodingKey {
			case nummer
		}
		required init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			nummer = try container.decode(UInt.self, forKey: .nummer)
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
		var cover: String?
		var cover2: [String]?
		var cover_itunes: String?
		var cover_kosmos: String?
		var dreifragezeichen: String?
		var appleMusic: String?
		var spotify: String?
		var bookbeat: String?
		var amazonMusic: String?
		var amazon: String?
		var youTubeMusic: String?
	}
	
	struct IDs: Codable {
		var dreimetadaten: UInt
		var appleMusic: String?
		var spotify: String?
		var bookbeat: String?
		var amazonMusic: String?
		var amazon: String?
		var youTubeMusic: String?
	}
	
	struct Medium: Codable {
		var tracks: [Kapitel]
		var ripLog: String?
		var musicBrainzID: String?
	}
	
	
	struct DBInfo: Codable {
		var version: String
		var lastModified: String
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
			"dbInfo",
			"version",
			"lastModified",
			
			"serie",
			"spezial",
			"kurzgeschichten",
			"die_dr3i",
			"kids",
			"sonstige",
			
			"nummer",
			
			"teilNummer",
			"buchstabe",
			
			"titel",
			"autor",
			"hörspielskriptautor",
			"gesamtbeschreibung",
			"kurzbeschreibung",
			"beschreibung",
			"metabeschreibung",
			"veröffentlichungsdatum",
			"kapitel",
			"sprechrollen",
			"links",
			"ids",
			"unvollständig",
			"medien",
			"teile",
			
			"titel",
			"start",
			"end",
			
			"rolle",
			"sprecher",
			"pseudonym",
			
			"tracks",
			"ripLog",
			"musicBrainzID",
			
			"json",
			"ffmetadata",
			"cover",
			"cover2",
			"cover_itunes",
			"cover_kosmos",
			"dreifragezeichen",
			
			"dreimetadaten",
			"appleMusic",
			"spotify",
			"bookbeat",
			"amazonMusic",
			"amazon",
			"youTubeMusic",
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
	
	
	// MARK: - Collection Type Masking
	
	func separateByCollectionType(withDBInfo: Bool = false) -> [(objectModel: Self, collectionType: CollectionType)] {
		CollectionType.allCases.map { collectionType in
			var maskedObjectModel = Self()
			switch collectionType.objectModelKeyPath {
				case let keyPath as WritableKeyPath<Self, [Folge]?>:
					maskedObjectModel[keyPath: keyPath] = self[keyPath: keyPath]
				case let keyPath as WritableKeyPath<Self, [Hörspiel]?>:
					maskedObjectModel[keyPath: keyPath] = self[keyPath: keyPath]
				default:
					fatalError("Unrecognized type for CollectionType.objectModelKeyPath")
			}
			if withDBInfo {
				maskedObjectModel.dbInfo = dbInfo
			}
			return (maskedObjectModel, collectionType)
		}
	}
	
}


// MARK: - Database Reading

extension MetadataObjectModel {
	
	init(fromDatabase db: Database, withBaseURL baseURL: URL) throws {
		self.init(serie: [], spezial: [], kurzgeschichten: [], die_dr3i: [], kids: [])
		
		let columnHörspielID = Column(MetadataRelationalModel.Hörspiel.primaryKeyName)
		let columnSprechrolleID = Column(MetadataRelationalModel.Sprechrolle.primaryKeyName)
		let columnMediumID = Column(MetadataRelationalModel.Medium.primaryKeyName)
		let columnPosition = Column("position")
		
		func nilForEmpty<C: Collection>(_ collection: C) -> C? {
			collection.isEmpty ? nil : collection
		}
		func copy(from: Hörspiel, to: Hörspiel) {
			to.titel = from.titel
			to.autor = from.autor
			to.hörspielskriptautor = from.hörspielskriptautor
			to.gesamtbeschreibung = from.gesamtbeschreibung
			to.kurzbeschreibung = from.kurzbeschreibung
			to.beschreibung = from.beschreibung
			to.metabeschreibung = from.metabeschreibung
			to.veröffentlichungsdatum = from.veröffentlichungsdatum
			to.kapitel = from.kapitel
			to.sprechrollen = from.sprechrollen
			to.links = from.links
			to.ids = from.ids
			to.unvollständig = from.unvollständig
			to.medien = from.medien
			to.teile = from.teile
		}
		
		var hörspielObjects = [MetadataRelationalModel.Hörspiel.ID: MetadataObjectModel.Hörspiel]()
		let hörspielArray = try MetadataRelationalModel.Hörspiel.fetchAll(db)
		for hörspiel in hörspielArray {
			// autor
			let buchautorArray = try MetadataRelationalModel.HörspielBuchautor
				.filter(columnHörspielID == hörspiel.hörspielID)
				.fetchAll(db)
				.map {
					try MetadataRelationalModel.Person.find(db, id: $0.personID).name
				}
				.sorted()
			let buchautor = nilForEmpty(buchautorArray)?.joined(separator: ", ")
			
			// hörspielskriptautor
			let skriptautorArray = try MetadataRelationalModel.HörspielSkriptautor
				.filter(columnHörspielID == hörspiel.hörspielID)
				.fetchAll(db)
				.map {
					try MetadataRelationalModel.Person.find(db, id: $0.personID).name
				}
				.sorted()
			let skriptautor = nilForEmpty(skriptautorArray)?.joined(separator: ", ")
			
			// sprechrollen
			// Merge entries from table sprechrolle and sprechrolleTeil (in practice one of them is going to be empty)
			var sprechrollenRows = try MetadataRelationalModel.Sprechrolle
				.filter(columnHörspielID == hörspiel.hörspielID)
				.order(columnPosition)
				.fetchAll(db)
			try MetadataRelationalModel.SprechrolleTeil
				.filter(columnHörspielID == hörspiel.hörspielID)
				.order(columnPosition)
				.fetchAll(db)
				.forEach {
					let row = try MetadataRelationalModel.Sprechrolle.find(db, id: $0.sprechrolleID)
					sprechrollenRows.append(row)
				}
			// Grossly inefficient (this should really be joins) but works for now until I figure out GRDB's associations
			let sprechrollen: [Sprechrolle] = try sprechrollenRows.map { sprechrolle in
				let rolle = try MetadataRelationalModel.Rolle.find(db, id: sprechrolle.rolleID).name
				let sprecherPseudonymArray = try MetadataRelationalModel.Spricht
					.filter(columnSprechrolleID == sprechrolle.sprechrolleID)
					.order(columnPosition)
					.fetchAll(db)
					.map { spricht in
						let name = try MetadataRelationalModel.Person.find(db, id: spricht.personID).name
						let pseudonym = try spricht.pseudonymID.map {
							try MetadataRelationalModel.Pseudonym.find(db, id: $0).name
						}
						return (name: name, pseudonym: pseudonym)
					}
				let sprecherArray = sprecherPseudonymArray.map(\.name)
				let pseudonym = sprecherPseudonymArray.compactMap(\.pseudonym)
				return Sprechrolle(
					rolle: rolle,
					sprecher: sprecherArray.joined(separator: ", "),
					pseudonym: pseudonym.isEmpty ? nil : pseudonym.joined(separator: ", ")
				)
			}
			
			// kapitel
			var start = 0
			let kapitelArray = try MetadataRelationalModel.Kapitel
				.filter(columnHörspielID == hörspiel.hörspielID)
				.order(columnPosition)
				.fetchAll(db)
				.map { kapitel in
					let track = try MetadataRelationalModel.Track.find(db, id: kapitel.trackID)
					let titel = kapitel.abweichenderTitel ?? track.titel
					let end = start + Int(track.dauer)
					let kapitelObject = Kapitel(titel: titel, start: start, end: end)
					start = end
					return kapitelObject
				}
			
			// medien
			var medien = try MetadataRelationalModel.Medium
				.filter(columnHörspielID == hörspiel.hörspielID)
				.order(columnPosition)
				.fetchAll(db)
				.map { medium in
					start = 0
					let tracks = try MetadataRelationalModel.Track
						.filter(columnMediumID == medium.mediumID)
						.order(columnPosition)
						.fetchAll(db)
						.map { track in
							let end = start + Int(track.dauer)
							let trackObject = Kapitel(titel: track.titel, start: start, end: end)
							start = end
							return trackObject
						}
					return Medium(
						tracks: tracks,
						ripLog: medium.ripLog ? "" : nil,
						musicBrainzID: medium.musicBrainzID
					)
				}
			let multipleMedien = medien.count > 1
			for index in medien.indices {
				if medien[index].ripLog != nil {
					medien[index].ripLog = "rip_log\(multipleMedien ? String(index+1) : "").txt"
				}
			}
			
			// veröffentlichungsdatum
			let veröffentlichungsdatum = try hörspiel.veröffentlichungsdatum.map {
				guard $0.format == .YMD else {
					throw DatabaseError.invalidDateFormat(date: $0)
				}
				return String.fromDatabaseValue($0.databaseValue)!
			}
			
			// gesamtbeschreibung
			// kurzbeschreibung + beschreibung, or metabeschreibung if both are nil
			let beschreibungComponents = [hörspiel.kurzbeschreibung, hörspiel.beschreibung].compactMap { $0 }
			let gesamtbeschreibung = beschreibungComponents.isEmpty ? hörspiel.metabeschreibung : beschreibungComponents.joined(separator: "\n")
			
			// Create and remember object model item
			let hörspielObject = Hörspiel()
			hörspielObject.titel = hörspiel.titel
			hörspielObject.autor = buchautor
			hörspielObject.hörspielskriptautor = skriptautor
			hörspielObject.gesamtbeschreibung = gesamtbeschreibung
			hörspielObject.kurzbeschreibung = hörspiel.kurzbeschreibung
			hörspielObject.beschreibung = hörspiel.beschreibung
			hörspielObject.metabeschreibung = hörspiel.metabeschreibung
			hörspielObject.veröffentlichungsdatum = veröffentlichungsdatum
			hörspielObject.kapitel = nilForEmpty(kapitelArray)
			hörspielObject.sprechrollen = nilForEmpty(sprechrollen)
			hörspielObject.medien = nilForEmpty(medien)
			hörspielObject.links = Links(
				json: "metadata.json",
				ffmetadata: !hörspiel.unvollständig ? "ffmetadata.txt" : nil,
				cover: hörspiel.cover > 0 ? "cover.png" : nil,
				cover2: hörspiel.cover > 1 ? (2...hörspiel.cover).map { "cover\($0).png" } : nil,
				cover_itunes: hörspiel.urlCoverApple,
				cover_kosmos: hörspiel.urlCoverKosmos,
				dreifragezeichen: hörspiel.urlDreifragezeichen,
				appleMusic: hörspiel.idAppleMusic.map { "https://music.apple.com/de/album/\($0)" },
				spotify: hörspiel.idSpotify.map { "https://open.spotify.com/intl-de/album/\($0)" },
				bookbeat: hörspiel.idBookbeat.map { "https://www.bookbeat.com/de/book/\($0)" },
				amazonMusic: hörspiel.idAmazonMusic.map { "https://music.amazon.de/albums/\($0)" },
				amazon: hörspiel.idAmazon.map { "https://www.amazon.de/gp/product/\($0)" },
				youTubeMusic: hörspiel.idYouTubeMusic.map { "https://music.youtube.com/browse/\($0)" }
			)
			hörspielObject.ids = IDs(
				dreimetadaten: hörspiel.hörspielID,
				appleMusic: hörspiel.idAppleMusic,
				spotify: hörspiel.idSpotify,
				bookbeat: hörspiel.idBookbeat,
				amazonMusic: hörspiel.idAmazonMusic,
				amazon: hörspiel.idAmazon,
				youTubeMusic: hörspiel.idYouTubeMusic
			)
			hörspielObject.unvollständig = hörspiel.unvollständig ? true : nil
			
			hörspielObjects[hörspiel.hörspielID] = hörspielObject
		}
		
		
		func findHörspielObject<T: TableRecord>(id: MetadataRelationalModel.Hörspiel.ID, from: T.Type) throws -> MetadataObjectModel.Hörspiel {
			guard let object = hörspielObjects[id] else {
				throw DatabaseError.foreignKeyViolation(table: T.databaseTableName)
			}
			return object
		}
		
		// teile
		for (hörspielID, hörspiel) in hörspielObjects {
			let teile = try MetadataRelationalModel.HörspielTeil
				.filter(Column("hörspiel") == hörspielID)
				.order(columnPosition)
				.fetchAll(db)
				.map { hörspielTeil in
					let teilH = try findHörspielObject(id: hörspielTeil.teil, from: MetadataRelationalModel.HörspielTeil.self)
					let teil = Teil(teilNummer: hörspielTeil.position)
					teil.buchstabe = hörspielTeil.buchstabe
					copy(from: teilH, to: teil)
					return teil
				}
			
			// Inherit fields from parent
			for teil in teile {
				func inheritFromParent<T>(_ keypath: ReferenceWritableKeyPath<Hörspiel, T?>) {
					teil[keyPath: keypath] = teil[keyPath: keypath] ?? hörspiel[keyPath: keypath]
				}
				inheritFromParent(\.autor)
				inheritFromParent(\.hörspielskriptautor)
				inheritFromParent(\.veröffentlichungsdatum)
			}
			// Gather fields from children
			func gatherFromChildren(_ keypath: ReferenceWritableKeyPath<Hörspiel, String?>) {
				guard hörspiel[keyPath: keypath] == nil else { return }
				let values = OrderedSet(teile.compactMap { $0[keyPath: keypath] })
				hörspiel[keyPath: keypath] = !values.isEmpty ? values.joined(separator: ", ") : nil
			}
			gatherFromChildren(\.autor)
			gatherFromChildren(\.hörspielskriptautor)
			
			hörspiel.teile = nilForEmpty(teile)
			if !teile.isEmpty {
				hörspiel.links?.ffmetadata = nil
			}
		}
		
		// url
		func apply(url: URL, to hörspiel: Hörspiel) {
			func prepend(to fileName: inout String?) {
				if fileName != nil { prepend(to: &fileName!) }
			}
			func prepend(to fileName: inout String) {
				fileName = url.appendingPathComponent(fileName).absoluteString
			}
			if hörspiel.links != nil {
				prepend(to: &hörspiel.links!.json)
				prepend(to: &hörspiel.links!.ffmetadata)
				prepend(to: &hörspiel.links!.cover)
				hörspiel.links!.cover2?.indices.forEach {
					prepend(to: &hörspiel.links!.cover2![$0])
				}
			}
			hörspiel.medien?.indices.forEach {
				prepend(to: &hörspiel.medien![$0].ripLog)
			}
			hörspiel.teile?.enumerated().forEach { (index, teil) in
				apply(url: url.appendingPathComponent(String(teil.teilNummer)), to: teil)
			}
		}
		func addURL(to hörspiel: Hörspiel, as collectionType: CollectionType) throws {
			let dirname = try WebDataExporter.dirname(for: hörspiel, nummerFormat: collectionType.nummerFormat)
			let url = baseURL
				.appendingPathComponent(collectionType.fileName)
				.appendingPathComponent(dirname)
			apply(url: url, to: hörspiel)
		}
		
		// collections
		func makeFolge(with nummer: UInt?, hörspiel: inout Hörspiel) {
			guard let nummer else { return }
			let folge = Folge(nummer: nummer)
			copy(from: hörspiel, to: folge)
			hörspiel = folge
		}
		func fetchAllAndMap<T: PersistableFetchableTableRecord>(
			_ table: T.Type,
			type: CollectionType,
			id: (T) -> MetadataRelationalModel.Hörspiel.ID,
			asFolge nummer: ((T) -> UInt?)? = nil,
			order: ((T.Type) -> QueryInterfaceRequest<T>)? = nil
		) throws -> [Hörspiel] {
			// Order by primary key (hörspielID) or use custom ordering
			let request: QueryInterfaceRequest<T> = order?(table) ?? table.orderByPrimaryKey()
			return try request
				.fetchAll(db)
				.map {
					// Find object
					var hörspiel = try findHörspielObject(id: id($0), from: table)
					// Convert to Folge if necessary
					if let nummer {
						makeFolge(with: nummer($0), hörspiel: &hörspiel)
					}
					// Add local directory URL
					try addURL(to: hörspiel, as: type)
					return hörspiel
				}
		}
		
		// serie
		serie = try fetchAllAndMap(MetadataRelationalModel.SerieFolge.self, type: .serie, id: \.hörspielID, asFolge: \.nummer)
			.map {
				$0 as! Folge
			}
		
		// spezial
		spezial = try fetchAllAndMap(MetadataRelationalModel.SpezialFolge.self, type: .spezial, id: \.hörspielID, order: {
			$0.order(columnPosition)
		})
		
		// kurzgeschichten
		kurzgeschichten = try fetchAllAndMap(MetadataRelationalModel.KurzgeschichtenFolge.self, type: .kurzgeschichten, id: \.hörspielID)
		
		// die_dr3i
		die_dr3i = try fetchAllAndMap(MetadataRelationalModel.DieDr3iFolge.self, type: .die_dr3i, id: \.hörspielID, asFolge: \.nummer)
		
		// kids
		kids = try fetchAllAndMap(MetadataRelationalModel.KidsFolge.self, type: .kids, id: \.hörspielID, asFolge: \.nummer)
			.sorted { (a, b) in
				a.veröffentlichungsdatum ?? "" < b.veröffentlichungsdatum ?? ""
			}
		
		// sonstige
		sonstige = try fetchAllAndMap(MetadataRelationalModel.SonstigesHörspiel.self, type: .sonstige, id: \.hörspielID)
		
		
		// version
		dbInfo = try MetadataRelationalModel.Version
			.order(Column("date").desc)
			.fetchOne(db)
			.map {
				let versionNumber = "\($0.major).\($0.minor).\($0.patch)"
				let formatter = ISO8601DateFormatter()
				formatter.formatOptions = [.withInternetDateTime]
				let timestamp = formatter.string(from: $0.date)
				return DBInfo(version: versionNumber, lastModified: timestamp)
			}
	}
	
	
	enum DatabaseError: LocalizedError {
		case foreignKeyViolation(table: String)
		case invalidDateFormat(date: DatabaseDateComponents)
		
		var errorDescription: String? {
			switch self {
				case .foreignKeyViolation(let table):
					return "Foreign key contraint violation in \"\(table)\""
				case .invalidDateFormat(let date):
					return "Invalid date format for \"\(date)\""
			}
		}
	}
	
}
