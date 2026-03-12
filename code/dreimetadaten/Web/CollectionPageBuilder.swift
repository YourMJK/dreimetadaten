//
//  CollectionPageBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.04.24.
//

import Foundation


class CollectionPageBuilder: PageBuilder {
	let objectModel: MetadataObjectModel
	let collectionType: CollectionType
	let host: String
	
	init(objectModel: MetadataObjectModel, collectionType: CollectionType, templateFile: URL, host: String) throws {
		self.objectModel = objectModel
		self.collectionType = collectionType
		self.host = host
		try super.init(templateFile: templateFile)
	}
	
	override func build() throws {
		try super.build()
		try replaceTableRowPlaceholder()
	}
	
	private func replaceTableRowPlaceholder() throws {
		let table = TableBuilder(class: .datatable)
		
		// Collection
		guard var collection = objectModel[keyPath: collectionType.objectModelKeyPath] as? [MetadataObjectModel.Hörspiel] else {
			throw BuildingError.missingCollectionData(collectionType: collectionType)
		}
		
		// Check optional links
		typealias LinkKeyPath = KeyPath<MetadataObjectModel.Links, String?>
		let optionalLinks: [LinkKeyPath] = [
			\.artwork,
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
		table.addRow()
		let hasRipLog = collection.compactMap(\.medien).joined().contains { $0.ripLog != nil }
		let hasArtwork = hasLink[\.artwork]!
		let headerCoverWidth = countLinks([\.cover, \.cover_itunes, \.cover_kosmos])
		let headerPlattformWidth = countLinks([\.dreifragezeichen, \.appleMusic, \.spotify])
		let headerNr = "Nr."
		let headerTitel = "Titel"
		switch collectionType {
			case .serie:
				collection.reverse()
				table.addCell(type: .th, content: headerNr)
			case .spezial:
				table.addCell(type: .th, content: headerTitel)
			case .kurzgeschichten:
				table.addCell(type: .th, content: "Sammlung")
				table.addCell(type: .th, content: headerTitel)
			case .die_dr3i:
				table.addCell(type: .th, content: headerNr)
				table.addCell(type: .th, content: headerTitel)
			case .kids:
				collection.reverse()
				table.addCell(type: .th, content: headerNr)
				table.addCell(type: .th, content: headerTitel)
			default:
				fatalError("Collection type \"\(collectionType)\" not implemented")
		}
		table.addCell(type: .th, width: 2, content: "Metadaten")
		if hasRipLog {
			table.addCell(type: .th, content: "Rip")
		}
		table.addCell(type: .th, width: headerCoverWidth, content: "Cover")
		if hasArtwork {
			table.addCell(type: .th, content: "Artwork")
		}
		table.addCell(type: .th, width: headerPlattformWidth, content: "Plattform")
		
		// Content
		func icon(_ filename: String, title: String) -> HTML.Node {
			HTML.img().src("icons/\(filename)").attribute(key: "title", value: title)
		}
		func iconWithSuffix(icon: HTML.Node, suffix: HTML.Content) -> HTML.Node {
			HTML.span().class("icon_suffix").content {[
				icon,
				suffix
			]}
		}
		let iconDM = icon("dm_link.svg", title: "dreimetadaten")
		let iconDDF = icon("ddf_link.svg", title: "dreifragezeichen.de")
		let iconAM = icon("am_link.svg", title: "Amazon Music")
		let iconSpotify = icon("spotify_link.svg", title: "Spotify")
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
			table.addRow(class: hörspiel.unvollständig == true ? .incomplete : nil)
			
			// First one (or two) identifying cell(s)
			switch collectionType {
				case .serie:
					if let folge = hörspiel as? MetadataObjectModel.Folge {
						table.addCell(class: .nr, content: nameForFolge(folge))
						//table.addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else if let teil = hörspiel as? MetadataObjectModel.Teil {
						table.addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
					
				case .spezial:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
						table.addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
					else {
						table.addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					
				case .kurzgeschichten:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
						table.addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
						table.addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else {
						table.addCell(class: .nr, content: hörspiel.titel ?? "")
						table.addEmptyCell()
					}
				
				case .die_dr3i, .kids:
					if let folge = hörspiel as? MetadataObjectModel.Folge {
						table.addCell(class: .nr, content: nameForFolge(folge))
						table.addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					else if let teil = hörspiel as? MetadataObjectModel.Teil {
						table.addEmptyCell()
						table.addCell(class: .nr, content: nameForTeil(teil, count: collectionCount))
					}
					else {
						table.addEmptyCell()
						table.addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					
				default:
					fatalError("Collection type \"\(collectionType)\" not implemented")
			}
			
			// Links
			func addLinks(_ links: [(HTML.Content, String?)], cellClass: TableBuilder.CellClass = .data) throws {
				let lines: [HTML.Node] = try links.compactMap { (content, link) in
					guard let link else { return nil }
					return HTML.a().href(try relativePathForLink(link)).content { content }
				}
				table.addCell(class: cellClass, lines: lines)
			}
			func addLinks(_ links: [(HTML.Content, LinkKeyPath)], cellClass: TableBuilder.CellClass = .data) throws {
				try addLinks(links.map { (content, keyPath) in
					(content, hörspiel.links?[keyPath: keyPath])
				}, cellClass: cellClass)
			}
			func addOptionalLink(_ content: HTML.Content, _ keyPath: LinkKeyPath, cellClass: TableBuilder.CellClass = .data) throws {
				guard hasLink[keyPath]! else { return }
				try addLinks([(content, keyPath)], cellClass: cellClass)
			}
			func addOptionalIconLink(_ node: HTML.Node, _ keyPath: LinkKeyPath) throws {
				try addOptionalLink(node, keyPath, cellClass: .icon)
			}
			func addOptionalLinks(
				primary: (content: HTML.Content, keyPath: LinkKeyPath),
				secondary: (content: (UInt) -> HTML.Content, keyPath: KeyPath<MetadataObjectModel.Links, [String]?>),
				cellClass: TableBuilder.CellClass = .data
			) throws {
				guard hasLink[primary.keyPath]! else { return }
				var links: [(HTML.Content, String?)] = [(primary.content, hörspiel.links?[keyPath: primary.keyPath])]
				hörspiel.links?[keyPath: secondary.keyPath]?.enumerated().forEach { (index, link) in
					links.append((secondary.content(UInt(index+2)), link))
				}
				try addLinks(links, cellClass: cellClass)
			}
			// Metadaten
			try addLinks([("JSON", \.json)])
			try addLinks([("FFmetadata", \.ffmetadata)])
			// Rip Log
			if hasRipLog {
				let ripLogs = hörspiel.medien?.map(\.ripLog) ?? []
				let multipleRipLogs = ripLogs.count > 1
				try addLinks(ripLogs.enumerated().map { (index, ripLog) in
					("CD\(multipleRipLogs ? String(index+1) : "")", ripLog)
				})
			}
			// Cover
			try addOptionalLinks(
				primary: (iconDM, \.cover),
				secondary: ({ iconWithSuffix(icon: iconDM, suffix: "\($0)") }, \.cover2),
				cellClass: .icon
			)
			try addOptionalLink("iTunes", \.cover_itunes)
			try addOptionalLink("Kosmos", \.cover_kosmos)
			// Artwork
			try addOptionalLinks(
				primary: (iconDM, \.artwork),
				secondary: ({ iconWithSuffix(icon: iconDM, suffix: "\($0)") }, \.artwork2),
				cellClass: .icon
			)
			// Plattform
			try addOptionalIconLink(iconDDF, \.dreifragezeichen)
			try addOptionalIconLink(iconAM, \.appleMusic)
			try addOptionalIconLink(iconSpotify, \.spotify)
		}
		
		func recursive(_ hörspiel: MetadataObjectModel.Hörspiel, collectionCount: Int) throws {
			try addRowFor(hörspiel: hörspiel, collectionCount: collectionCount)
			try hörspiel.teile?.forEach { try recursive($0, collectionCount: hörspiel.teile?.count ?? 0) }
		}
		try collection.forEach { try recursive($0, collectionCount: collection.count) }
		
		let content = table.serialize()
		try replace(placeholder: "%%table%%", with: content)
	}
	
}


extension CollectionPageBuilder {
	enum BuildingError: LocalizedError {
		case invalidURL(string: String)
		case missingCollectionData(collectionType: CollectionType)
		
		var errorDescription: String? {
			switch self {
				case .invalidURL(let string):
					return "Invalid URL \"\(string)\""
				case .missingCollectionData(let collectionType):
					return "Given dataset doesn't contain any data for the selected collection type \"\(collectionType)\""
			}
		}
	}
}
