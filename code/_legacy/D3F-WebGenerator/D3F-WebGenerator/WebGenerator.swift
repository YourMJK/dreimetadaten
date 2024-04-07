//
//  WebGenerator.swift
//  D3F-WebGenerator
//
//  Created by YourMJK on 26.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


class WebGenerator {
	
	let metadata: Metadata
	var content: String
	
	
	convenience init(withMasterFile metadataFile: URL, templateFile: URL) {
		do {
			let templateContent = try String(contentsOf: templateFile, encoding: .utf8)
			self.init(metadata: Self.parseJSON(url: metadataFile), templateContent: templateContent)
		}
		catch {
			exit(error: "Couldn't read template file \"\(templateFile.path)\":  \(error.localizedDescription)")
		}
	}
	init(metadata: Metadata, templateContent: String) {
		self.metadata = metadata
		self.content = templateContent
	}
	
	
	static func parseJSON(url: URL) -> Metadata {
		do {
			let jsonData = try Data(contentsOf: url)
			return try parseJSON(data: jsonData)
		}
		catch {
			exit(error: "Couldn't parse JSON file \"\(url.path)\":  \(error.localizedDescription)")
		}
	}
	static func parseJSON(data jsonData: Data) throws -> Metadata {
		let jsonDecoder = JSONDecoder()
		let metadata = try jsonDecoder.decode(Metadata.self, from: jsonData)
		return metadata
	}
	
	
	func replace(placeholder: String, with replacement: String) {
		guard content.contains(placeholder) else {
			exit(error: "Content of given template file doesn't contain the placeholder \"\(placeholder)\"")
		}
		
		content = content.replacingOccurrences(of: placeholder, with: replacement)  // despite copy overhead 10x faster than range(of:) + mutating replaceSubrange()
	}
	
	
	func replaceTableRowPlaceholder(withDataFrom collectionType: CollectionType) {
		let placeholder = "%%table_rows%%"
		var tableRowsString = ""
		
		enum CellClass: String {
			case nr = "cell_nr"
			case data = "cell_data"
		}
		func addCell(class cellClass: CellClass, content: String, link: String? = nil) {
			var cell = "<td class=\"\(cellClass.rawValue)\">"
			if let link = link {
				cell.append("<a href=\"\(link)\">")
				cell.append(content)
				cell.append("</a>")
			}
			else {
				cell.append(content)
			}
			cell.append("</td>")
			tableRowsString.append("\n\t")
			tableRowsString.append(cell)
		}
		func addEmptyCell(count: UInt = 1) {
			for _ in 1...1 {
				addCell(class: .data, content: "")
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
		
		
		guard var collection = metadata[keyPath: collectionType.metadataKeyPath] as? [Höreinheit] else {
			exit(error: "Given metadata file doesn't have any data for the requested collection type \"\(collectionType)\"")
		}
		if collectionType == .serie {
			collection.reverse()
		}
		
		let numberOfDigts: UInt = {
			var number = collection.count
			var orderOfMagnitude: UInt = 0
			while number != 0 {
				orderOfMagnitude += 1
				number /= 10
			}
			return orderOfMagnitude
		}()
		
		
		func nameForFolge(_ folge: Folge) -> String {
			if folge.nummer < 0 {
				return ""
			}
			return String(format: "%0\(numberOfDigts)d", folge.nummer)
		}
		func nameForTeil(_ teil: Teil) -> String {
			return "/\(teil.buchstabe ?? "CD\(teil.teilNummer)")"
		}
		func relativePathForLink(_ link: String) -> String {
			for prefix in ["http://dreimetadaten.de/", "https://dreimetadaten.de/"] {
				if link.hasPrefix(prefix) {
					return String(link.dropFirst(prefix.count))
				}
			}
			return link
		}
		
		func addRowFor(höreinheit: Höreinheit) {
			startRow(incomplete: höreinheit.unvollständig ?? false)
			
			// First one (or two) identifying cell(s)
			switch collectionType {
				case .serie:
					if let folge = höreinheit as? Folge {
						addCell(class: .nr, content: nameForFolge(folge))
					}
					else if let teil = höreinheit as? Teil {
						addCell(class: .nr, content: nameForTeil(teil))
					}
					
				case .spezial:
					if let teil = höreinheit as? Teil {
						addCell(class: .nr, content: nameForTeil(teil))
					}
					else {
						addCell(class: .nr, content: höreinheit.titel ?? "")
					}
					
				case .kurzgeschichten:
					if let teil = höreinheit as? Teil {
						if let titel = teil.titel {
							addEmptyCell()
							addCell(class: .nr, content: titel)
						}
						else {
							addCell(class: .nr, content: nameForTeil(teil))
							addEmptyCell()
						}
					}
					else {
						addCell(class: .nr, content: höreinheit.titel ?? "")
						addEmptyCell()
					}
				
				case .die_dr3i:
					if let folge = höreinheit as? Folge {
						addCell(class: .nr, content: nameForFolge(folge))
						addCell(class: .nr, content: höreinheit.titel ?? "")
					}
					else if let teil = höreinheit as? Teil {
						addEmptyCell()
						addCell(class: .nr, content: nameForTeil(teil))
					}
			}
			
			// Links
			if let links = höreinheit.links {
				func addLink(_ link: String?, name: String) {
					if let link = link {
						addCell(class: .data, content: name, link: relativePathForLink(link))
					}
					else {
						addEmptyCell()
					}
				}
				addLink(links.json, name: "Metadaten")
				addLink(links.ffmetadata, name: "FFmetadata")
				addLink(links.xld_log, name: "XLD Log")
				addLink(links.cover, name: "Cover")
				addLink(links.cover_itunes, name: "Cover (iTunes)")
				addLink(links.cover_kosmos, name: "Cover (Kosmos)")
			}
			else {
				addEmptyCell(count: 6)
			}
			
			endRow()
		}
		
		func recursive(_ höreinheit: Höreinheit) {
			addRowFor(höreinheit: höreinheit)
			höreinheit.teile?.forEach { recursive($0) }
		}
		collection.forEach { recursive($0) }
		
		replace(placeholder: placeholder, with: tableRowsString)
	}
	
	
	func replaceDatePlaceholder() {
		let placeholder = "%%date%%"
		
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd.MM.yyyy"
		let dateString = dateFormatter.string(from: date)
		
		replace(placeholder: placeholder, with: dateString)
	}
	
}
