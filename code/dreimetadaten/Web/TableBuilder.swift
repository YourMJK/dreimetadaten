//
//  TableBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation


class TableBuilder {
	var content: String = ""
	
	enum CellType: String {
		case th
		case td
	}
	enum CellClass: String {
		case nr = "cell_nr"
		case data = "cell_data"
		case icon = "cell_icon"
	}
	enum RowClass: String {
		case incomplete = "row_incomplete"
	}
	enum TableClass: String {
		case datatable
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
		content.append("\t\(cell)\n")
	}
	
	func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, content: String) {
		addCell(type: type, class: cellClass, width: width, [(content, nil)])
	}
	
	func addEmptyCell(count: UInt = 1) {
		for _ in 1...count {
			addCell([])
		}
	}
	
	func startRow(class rowClass: RowClass? = nil) {
		content.append("<tr")
		if let rowClass {
			content.append(" class=\"\(rowClass.rawValue)\"")
		}
		content.append(">\n")
	}
	func endRow() {
		content.append("</tr>\n")
	}
	
	func startTable(class tableClass: TableClass? = nil) {
		content.append("<table")
		if let tableClass {
			content.append(" class=\"\(tableClass.rawValue)\"")
		}
		content.append(">\n")
	}
	func endTable() {
		content.append("</table>\n")
	}
	
}
