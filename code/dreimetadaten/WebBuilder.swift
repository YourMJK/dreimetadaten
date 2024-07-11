//
//  WebBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.04.24.
//

import Foundation


class WebBuilder {
	let objectModel: MetadataObjectModel
	let collectionType: CollectionType
	var content: String
	let host: String
	
	init(objectModel: MetadataObjectModel, collectionType: CollectionType, templateContent: String, host: String) {
		self.objectModel = objectModel
		self.collectionType = collectionType
		self.content = templateContent
		self.host = host
	}
	
	
	func build() throws {
		try replaceTableRowPlaceholder()
		try replaceDatePlaceholder()
	}
	
	
	private func replaceTableRowPlaceholder() throws {
		let placeholder = "%%table_rows%%"
		var tableRowsString = ""
		
		enum CellType: String {
			case th = "th"
			case td = "td"
		}
		enum CellClass: String {
			case nr = "cell_nr"
			case data = "cell_data"
			case icon = "cell_icon"
		}
		func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, _ lines: [(text: String, link: String?)]) {
			guard width != 0 else { return }
			
			var cell = "<\(type.rawValue)"
			if let cellClass {
				cell.append(" class=\"\(cellClass.rawValue)\"")
			}
			if let width {
				cell.append(" colspan=\"\(width)\"")
			}
			cell.append(">")
			
			var first = true
			for line in lines {
				if !first {
					cell.append("<br>")
				}
				first = false
				if let link = line.link {
					cell.append("<a href=\"\(link)\">")
					cell.append(line.text)
					cell.append("</a>")
				}
				else {
					cell.append(line.text)
				}
			}
			
			cell.append("</td>")
			tableRowsString.append("\n\t")
			tableRowsString.append(cell)
		}
		func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, content: String) {
			addCell(type: type, class: cellClass, width: width, [(content, nil)])
		}
		func addEmptyCell(count: UInt = 1) {
			for _ in 1...count {
				addCell([])
			}
		}
		func startRow(incomplete: Bool) {
			tableRowsString.append("\n<tr")
			if incomplete { tableRowsString.append(" class=\"row_incomplete\"") }
			tableRowsString.append(">")
		}
		func endRow() {
			tableRowsString.append("\n</tr>")
		}
		
		
		// Collection
		guard var collection = objectModel[keyPath: collectionType.objectModelKeyPath] as? [MetadataObjectModel.Hörspiel] else {
			throw BuildingError.missingCollectionData(collectionType: collectionType)
		}
		
		// Check optional links
		typealias LinkKeyPath = KeyPath<MetadataObjectModel.Links, String?>
		let optionalLinks: [LinkKeyPath] = [
			\.cover,
			\.cover_itunes,
			\.cover_kosmos,
			\.dreifragezeichen,
			\.appleMusic,
			\.spotify
		]
		var hasLink: [LinkKeyPath: Bool] = [:]
		for keyPath in optionalLinks {
			hasLink[keyPath] = collection.contains { $0.links?[keyPath: keyPath] != nil }
		}
		func countLinks(_ links: [LinkKeyPath]) -> UInt {
			links
				.map { hasLink[$0]! ? 1 : 0 }
				.reduce(0, +)
		}
		
		// Headers
		let headerCoverWidth: UInt = countLinks([\.cover, \.cover_itunes, \.cover_kosmos])
		let headerPlattformWidth: UInt = countLinks([\.dreifragezeichen, \.appleMusic, \.spotify])
		let headerNr = "Nr."
		let headerTitel = "Titel"
		switch collectionType {
			case .serie:
				collection.reverse()
				addCell(type: .th, content: headerNr)
			case .spezial:
				addCell(type: .th, content: headerTitel)
			case .kurzgeschichten:
				addCell(type: .th, content: "Sammlung")
				addCell(type: .th, content: headerTitel)
			case .die_dr3i:
				addCell(type: .th, content: headerNr)
				addCell(type: .th, content: headerTitel)
		}
		addCell(type: .th, width: 2, content: "Metadaten")
		addCell(type: .th, content: "Rip")
		addCell(type: .th, width: headerCoverWidth, content: "Cover")
		addCell(type: .th, width: headerPlattformWidth, content: "Plattform")
		
		// Content
		let listSymbol = "└╴"
		
		func formatLeadingZeros(max count: Int) -> String {
			var number = count
			var orderOfMagnitude: UInt = 0
			while number != 0 {
				orderOfMagnitude += 1
				number /= 10
			}
			return "%0\(orderOfMagnitude)d"
		}
		func nameForFolge(_ folge: MetadataObjectModel.Folge) -> String {
			guard folge.nummer >= 0 else { return "" }
			return String(format: collectionType.nummerFormat ?? "", folge.nummer)
		}
		func nameForTeil(_ teil: MetadataObjectModel.Teil, count: Int) -> String {
			return "\(listSymbol)\(teil.buchstabe ?? String(format: formatLeadingZeros(max: count), teil.teilNummer))"
		}
		func relativePathForLink(_ link: String) throws -> String {
			guard let url = URL(string: link) else {
				throw BuildingError.invalidURL(string: link)
			}
			if url.host == host {
				return String(url.relativePath.dropFirst())
			}
			return link
		}
		
		func addRowFor(hörspiel: MetadataObjectModel.Hörspiel, collectionCount: Int) throws {
			startRow(incomplete: hörspiel.unvollständig ?? false)
			
			// First one (or two) identifying cell(s)
			switch collectionType {
				case .serie:
					if let folge = hörspiel as? MetadataObjectModel.Folge {
						addCell(class: .nr, content: nameForFolge(folge))
						//addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else if let teil = hörspiel as? MetadataObjectModel.Teil {
						addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
					
				case .spezial:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
						addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
					else {
						addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					
				case .kurzgeschichten:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
						addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
						addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else {
						addCell(class: .nr, content: hörspiel.titel ?? "")
						addEmptyCell()
					}
				
				case .die_dr3i:
					if let folge = hörspiel as? MetadataObjectModel.Folge {
						addCell(class: .nr, content: nameForFolge(folge))
						addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else if let teil = hörspiel as? MetadataObjectModel.Teil {
						addEmptyCell()
						addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
			}
			
			// Links
			func addLinks(_ links: [(String, String?)], cellClass: CellClass = .data) throws {
				let lines: [(text: String, link: String?)] = try links.compactMap { (name, link) in
					guard let link else { return nil }
					return (name, try relativePathForLink(link))
				}
				addCell(class: cellClass, lines)
			}
			func addLinks(_ links: [(String, LinkKeyPath)], cellClass: CellClass = .data) throws {
				try addLinks(links.map { (name, keyPath) in
					(name, hörspiel.links?[keyPath: keyPath])
				}, cellClass: cellClass)
			}
			func addOptionalLink(_ name: String, _ keyPath: LinkKeyPath, cellClass: CellClass = .data) throws {
				guard hasLink[keyPath]! else { return }
				try addLinks([(name, keyPath)], cellClass: cellClass)
			}
			func addOptionalLinkIcon(_ filename: String, _ keyPath: LinkKeyPath) throws {
				try addOptionalLink("<img src=\"icons/\(filename)\">", keyPath, cellClass: .icon)
			}
			// Metadaten
			try addLinks([("JSON", \.json)])
			try addLinks([("FFmetadata", \.ffmetadata)])
			// Rip Log
			let ripLogs = hörspiel.medien?.map(\.ripLog) ?? []
			let multipleRipLogs = ripLogs.count > 1
			try addLinks(ripLogs.enumerated().map { (index, ripLog) in
				("CD\(multipleRipLogs ? String(index+1) : "")", ripLog)
			})
			// Cover
			try addOptionalLink("dreimetadaten", \.cover)
			try addOptionalLink("iTunes", \.cover_itunes)
			try addOptionalLink("Kosmos", \.cover_kosmos)
			// Plattform
			try addOptionalLinkIcon("ddf_link.svg", \.dreifragezeichen)
			try addOptionalLinkIcon("am_link.svg", \.appleMusic)
			try addOptionalLinkIcon("spotify_link.svg", \.spotify)
			
			endRow()
		}
		
		func recursive(_ hörspiel: MetadataObjectModel.Hörspiel, collectionCount: Int) throws {
			try addRowFor(hörspiel: hörspiel, collectionCount: collectionCount)
			try hörspiel.teile?.forEach { try recursive($0, collectionCount: hörspiel.teile?.count ?? 0) }
		}
		try collection.forEach { try recursive($0, collectionCount: collection.count) }
		
		try replace(placeholder: placeholder, with: tableRowsString)
	}
	
	private func replaceDatePlaceholder() throws {
		let placeholder = "%%date%%"
		
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd.MM.yyyy"
		let dateString = dateFormatter.string(from: date)
		
		try replace(placeholder: placeholder, with: dateString)
	}
	
	private func replace(placeholder: String, with replacement: String) throws {
		guard content.contains(placeholder) else {
			throw BuildingError.missingPlaceholderInTemplate(placeholder: placeholder)
		}
		content = content.replacingOccurrences(of: placeholder, with: replacement)  // despite copy overhead, 10x faster than range(of:) + mutating replaceSubrange()
	}
	
}


extension WebBuilder {
	enum BuildingError: LocalizedError {
		case invalidURL(string: String)
		case missingCollectionData(collectionType: CollectionType)
		case missingPlaceholderInTemplate(placeholder: String)
		
		var errorDescription: String? {
			switch self {
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
				case .missingCollectionData(let collectionType):
					return "Given dataset doesn't contain any data for the selected collection type \"\(collectionType)\""
				case .missingPlaceholderInTemplate(let placeholder):
					return "Content of given template file doesn't contain the placeholder \"\(placeholder)\""
			}
		}
	}
}
