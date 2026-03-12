//
//  TableBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation


class TableBuilder {
	let table: HTML.Node
	var currentRow: HTML.Node?
	
	init(class tableClass: TableClass) {
		self.table = HTML.table().class(tableClass.rawValue).indent()
	}
	
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
	
	func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, lines: [HTML.Content]) {
		guard width != 0 else { return }
		
		let cell: HTML.Node =
			switch type {
				case .th: HTML.th()
				case .td: HTML.td()
			}
		
		if let cellClass {
			cell.class(cellClass.rawValue)
		}
		if let width {
			cell.attribute(key: "colspan", value: "\(width)")
		}
		
		var first = true
		for line in lines {
			if !first {
				cell.content(HTML.br)
			}
			first = false
			cell.content { line }
		}
		
		currentRow?.content { cell }
	}
	
	func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, content: HTML.Content) {
		addCell(type: type, class: cellClass, width: width, lines: [content])
	}
	
	func addEmptyCell(count: UInt = 1) {
		for _ in 1...count {
			addCell(lines: [])
		}
	}
	
	func addRow(class rowClass: RowClass? = nil) {
		let row = HTML.tr().indent()
		if let rowClass {
			row.class(rowClass.rawValue)
		}
		table.content { row }
		currentRow = row
	}
	
	func serialize() -> String {
		table.serialize() + "\n"
	}
}
