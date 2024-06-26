//
//  SQLExporter.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.06.24.
//

import Foundation
import GRDB


struct SQLExporter {
	let databaseFile: URL
	let sqliteBinary: URL
	
	func export(to sqlFile: URL) throws {
		let start = "PRAGMA foreign_keys=ON;\nBEGIN TRANSACTION;\n"
		let end = "COMMIT;\n"
		
		FileManager.default.createFile(atPath: sqlFile.path, contents: nil)
		let handle: FileHandle
		do {
			handle = try FileHandle(forWritingTo: sqlFile)
		}
		catch {
			throw ExporterError.fileWritingFailed(url: sqlFile, error: error)
		}
		defer { handle.closeFile() }
		
		// Overwrite file with `start`
		handle.write(start)
		
		// Append schema first, then data
		try sqliteCommand(arguments: [
			".schema --indent --nosys",
			".dump --data-only --nosys",
		], output: handle)
		
		// Append `end`
		handle.seekToEndOfFile()
		handle.write(end)
	}
	
	private func sqliteCommand(arguments sqliteArgs: [String], output: FileHandle = .standardOutput) throws {
		var arguments = [databaseFile.relativePath]
		arguments.append(contentsOf: sqliteArgs)
		
		let stderrPipe = Pipe()
		let proc = Process()
		proc.executableURL = sqliteBinary
		proc.arguments = arguments
		proc.standardError = stderrPipe
		proc.standardOutput = output
		proc.environment = ProcessInfo.processInfo.environment
		
		do {
			try proc.run()
		}
		catch {
			throw SQLiteError.processFailed(error: error)
		}
		proc.waitUntilExit()
		
		let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
		stderrPipe.fileHandleForReading.closeFile()
		
		guard proc.terminationStatus == 0 else {
			let stderrString = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .newlines)
			let error = stderrString.map { $0.isEmpty ? nil : $0 } ?? nil
			throw SQLiteError.commandFailed(arguments: sqliteArgs, error: error)
		}
	}
}


extension SQLExporter {
	enum ExporterError: LocalizedError {
		case fileWritingFailed(url: URL, error: Error)
		
		var errorDescription: String? {
			switch self {
				case .fileWritingFailed(let url, let error):
					return "Couldn't write to file \"\(url.relativePath)\": \(error.localizedDescription)"
			}
		}
	}
	
	enum SQLiteError: LocalizedError {
		case processFailed(error: Error)
		case commandFailed(arguments: [String], error: String?)
		
		var errorDescription: String? {
			switch self {
				case .processFailed(let error):
					return "Process execution failed: \(error.localizedDescription)"
				case .commandFailed(let arguments, let error):
					return "SQLite command with arguments \(arguments) failed\(error.map { ":\n\($0)" } ?? "")"
			}
		}
	}
}
