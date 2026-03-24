//
//  TableBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation


class TableBuilder {
	let table: HTML.Node
	let thead: HTML.Node
	let tbody: HTML.Node
	var currentHeaderRow: HTML.Node?
	var currentBodyRow: HTML.Node?
	
	init(class tableClass: TableClass) {
		let thead = HTML.thead().indent()
		let tbody = HTML.tbody().indent()
		self.table = HTML.table().class(tableClass.rawValue).indent().content {[
			thead,
			tbody
		]}
		self.thead = thead
		self.tbody = tbody
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
		
		let cell: HTML.Node
		let row: HTML.Node?
		switch type {
			case .th:
				cell = HTML.th()
				row = currentHeaderRow
			case .td:
				cell = HTML.td()
				row = currentBodyRow
		}
		guard let row else { return }
		
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
		
		row.content { cell }
	}
	
	func addCell(type: CellType = .td, class cellClass: CellClass? = nil, width: UInt? = nil, content: HTML.Content) {
		addCell(type: type, class: cellClass, width: width, lines: [content])
	}
	
	func addEmptyCell(count: UInt = 1) {
		for _ in 1...count {
			addCell(lines: [])
		}
	}
	
	private func newRow(rowClass: RowClass?) -> HTML.Node {
		let row = HTML.tr().indent()
		if let rowClass {
			row.class(rowClass.rawValue)
		}
		return row
	}
	func addRow(class rowClass: RowClass? = nil) {
		let row = newRow(rowClass: rowClass)
		tbody.content { row }
		currentBodyRow = row
	}
	func addHeaderRow(class rowClass: RowClass? = nil) {
		let row = newRow(rowClass: rowClass)
		thead.content { row }
		currentHeaderRow = row
	}
	
	func serialize() -> String {
		table.serialize() + "\n"
	}
}
