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
		case th = "th"
		case td = "td"
	}
	enum CellClass: String {
		case nr = "cell_nr"
		case data = "cell_data"
		case icon = "cell_icon"
	}
	enum RowClass: String {
		case incomplete = "row_incomplete"
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
		content.append("\n\t")
		content.append(cell)
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
		content.append("\n<tr")
		if let rowClass {
			content.append(" class=\"\(rowClass.rawValue)\"")
		}
		content.append(">")
	}
	func endRow() {
		content.append("\n</tr>")
	}
	
}
