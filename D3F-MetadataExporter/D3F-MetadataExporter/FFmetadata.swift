//
//  FFmetadata.swift
//  D3F-MetadataExporter
//
//  Created by YourMJK on 06.04.21.
//  Copyright © 2021 YourMJK. All rights reserved.
//

import Foundation


struct FFmetadata {
	let title: String?
	let album: String?
	let artist: String?
	let album_artist: String?
	let composer: String?
	let description: String?
	let genre: String?
	let date: DateComponents?
	let track: (number: UInt, total: UInt?)?
	let chapters: [Chapter]?
}


extension FFmetadata {
	struct Chapter {
		let timebase: UInt
		let start: Int
		let end: Int
		let title: String
	}
}


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
		if let chapters = chapters {
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
