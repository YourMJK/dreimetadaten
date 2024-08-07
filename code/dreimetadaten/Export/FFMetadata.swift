//
//  FFmetadata.swift
//  dreimetadaten
//
//  Created by YourMJK on 09.04.24.
//

import Foundation


struct FFmetadata {
	var title: String?
	var album: String?
	var artist: String?
	var album_artist: String?
	var composer: String?
	var description: String?
	var genre: String?
	var date: DateComponents?
	var track: (number: UInt, total: UInt?)?
	var chapters: [Chapter]?
}


extension FFmetadata {
	struct Chapter {
		let timebase: UInt
		let start: Int
		let end: Int
		let title: String
	}
}


// MARK: - Formatting

extension FFmetadata {
	var formattedContent: String {
		var lines = [";FFMETADATA1"]
		
		func addTag(key: String, value: String?, escape: Bool = true) {
			guard var value = value else { return }
			if escape {
				// Place a "\\" before every ["=", ";", "#", "\\", "\n"]
				value = value.replacingOccurrences(of: "([=;#\\\\\n])", with: "\\\\$1", options: .regularExpression)
			}
			lines.append("\(key)=\(value)")
		}
		func addLine(_ line: String = "") {
			lines.append(line)
		}
		
		addTag(key: "title", value: title)
		addTag(key: "album", value: album)
		addTag(key: "artist", value: artist)
		addTag(key: "album_artist", value: album_artist)
		addTag(key: "composer", value: composer)
		addTag(key: "description", value: description)
		addTag(key: "genre", value: genre)
		
		// Produce a "yyyy", "yyyy-MM" or "yyyy-MM-dd" date string
		var dateString: String?
		if let year = date?.year {
			dateString = String(format: "%04d", year)
			[date!.month, date!.day].prefix { $0 != nil }.forEach {
				dateString!.append(String(format: "-%02d", $0!))
			}
		}
		addTag(key: "date", value: dateString, escape: false)
		
		// Produce a "num" or "num/tot" track string
		var trackString: String?
		if let track = track {
			trackString = "\(track.number)"
			if let total = track.total {
				trackString!.append("/\(total)")
			}
		}
		addTag(key: "track", value: trackString, escape: false)
		
		// Add chapters
		if let chapters = chapters, chapters.count > 1 {
			addLine()
			for chapter in chapters {
				addLine("[CHAPTER]")
				addTag(key: "TIMEBASE", value: "1/\(chapter.timebase)", escape: false)
				addTag(key: "START", value: "\(chapter.start)", escape: false)
				addTag(key: "END", value: "\(chapter.end)", escape: false)
				addTag(key: "title", value: "\(chapter.title)")
			}
		}
		
		// Add trailing newline
		addLine()
		
		return lines.joined(separator: "\n")
	}
}


// MARK: - Creation

extension FFmetadata {
	private init(withBasicTagsFrom hörspiel: MetadataObjectModel.Hörspiel) {
		// First sprecher as artist
		let artist: String? = {
			if let firstSprechrolle = hörspiel.sprechrollen?.first {
				return firstSprechrolle.sprecher
			}
			return nil
		}()
		
		// Kurzbeschreibung + beschreibung as description, or metabeschreibung if both are nil
		let descriptionComponents = [hörspiel.kurzbeschreibung, hörspiel.beschreibung].compactMap { $0 }
		let description = descriptionComponents.isEmpty ? hörspiel.metabeschreibung : descriptionComponents.joined(separator: "\n")
		
		// Veröffentlichungsdatum as date, assuming yyyy-MM-dd format
		let date: DateComponents? = {
			guard let stringComponents = hörspiel.veröffentlichungsdatum?.split(separator: "-") else {
				return nil
			}
			func component(_ index: Int) -> Int {
				Int(stringComponents[index])!
			}
			return DateComponents(year: component(0), month: component(1), day: component(2))
		}()
		
		// Kapitel as chapters, assuming times in milliseconds. Chapters are nil if any Kapitel is missing a start or end time
		let chapters: [Chapter]? = {
			guard let kapitels = hörspiel.kapitel, !kapitels.isEmpty else {
				return nil
			}
			var chapters = [Chapter]()
			for kapitel in kapitels {
				guard let start = kapitel.start, let end = kapitel.end else {
					return nil
				}
				chapters.append(Chapter(timebase: 1000, start: start, end: end, title: kapitel.titel))
			}
			return chapters
		}()
		
		self.init(
			title: hörspiel.titel,
			album: nil,
			artist: artist,
			album_artist: hörspiel.hörspielskriptautor,
			composer: hörspiel.autor,
			description: description,
			genre: "Krimi",
			date: date,
			track: nil,
			chapters: chapters
		)
	}
	
	
	/// Create the FFmetadata for a collection item of type `type` with `Self.init(withBasicTagsFrom:)` and using the type's specific `titlePrefix` (e.g. "Die drei ???") and `nummerFormat` (e.g. "Nr. %03d") to form a title.
	static func create(forCollectionItem hörspiel: MetadataObjectModel.Hörspiel, type: CollectionType) -> Self {
		create(forCollectionItem: hörspiel, titlePrefix: type.titlePrefix, nummerFormat: type.titleNummerFormat)
	}
	
	/// Create the FFmetadata for a generic collection item with `Self.init(withBasicTagsFrom:)` and using the specified `titlePrefix` (e.g. "Die drei ???") and `nummerFormat` (e.g. "Nr. %03d") to form a title.
	static func create(forCollectionItem hörspiel: MetadataObjectModel.Hörspiel, titlePrefix: String, nummerFormat: String?) -> Self {
		// Form title
		let nummerString: String? = {
			guard let folge = hörspiel as? MetadataObjectModel.Folge else {
				return nil
			}
			guard let nummerFormat = nummerFormat else {
				return nil
			}
			return String(format: nummerFormat, folge.nummer)
		}()
		let titleComponents = [titlePrefix, nummerString, "–", hörspiel.titel]
		let title = titleComponents.compactMap { $0 }.joined(separator: " ")  // e.g. "Die drei ??? Nr. XXX – Titel"
		
		// FFmetadata of base
		var ffmetadata = Self(withBasicTagsFrom: hörspiel)
		ffmetadata.title = title
		ffmetadata.album = title
		
		return ffmetadata
	}
	
	/// Create the FFmetadata for an array of Teil which share the same base metadata
	static func create(forTeile teile: [MetadataObjectModel.Teil], ofBase ffmetadataBase: FFmetadata) -> [Self] {
		guard !teile.isEmpty else { return [] }
		let maxTeilNummer = teile.map { $0.teilNummer }.max()!
		
		let ffmetadataTeile: [Self] = teile.map { teil in
			var ffmetadata = Self(withBasicTagsFrom: teil)
			ffmetadata.album = ffmetadataBase.title
			ffmetadata.track = (number: teil.teilNummer, total: maxTeilNummer)
			
			func baseValueAsPlaceholder<T>(_ keyPath: WritableKeyPath<FFmetadata, T?>) {
				ffmetadata[keyPath: keyPath] = ffmetadata[keyPath: keyPath] ?? ffmetadataBase[keyPath: keyPath]
			}
			baseValueAsPlaceholder(\.artist)
			baseValueAsPlaceholder(\.album_artist)
			baseValueAsPlaceholder(\.composer)
			baseValueAsPlaceholder(\.description)
			baseValueAsPlaceholder(\.genre)
			baseValueAsPlaceholder(\.date)
			
			return ffmetadata
		}
		
		return ffmetadataTeile
	}
}
