//
//  WebBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.04.24.
//

import Foundation


class WebBuilder {
	var objectModel: MetadataObjectModel
	var collectionType: CollectionType
	var content: String
	
	init(objectModel: MetadataObjectModel, collectionType: CollectionType, templateContent: String) {
		self.objectModel = objectModel
		self.collectionType = collectionType
		self.content = templateContent
	}
	
	
	func build() throws {
		try replaceTableRowPlaceholder()
		try replaceDatePlaceholder()
	}
	
	
	private func replaceTableRowPlaceholder() throws {
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
		
		
		guard var collection = objectModel[keyPath: collectionType.objectModelKeyPath] as? [MetadataObjectModel.Hörspiel] else {
			throw BuildingError.missingCollectionData(collectionType: collectionType)
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
		
		
		func nameForFolge(_ folge: MetadataObjectModel.Folge) -> String {
			if folge.nummer < 0 {
				return ""
			}
			return String(format: "%0\(numberOfDigts)d", folge.nummer)
		}
		func nameForTeil(_ teil: MetadataObjectModel.Teil) -> String {
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
		
		func addRowFor(hörspiel: MetadataObjectModel.Hörspiel) {
			startRow(incomplete: hörspiel.unvollständig ?? false)
			
			// First one (or two) identifying cell(s)
			switch collectionType {
				case .serie:
					if let folge = hörspiel as? MetadataObjectModel.Folge {
						addCell(class: .nr, content: nameForFolge(folge))
					}
					else if let teil = hörspiel as? MetadataObjectModel.Teil {
						addCell(class: .nr, content: nameForTeil(teil))
					}
					
				case .spezial:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
						addCell(class: .nr, content: nameForTeil(teil))
					}
					else {
						addCell(class: .nr, content: hörspiel.titel ?? "")
					}
					
				case .kurzgeschichten:
					if let teil = hörspiel as? MetadataObjectModel.Teil {
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
						addCell(class: .nr, content: nameForTeil(teil))
					}
			}
			
			// Links
			if let links = hörspiel.links {
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
		
		func recursive(_ hörspiel: MetadataObjectModel.Hörspiel) {
			addRowFor(hörspiel: hörspiel)
			hörspiel.teile?.forEach { recursive($0) }
		}
		collection.forEach { recursive($0) }
		
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
		case missingCollectionData(collectionType: CollectionType)
		case missingPlaceholderInTemplate(placeholder: String)
		
		var errorDescription: String? {
			switch self {
				case .missingCollectionData(let collectionType):
					return "Given dataset doesn't contain any data for the selected collection type \"\(collectionType)\""
				case .missingPlaceholderInTemplate(let placeholder):
					return "Content of given template file doesn't contain the placeholder \"\(placeholder)\""
			}
		}
	}
}
