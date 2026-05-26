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
	
	static let defaultSqliteBinaryPath = Command.findExecutablePath(name: "sqlite3") ?? "/usr/bin/sqlite3"
	private static let minimumRequiredSqliteVersion = (major: 3, minor: 50)
	
	init(databaseFile: URL, sqliteBinary: URL) throws {
		self.databaseFile = databaseFile
		self.sqliteBinary = sqliteBinary
		try checkSQLiteVersion()
	}
	
	
	func export(to sqlFile: URL) throws {
		let start = "PRAGMA foreign_keys=ON;\nBEGIN TRANSACTION;\n"
		let end = "COMMIT;\n"
		
		guard FileManager.default.createFile(at: sqlFile, contents: nil) else {
			throw IOError.fileWritingFailed(url: sqlFile, error: nil)
		}
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
		], output: .file(handle))
		
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
		try sqliteCommand(arguments: [], output: .stdout, input: contents)
	}
	
	
	private func checkSQLiteVersion() throws {
		// Parse output of `sqlite3 --version`
		let output = try sqliteCommand(arguments: ["--version"])
		guard let version = output.components(separatedBy: " ").first else {
			throw SQLiteError.versionNotRecognized(version: output)
		}
		let components = version.components(separatedBy: ".").map(Int.init)
		guard components.count >= 2, let major = components[0], let minor = components[1] else {
			throw SQLiteError.versionNotRecognized(version: version)
		}
		
		// Check requirements
		let minMajor = Self.minimumRequiredSqliteVersion.major
		let minMinor = Self.minimumRequiredSqliteVersion.minor
		guard major == minMajor, minor >= minMinor else {
			throw SQLiteError.versionTooOld(required: "\(minMajor).\(minMinor)+", current: version)
		}
	}
	
	
	private enum CommandOutputType {
		case stdout
		case file(FileHandle)
		case variable(UnsafeMutablePointer<String>)
	}
	private func sqliteCommand(arguments sqliteArgs: [String], input: String? = nil) throws -> String {
		var output = ""
		try withUnsafeMutablePointer(to: &output) {
			try sqliteCommand(arguments: sqliteArgs, output: .variable($0), input: input)
		}
		return output
	}
	private func sqliteCommand(arguments sqliteArgs: [String], output: CommandOutputType, input: String? = nil) throws {
		var arguments = [databaseFile.relativePath]
		arguments.append(contentsOf: sqliteArgs)
		
		let stdoutPipe = Pipe()
		let stdinPipe = Pipe()
		let proc = Process()
		proc.executableURL = sqliteBinary
		proc.arguments = arguments
		proc.standardOutput =
			switch output {
				case .stdout:
					FileHandle.standardOutput
				case .file(let handle):
					handle
				case .variable(_):
					stdoutPipe
			}
		proc.standardInput = stdinPipe
		proc.environment = ProcessInfo.processInfo.environment
		
		// Run
		do {
			try proc.run()
		}
		catch {
			throw SQLiteError.processFailed(error: error)
		}
		
		// Write to stdin
		if let input {
			stdinPipe.fileHandleForWriting.write(input)
			try stdinPipe.fileHandleForWriting.close()
		}
		
		// Read stdout
		if case .variable(let pointer) = output {
			let reader = stdoutPipe.fileHandleForReading
			let data = try reader.readToEnd()
			try reader.close()
			guard let data, let string = String(data: data, encoding: .utf8) else {
				throw IOError.stdoutReadingFailed
			}
			pointer.pointee = string
		}
		
		// Wait for termination
		proc.waitUntilExit()
		guard proc.terminationStatus == 0 else {
			throw SQLiteError.commandFailed(arguments: sqliteArgs)
		}
	}
	
	private static func readAndNormalize(contentsOf url: URL) throws -> String {
		do {
			// Normalize Unicode characters into NFC, e.g. replacing "\u{0061}\u{0308}" (LATIN SMALL LETTER A + COMBINING DIAERESIS) with "\u{00E4}" (LATIN SMALL LETTER A WITH DIAERESIS)
			let contents = try String(contentsOf: url, encoding: .utf8)
			return contents.precomposedStringWithCanonicalMapping
		}
		catch {
			throw IOError.fileReadingFailed(url: url, error: error)
		}
	}
}


extension SQLPorter {
	enum IOError: LocalizedError {
		case fileWritingFailed(url: URL, error: Error?)
		case fileReadingFailed(url: URL, error: Error)
		case stdoutReadingFailed
		
		var errorDescription: String? {
			switch self {
				case .fileWritingFailed(let url, let error):
					let description = error.map { ": \($0.localizedDescription)" }
					return "Couldn't write to file \"\(url.relativePath)\"\(description ?? "")"
				case .fileReadingFailed(let url, let error):
					return "Couldn't read file \"\(url.relativePath)\": \(error.localizedDescription)"
				case .stdoutReadingFailed:
					return "Couldn't read stdout as UTF-8 string"
			}
		}
	}
	
	enum SQLiteError: LocalizedError {
		case processFailed(error: Error)
		case commandFailed(arguments: [String])
		case versionNotRecognized(version: String)
		case versionTooOld(required: String, current: String)
		
		var errorDescription: String? {
			switch self {
				case .processFailed(let error):
					return "Process execution failed: \(error.localizedDescription)"
				case .commandFailed(let arguments):
					return "SQLite command with arguments \(arguments) failed"
				case .versionNotRecognized(let version):
					return "SQLite version \"\(version)\" not recognized"
				case .versionTooOld(let required, let current):
					return "SQLite version \(required) required. Current version is \(current)"
			}
		}
	}
}
