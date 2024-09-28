//
//  Importer.swift
//  dreimetadaten
//
//  Created by YourMJK on 13.09.24.
//

import Foundation
import CommandLineTool
import GRDB
import CodableCSV


struct Importer {
	let db: Database
	
	func importData(from jsonFile: URL) throws {
		// Decode JSON file
		let model = try readJSON(file: jsonFile)
		
		// Insert "Ulf Blanck"
		let skriptautor = MetadataRelationalModel.Person(
			personID: try nextID(of: MetadataRelationalModel.Person.self, id: \.personID),
			name: "Ulf Blanck"
		)
		try skriptautor.insert(db)
		// Insert "Boris Pfeiffer"
		try MetadataRelationalModel.Person(
			personID: try nextID(of: MetadataRelationalModel.Person.self, id: \.personID),
			name: "Boris Pfeiffer"
		).insert(db)
		
		// Read data
		for index in model.indices {
			let item = model[index]
			
			stderr("> \(item.nummer)")
			
			// Hörspiel
			let hörspielID = try nextID(of: MetadataRelationalModel.Hörspiel.self, id: \.hörspielID)
			let hörspiel = MetadataRelationalModel.Hörspiel(
				hörspielID: hörspielID,
				titel: item.titel,
				kurzbeschreibung: item.kurzbeschreibung,
				beschreibung: item.beschreibung,
				metabeschreibung: nil,
				veröffentlichungsdatum: try Migrator.dateComponents(from: item.veroeffentlichungsdatum),
				unvollständig: false,
				cover: 0,
				urlCoverApple: nil,
				urlCoverKosmos: nil,
				urlDreifragezeichen: item.dreifragezeichen,
				urlAppleMusic: "https://music.apple.com/de/album/\(item.appleMusicID)",
				urlSpotify: nil,
				urlBookbeat: nil
			)
			try hörspiel.insert(db)
			try MetadataRelationalModel.KidsFolge(nummer: item.nummer, hörspielID: hörspielID).insert(db)
			
			// Sprechrolle
			let baseSprechrolleID = try nextID(of: MetadataRelationalModel.Sprechrolle.self, id: \.sprechrolleID)
			for (index, sprechrolleObject) in item.sprechrollen.enumerated() {
				let index = UInt(index)
				let sprechrolleID = baseSprechrolleID + index
				
				// Rolle
				let rolle = try MetadataRelationalModel.Rolle
					.filter(Column("name") == sprechrolleObject.rolle)
					.fetchOne(db)
				let rolleID = try rolle?.rolleID ?? {
					let rolleID = try nextID(of: MetadataRelationalModel.Rolle.self, id: \.rolleID)
					try MetadataRelationalModel.Rolle(rolleID: rolleID, name: sprechrolleObject.rolle).insert(db)
					return rolleID
				}()
				
				// Sprechrolle
				try MetadataRelationalModel.Sprechrolle(
					sprechrolleID: sprechrolleID,
					hörspielID: hörspielID,
					rolleID: rolleID,
					position: index+1
				).insert(db)
				
				// Sprecher
				for (sprecherIndex, sprecherName) in sprechrolleObject.sprecher.components(separatedBy: ", ").enumerated() {
					let person = try MetadataRelationalModel.Person
						.filter(Column("name") == sprecherName)
						.fetchOne(db)
					let personID = try person?.personID ?? {
						let personID = try nextID(of: MetadataRelationalModel.Person.self, id: \.personID)
						try MetadataRelationalModel.Person(personID: personID, name: sprecherName).insert(db)
						return personID
					}()
					
					// Spricht
					try MetadataRelationalModel.Spricht(sprechrolleID: sprechrolleID, personID: personID, position: UInt(sprecherIndex + 1)).insert(db)
				}
			}
			
			// Buchautor
			for autorName in item.autor.components(separatedBy: ", ") {
				let buchautor = try MetadataRelationalModel.Person
					.filter(Column("name") == autorName)
					.fetchOne(db)
				guard let buchautor else {
					fatalError("Unknown person \"\(item.autor)\"")
				}
				try MetadataRelationalModel.HörspielBuchautor(hörspielID: hörspielID, personID: buchautor.personID).insert(db)
			}
			
			// Skriptautor
			try MetadataRelationalModel.HörspielSkriptautor(hörspielID: hörspielID, personID: skriptautor.personID).insert(db)
			
			
			
			// MusicBrainz
			if let discID = item.musicBrainzID {
				// Medium
				let mediumID = try nextID(of: MetadataRelationalModel.Medium.self, id: \.mediumID)
				try MetadataRelationalModel.Medium(
					mediumID: mediumID,
					hörspielID: hörspielID,
					position: 1,
					ripLog: false,
					musicBrainzID: discID
				).insert(db)
				
				// Tracks
				let kapitels = try Self.musicBrainzKapitel(nummer: item.nummer, discID: discID)
				let baseTrackID = try nextID(of: MetadataRelationalModel.Track.self, id: \.trackID)
				for (index, kapitel) in kapitels.enumerated() {
					let index = UInt(index)
					let trackID = baseTrackID + index
					try MetadataRelationalModel.Track(
						trackID: trackID,
						mediumID: mediumID,
						position: index+1,
						titel: kapitel.titel,
						dauer: kapitel.dauer
					).insert(db)
					try MetadataRelationalModel.Kapitel(
						trackID: trackID,
						hörspielID: hörspielID,
						position: index+1
					).insert(db)
				}
			}
		}
		
	}
	
