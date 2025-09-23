//
//  DatabaseTester.swift
//  dreimetadaten
//
//  Created by YourMJK on 22.09.25.
//

import Foundation
import GRDB


struct DatabaseTester {
	typealias TableRows = [[String]]
	
	let db: Database
	private let decimalFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.usesGroupingSeparator = false
		return formatter
	}()
	
	
	func validate(constraints: some Collection<Constraint>, violation: (Constraint, TableRows) -> Void) throws -> (passed: Int, total: Int) {
		var passed = 0
		
		for constraint in constraints {
			// Check if constraint is violated
			if let tableRows = try queryViolations(constraint: constraint) {
				violation(constraint, tableRows)
			}
			else {
				passed += 1
			}
		}
		
		return (passed, constraints.count)
	}
	
	private func queryViolations(constraint: Constraint) throws -> TableRows? {
		// Query all violations of constraint
		let rows = try Row.fetchAll(db, sql: constraint.sqlQueryForNotExists)
		
		// Prepare table rows if result is not empty
		guard let columnNames = rows.first?.columnNames else {
			return nil
		}
		var tableRows: TableRows = [[String](columnNames)]
		
		// Format database values
		func format(_ value: DatabaseValue) -> String {
			switch value.storage {
				case .string(let string): return string
				case .double(let double): return decimalFormatter.string(from: NSNumber(value: double))!
				default: return "\(value)"
			}
		}
		for row in rows {
			let tableRow = Array(row.databaseValues.map(format(_:)))
			tableRows.append(tableRow)
		}
		
		return tableRows
	}
}
