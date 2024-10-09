//
//  SQLPorter.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.06.24.
//

import Foundation
import GRDB


struct SQLPorter {
	let databaseFile: URL
	let sqliteBinary: URL
	
	static let defaultSqliteBinaryPath = "/usr/bin/sqlite3"
	
	
	func export(to sqlFile: URL) throws {
		let start = "PRAGMA foreign_keys=ON;\nBEGIN TRANSACTION;\n"
		let end = "COMMIT;\n"
		
		FileManager.default.createFile(atPath: sqlFile.path, contents: nil)
		let handle: FileHandle
		do {
			handle = try FileHandle(forWritingTo: sqlFile)
		}
		catch {
			throw IOError.fileWritingFailed(url: sqlFile, error: error)
		}
		defer { handle.closeFile() }
		
		// Overwrite file with `start`
		handle.write(start)
		
		// Append schema first, then data
		try sqliteCommand(arguments: [
			// Manually querying sqlite_master because ".schema --indent --nosys" inserts new automatic comments each time after VIEW definitions
			"SELECT sql||';' FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'",
			".dump --data-only --nosys",
		], output: handle)
		
		// Append `end`
		handle.seekToEndOfFile()
		handle.write(end)
		handle.closeFile()
		
		// Normalize
		let contents = try Self.readAndNormalize(contentsOf: sqlFile)
		do {
			try contents.write(to: sqlFile, atomically: false, encoding: .utf8)
		}
		catch {
			throw IOError.fileWritingFailed(url: sqlFile, error: error)
		}
	}
	
	func `import`(from sqlFile: URL) throws {
		let contents = try Self.readAndNormalize(contentsOf: sqlFile)
		try sqliteCommand(arguments: [], input: contents)
	}
	
	
	private func sqliteCommand(arguments sqliteArgs: [String], output: FileHandle = .standardOutput, input: String? = nil) throws {
		var arguments = [databaseFile.relativePath]
		arguments.append(contentsOf: sqliteArgs)
		
		let stdinPipe = Pipe()
		let proc = Process()
		proc.executableURL = sqliteBinary
		proc.arguments = arguments
		proc.standardOutput = output
		proc.standardInput = stdinPipe
		proc.environment = ProcessInfo.processInfo.environment
		
		do {
			try proc.run()
		}
		catch {
			throw SQLiteError.processFailed(error: error)
		}
		if let input {
			stdinPipe.fileHandleForWriting.write(input)
			stdinPipe.fileHandleForWriting.closeFile()
		}
		proc.waitUntilExit()
		
		guard proc.terminationStatus == 0 else {
			throw SQLiteError.commandFailed(arguments: sqliteArgs)
		}
	}
	
	private static func readAndNormalize(contentsOf url: URL) throws -> String {
		do {
			// Normalize Unicode characters into NFC, e.g. replacing "\u{0061}\u{0308}" (LATIN SMALL LETTER A + COMBINING DIAERESIS) with "\u{00E4}" (LATIN SMALL LETTER A WITH DIAERESIS)
			let contents = try String(contentsOfFile: url.path, encoding: .utf8)
			return contents.precomposedStringWithCanonicalMapping
		}
		catch {
			throw IOError.fileReadingFailed(url: url, error: error)
		}
	}
}


extension SQLPorter {
	enum IOError: LocalizedError {
		case fileWritingFailed(url: URL, error: Error)
		case fileReadingFailed(url: URL, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .fileWritingFailed(let url, let error):
					return "Couldn't write to file \"\(url.relativePath)\": \(error.localizedDescription)"
				case .fileReadingFailed(let url, let error):
					return "Couldn't read file \"\(url.relativePath)\": \(error.localizedDescription)"
			}
		}
	}
	
	enum SQLiteError: LocalizedError {
		case processFailed(error: Error)
		case commandFailed(arguments: [String])
		
		var errorDescription: String? {
			switch self {
				case .processFailed(let error):
					return "Process execution failed: \(error.localizedDescription)"
				case .commandFailed(let arguments):
					return "SQLite command with arguments \(arguments) failed"
			}
		}
	}
}
