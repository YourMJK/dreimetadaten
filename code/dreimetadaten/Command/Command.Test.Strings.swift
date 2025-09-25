//
//  Command.Test.Strings.swift
//  dreimetadaten
//
//  Created by YourMJK on 23.09.25.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Test {
	struct Strings: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Test validity of string values in dataset.",
			alwaysCompactUsageOptions: true
		)
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		func run() throws {
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			let failed = try dbQueue.read { db in
				let tester = StringTester(db: db)
				return try tester.validateStrings(tables: StringTester.Table.allCases) { (cell, error) in
					// Print violations
					stderr("> FAILED in column \"\(cell.column)\" of table \"\(cell.table)\" at rowid \(cell.rowid) (\(error.localizedDescription)):\n\"\(cell.value)\"\n")
				}
			}
			
			// Print and return number of failed strings as exit code
			stdout("\(failed) strings failed.")
			guard failed == 0 else {
				let exitCode = Int32(failed)
				throw ExitCode(exitCode)
			}
		}
	}
}
