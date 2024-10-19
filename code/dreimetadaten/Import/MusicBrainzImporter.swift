//
//  MusicBrainzImporter.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.10.24.
//

import Foundation
import GRDB


struct MusicBrainzImporter {
	let db: Database
	
	
	func addMedium(to hörspielID: MetadataRelationalModel.Hörspiel.ID, at position: UInt, usingDisc discID: String) throws {
		func nextID<T: PersistableFetchableTableRecord, I: BinaryInteger>(of: T.Type, id transform: (T) -> I) throws -> I {
			try T.fetchAll(db).map(transform).max()! + 1
		}
		
		// Medium
		let mediumID = try nextID(of: MetadataRelationalModel.Medium.self, id: \.mediumID)
		try MetadataRelationalModel.Medium(
			mediumID: mediumID,
			hörspielID: hörspielID,
			position: position,
			ripLog: false,
			musicBrainzID: discID
		).insert(db)
		
		// Tracks
		let chapters = try Self.chaptersFromTracks(discID: discID, mediaPosition: position)
		let baseTrackID = try nextID(of: MetadataRelationalModel.Track.self, id: \.trackID)
		let baseKapitelPosition = (try UInt.fetchOne(db, sql: "SELECT MAX(position) FROM kapitel WHERE hörspielID = \(hörspielID)") ?? 0) + 1
		for (index, chapter) in chapters.enumerated() {
			let index = UInt(index)
			let trackID = baseTrackID + index
			try MetadataRelationalModel.Track(
				trackID: trackID,
				mediumID: mediumID,
				position: index+1,
				titel: chapter.title,
				dauer: chapter.duration
			).insert(db)
			try MetadataRelationalModel.Kapitel(
				trackID: trackID,
				hörspielID: hörspielID,
				position: baseKapitelPosition + index
			).insert(db)
		}
	}
	
	
	typealias Chapter = (title: String, duration: UInt)
	
