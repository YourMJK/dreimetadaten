//
//  TableFormatter.swift
//  dreimetadaten
//
//  Created by YourMJK on 22.09.25.
//

public struct TableFormatter {
	let separator: String
	let minimumColumnWidth: Int
	private var columnWidths: [Int: Int]
	
	init(separator: String, minimumColumnWidth: Int = 0) {
		self.separator = separator
		self.minimumColumnWidth = minimumColumnWidth
		self.columnWidths = [:]
	}
	
	
	mutating func updateColumnWidths<R: Collection>(row: R) where R.Element: StringProtocol {
		for (index, column) in row.enumerated() {
			columnWidths[index] = max(columnWidths[index, default: 0], column.count)
		}
	}
	mutating func updateColumnWidths<R: Collection>(rows: some Collection<R>) where R.Element: StringProtocol {
		for row in rows {
			updateColumnWidths(row: row)
		}
	}
	mutating func resetColumnWidths() {
		columnWidths.removeAll()
	}
	
	func format<R: Collection>(row: R) -> String where R.Element: StringProtocol {
		row
			.enumerated()
			.map { (index, string) in
				// Pad with spaces to the left
				let width = getColumnWidth(index: index)
				let padding = String(repeating: " ", count: max(width-string.count, 0))
				return padding + string
			}
			.joined(separator: separator)
	}
	func format<R: Collection>(rows: some Collection<R>) -> String where R.Element: StringProtocol {
		rows.map(format(row:)).joined(separator: "\n")
	}
	
	private func getColumnWidth(index: Int) -> Int {
		max(columnWidths[index, default: 0], minimumColumnWidth)
	}
	
}
