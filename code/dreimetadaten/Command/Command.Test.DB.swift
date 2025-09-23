//
//  Command.Test.DB.swift
//  dreimetadaten
//
//  Created by YourMJK on 22.09.25.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Test {
	struct DB: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Test database against additional constraints.",
			alwaysCompactUsageOptions: true
		)
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		func run() throws {
			var tableFormatter = TableFormatter(separator: " | ")
			
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			let (passed, total) = try dbQueue.read { db in
				let tester = DatabaseTester(db: db)
				return try tester.validate(constraints: DatabaseTester.Constraint.allCases) { (constraint, tableRows) in
					// Print violations
					tableFormatter.resetColumnWidths()
					tableFormatter.updateColumnWidths(rows: tableRows)
					let table = tableFormatter.format(rows: tableRows)
					stderr("> FAILED \"\(constraint.rawValue)\":\n\(table)\n")
				}
			}
			
			// Print passed vs. total and return number of failed constraints as exit code
			stdout("\(passed)/\(total) constraints passed.")
			guard passed == total else {
				let exitCode = Int32(total - passed)
				throw ExitCode(exitCode)
			}
		}
	}
}