	private static func chaptersFromTracks(discID: String, mediaPosition: UInt) throws -> [Chapter] {
		// Get disc data
		guard let disc = try synchronousJSONRequest(to: "https://musicbrainz.org/ws/2/discid/\(discID)?fmt=json") as? [String: Any] else {
			throw ImportError.jsonParsingFailed(errorMsg: "Disc top level not a dictionary")
		}
		guard let discRelease = (disc["releases"] as? [[String: Any]])?.first else {
			throw ImportError.jsonParsingFailed(errorMsg: "Release object not found")
		}
		guard let sectorOffsets = disc["offsets"] as? [Int], let sectorCount = disc["sectors"] as? Int else {
			throw ImportError.jsonParsingFailed(errorMsg: "Sector data not found")
		}
		guard let releaseID = discRelease["id"] as? String else {
			throw ImportError.jsonParsingFailed(errorMsg: "Release ID not found")
		}
		
		// Get release data
		guard let release = try synchronousJSONRequest(to: "https://musicbrainz.org/ws/2/release/\(releaseID)?inc=recordings&fmt=json") as? [String: Any] else {
			throw ImportError.jsonParsingFailed(errorMsg: "Release top level not a dictionary")
		}
		guard let media = (release["media"] as? [[String: Any]]) else {
			throw ImportError.jsonParsingFailed(errorMsg: "Media not found")
		}
		let medium = try media.first {
			guard let position = $0["position"] as? UInt else {
				throw ImportError.jsonParsingFailed(errorMsg: "Media position not found")
			}
			return position == mediaPosition
		}
		guard let medium else {
			throw ImportError.mediaPositionNotFound(position: mediaPosition, count: UInt(media.count))
		}
		guard let tracks = medium["tracks"] as? [[String: Any]] else {
			throw ImportError.jsonParsingFailed(errorMsg: "Tracks not found")
		}
		
		// Generate chapters
		var previousPosition = 0
		var chapters: [Chapter] = try tracks.map { track in
			guard let position = track["position"] as? Int else {
				throw ImportError.jsonParsingFailed(errorMsg: "Track position not found")
			}
			let expectedPosition = previousPosition + 1
			guard position == expectedPosition else {
				throw ImportError.unexpectedTrackSequence(expected: expectedPosition, actual: position)
			}
			previousPosition = expectedPosition
			
			guard let trackTitle = (track["title"] as? String)?.trimmingCharacters(in: .whitespaces) else {
				throw ImportError.jsonParsingFailed(errorMsg: "Track title not found")
			}
			return (trackTitle, 0)
		}
		
		guard chapters.count == sectorOffsets.count else {
			throw ImportError.trackAndOffsetCountDiffer(tracks: UInt(chapters.count), offsets: UInt(sectorOffsets.count))
		}
		guard chapters.count > 0 else {
			throw ImportError.zeroTracks
		}
		
		let startOffset = sectorOffsets.first!
		let timestamps: [UInt] = try (sectorOffsets + [sectorCount]).map {
			let sectors = $0 - startOffset
			let samples = sectors * 2352 / 4  // sectorSize=2352B ; sampleSize=2*16bit=4B
			let milliseconds = Int((Double(samples) / 44.1).rounded())  // sampleRate=44.1kHz
			guard milliseconds >= 0 else {
				throw ImportError.negativeTimestamp(timestamp: milliseconds)
			}
			return UInt(milliseconds)
		}
		for (i, (start, end)) in zip(timestamps.dropLast(), timestamps.dropFirst()).enumerated() {
			chapters[i].duration = end-start
		}
		
		return chapters
	}
	
	
	private static func synchronousJSONRequest(to urlString: String) throws -> Any {
		guard let url = URL(string: urlString) else {
			throw ImportError.invalidURL(urlString: urlString)
		}
		var result: Any?
		var errorToThrow: Error?
		let semphore = DispatchSemaphore(value: 0)
		let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
			defer {
				semphore.signal()
			}
			if let error = error {
				errorToThrow = ImportError.requestFailed(errorMsg: error.localizedDescription)
				return
			}
			guard let data = data else {
				errorToThrow = ImportError.requestFailed(errorMsg: "No data")
				return
			}
			let httpResponse = response as! HTTPURLResponse
			guard httpResponse.statusCode == 200 else {
				errorToThrow = ImportError.requestFailed(errorMsg: "\(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "(nil)")")
				return
			}
			
			do {
				result = try JSONSerialization.jsonObject(with: data, options: [])
			}
			catch(let parseError) {
				errorToThrow = ImportError.jsonParsingFailed(errorMsg: parseError.localizedDescription)
				return
			}
		}
		task.resume()
		semphore.wait()
		
		if let error = errorToThrow {
			throw error
		}
		return result!
	}
	
	
	enum ImportError: LocalizedError {
		case invalidURL(urlString: String)
		case requestFailed(errorMsg: String)
		case jsonParsingFailed(errorMsg: String)
		case mediaPositionNotFound(position: UInt, count: UInt)
		case unexpectedTrackSequence(expected: Int, actual: Int)
		case trackAndOffsetCountDiffer(tracks: UInt, offsets: UInt)
		case zeroTracks
		case negativeTimestamp(timestamp: Int)
		
		var errorDescription: String {
			switch self {
				case .invalidURL(let urlString): return "Invalid URL:  \(urlString)"
				case .requestFailed(let errorMsg): return "Request to MusicBrainz failed:  \(errorMsg)"
				case .jsonParsingFailed(let errorMsg): return "Parsing MusicBrainz JSON response failed:  \(errorMsg)"
				case .mediaPositionNotFound(let position, let count): return "Medium with position \(position) not found in release, number of media is \(count)"
				case .unexpectedTrackSequence(let expected, let actual): return "Expected next track position to be \(expected) but was \(actual)"
				case .trackAndOffsetCountDiffer(let tracks, let offsets): return "Number of tracks (\(tracks) and number of offsets (\(offsets) don't match"
				case .zeroTracks: return "No tracks were found"
				case .negativeTimestamp(let timestamp): return "Negative timestamp (\(timestamp) after conversion"
			}
		}
	}
}
