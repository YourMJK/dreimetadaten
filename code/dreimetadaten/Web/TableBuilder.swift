//
//  TableBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation
import HTML


class TableBuilder {
	private let tableClass: TableClass
	private(set) var thead: HTML.Node?
	private(set) var tbody: HTML.Node?
	private(set) var currentHeaderRow: HTML.Node?
	private(set) var currentBodyRow: HTML.Node?
	
	init(class tableClass: TableClass) {
		self.tableClass = tableClass
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
	
	var table: HTML.Node {
		let content = [thead, tbody].compactMap { $0 }
		return HTML.table().class(tableClass.rawValue).indent().content { content }
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
		if tbody == nil {
			tbody = HTML.tbody().indent()
		}
		tbody!.content { row }
		currentBodyRow = row
	}
	func addHeaderRow(class rowClass: RowClass? = nil) {
		let row = newRow(rowClass: rowClass)
		if thead == nil {
			thead = HTML.thead().indent()
		}
		thead!.content { row }
		currentHeaderRow = row
	}
	
	func serialize() -> String {
		table.serialize() + "\n"
	}
}