	func readJSON(file jsonFile: URL) throws -> Model {
		do {
			let jsonData = try Data(contentsOf: jsonFile)
			let jsonDecoder = JSONDecoder()
			let model = try jsonDecoder.decode(Model.self, from: jsonData)
			return model
		}
		catch {
			throw ImportError.decodingError(error: error)
		}
	}
	
	func nextID<T: PersistableFetchableTableRecord, I: BinaryInteger>(of: T.Type, id transform: (T) -> I) throws -> I {
		try T.fetchAll(db).map(transform).max()! + 1
	}
	
}


extension Importer {
	typealias Model = [ModelItem]
	
	struct ModelItem: Codable {
		var nummer: UInt
		var titel: String
		var autor: String
		var kurzbeschreibung: String?
		var beschreibung: String
		var veroeffentlichungsdatum: String
		var sprechrollen: [MetadataObjectModel.Sprechrolle]
		var dreifragezeichen: String?
		var musicBrainzID: String?
		var appleMusicID: String
	}
}


extension Importer {
	enum ImportError: LocalizedError {
		case decodingError(error: Error)
		
		var errorDescription: String? {
			switch self {
				case .decodingError(let error):
					return "Couldn't decode JSON: \(error.localizedDescription)"
			}
		}
	}
}


extension Importer {
	typealias Kapitel = (titel: String, dauer: UInt)
	
	static func musicBrainzKapitel(nummer: UInt, discID: String) throws -> [Kapitel] {
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
		if let nummerEndIndex = title.firstIndex(of: ":"), let nummerIdentifierIndex = title[..<nummerEndIndex].lastIndex(of: " ") {
			let nummerStartIndex = title.index(after: nummerIdentifierIndex)
			let nummerString = title[nummerStartIndex..<nummerEndIndex]
			if let parsedNummer = UInt(nummerString) {
				if parsedNummer != nummer {
					stderr("Parsed nummer differs from expected (\(parsedNummer) vs. \(nummer))")
				}
			}
			else {
				stderr("Title has non-standard format: \"\(title)\"")
			}
		}
		else {
			stderr("Title has non-standard format: \"\(title)\"")
		}
		
		// Generate chapters
		var previousPosition = 0
		var kapitels: [Kapitel] = try tracks.map { track in
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
			guard let trackLength = track["length"] as? UInt else {
				throw MBDiscIDListParseError.jsonParsingFailed(errorMsg: "Track length not found")
			}
			return (trackTitle, trackLength)
		}
		
		guard kapitels.count == sectorOffsets.count else {
			throw MBDiscIDListParseError.trackAndOffsetCountDiffer(tracks: UInt(kapitels.count), offsets: UInt(sectorOffsets.count))
		}
		guard kapitels.count > 0 else {
			throw MBDiscIDListParseError.zeroTracks
		}
		
		let startOffset = sectorOffsets.first!
		let timestamps: [UInt] = try (sectorOffsets + [sectorCount]).map { 
			let sectors = $0 - startOffset
			let samples = sectors * 2352 / 4  // sectorSize=2352B ; sampleSize=2*16bit=4B
			let milliseconds = Int((Double(samples) / 44.1).rounded())  // sampleRate=44.1kHz
			guard milliseconds >= 0 else {
				throw MBDiscIDListParseError.negativeTimestamp(timestamp: milliseconds)
			}
			return UInt(milliseconds)
		}
		for (i, (start, end)) in zip(timestamps.dropLast(), timestamps.dropFirst()).enumerated() {
			let kapitel = kapitels[i]
			let trackLength = kapitel.dauer
			let calcLength = end-start
//			if calcLength != trackLength {
//				stderr("Calculated track length differs (\(calcLength) vs. \(trackLength)) for \"\(kapitel.titel)\"")
//			}
			
			let nonLetterTitle = kapitel.titel.contains { char in
				!char.isLetter && !char.isWhitespace
			}
			if nonLetterTitle {
				stderr("Track title containing non-letter: \"\(kapitel.titel)\"")
			}
			
			kapitels[i].dauer = calcLength
		}
		
		return kapitels
	}
	
	enum MBDiscIDListParseError: LocalizedError {
		case invalidURL(urlString: String)
		case requestFailed(errorMsg: String)
		case jsonParsingFailed(errorMsg: String)
		case invalidTitleFormat
		case unexpectedTrackSequence(expected: Int, actual: Int)
		case trackAndOffsetCountDiffer(tracks: UInt, offsets: UInt)
		case zeroTracks
		case negativeTimestamp(timestamp: Int)
		
		var errorDescription: String {
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
}
