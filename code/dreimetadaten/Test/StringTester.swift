//
//  StringTester.swift
//  dreimetadaten
//
//  Created by YourMJK on 23.09.25.
//

import Foundation
import GRDB


struct StringTester {
	let db: Database
	private let invalidCharacters: CharacterSet = {
		var set: CharacterSet = .illegalCharacters
		set.formUnion(.controlCharacters)
		set.formUnion(.whitespacesAndNewlines)
		set.formUnion(.whitespaces)
		set.remove("\n")
		set.remove(" ")
		return set
	}()
	
	
	func validateStrings(tables: some Collection<Table>, violation: (Cell, ValidationError) -> Void) throws -> UInt {
		var violations: UInt = 0
		
		for table in tables {
			// Get cells for strings values in table
			let cells = try queryStrings(table: table)
			
			// Validate string in cell
			for cell in cells {
				do {
					try validate(string: cell.value)
				}
				catch let error as ValidationError {
					violation(cell, error)
					violations += 1
				}
			}
		}
		
		return violations
	}
	
	private func validate(string: String) throws {
		// Non-empty
		guard !string.isEmpty else {
			throw ValidationError.empty
		}
		
		// No leading or trailing whitespace
		let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
		guard string == trimmed else {
			throw ValidationError.leadingOrTrailingWhitespace
		}
		
		// No repeated whitespace, except two newlines
		let repeatedWhitespaceMatches = string.matches(of: #/\s\s+/#).filter { $0.output != "\n\n" }
		guard repeatedWhitespaceMatches.isEmpty else {
			throw ValidationError.repeatedWhitespace
		}
		
		// No invalid characters
		if let invalidRange = string.rangeOfCharacter(from: invalidCharacters) {
			throw ValidationError.invalidCharacter(string[invalidRange])
		}
		
		// No "...", only "…"
		guard !string.contains("...") else {
			throw ValidationError.threeDots
		}
		
		// Space before "…" at the end
		guard !string.contains(#/[^ ]…$/#) else {
			throw ValidationError.noSpaceBeforeEndingEllipsis
		}
		
		// No " - ", only " – "
		guard !string.contains(" - ") else {
			throw ValidationError.hyphenForDash
		}
	}
	
	private func queryStrings(table: Table) throws -> [Cell] {
		// Query all violations of constraint
		let rows = try Row.fetchAll(db, sql: "SELECT rowid, * FROM \(table.rawValue)")
		var cells: [Cell] = []
		
		// Format database values
		for row in rows {
			// Get rowid value
			guard let rowidValue = row.databaseValues.first, case .int64(let rowid) = rowidValue.storage else {
				throw QueryError.invalidRowID(table: table)
			}
			let tableRow = row.dropFirst()
			
			// Filter table row for string values and collect cells
			for (column, value) in tableRow {
				guard case .string(let string) = value.storage else {
					continue
				}
				let cell = Cell(string, column, table.rawValue, rowid)
				cells.append(cell)
			}
		}
		
		return cells
	}
}


extension StringTester {
	typealias Cell = (value: String, column: String, table: String, rowid: Int64)
	
	enum QueryError: LocalizedError {
		case invalidRowID(table: Table)
		
		var errorDescription: String? {
			switch self {
				case .invalidRowID(let table):
					"Invalid \"rowid\" value in table \"\(table.rawValue)\""
			}
		}
	}
	
	enum ValidationError: LocalizedError {
		case empty
		case leadingOrTrailingWhitespace
		case repeatedWhitespace
		case invalidCharacter(Substring)
		case threeDots
		case noSpaceBeforeEndingEllipsis
		case hyphenForDash
		
		var errorDescription: String? {
			switch self {
				case .empty:
					"Empty string"
				case .leadingOrTrailingWhitespace:
					"Leading or trailing whitespace in string"
				case .repeatedWhitespace:
					"Repeated whitespace in string"
				case .invalidCharacter(let sequence):
					"Invalid character \"\(sequence.unicodeScalars.map { $0.escaped(asASCII: true) }.joined())\" in string"
				case .threeDots:
					"\"...\" instead of \"…\" in string"
				case .noSpaceBeforeEndingEllipsis:
					"No space before \"…\" at end of string"
				case .hyphenForDash:
					"Hyphen \" - \" instead of dash in string"
			}
		}
	}
}
