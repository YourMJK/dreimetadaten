//
//  Command.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.03.24.
//

import Foundation
import CommandLineTool
import ArgumentParser

@main
struct Command: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: executableName,
		version: "2.10.4",
		subcommands: [Load.self, Export.self, WebBuild.self, Import.self, Test.self],
		helpMessageLabelColumnWidth: 20
	)
	
	static let workingDir = URL(filePath: FileManager.default.currentDirectoryPath, directoryHint: .isDirectory)
	static let projectDir = URL(filePath: CommandLine.arguments.first!, directoryHint: .notDirectory)
		.deletingLastPathComponent()
		.appendingPathComponent("..")
	
	static let metadataDir = url(projectRelativePath: "metadata")
	static let databaseFile = metadataDir.appendingPathComponent("db.sqlite")
	static let sqlFile = metadataDir.appendingPathComponent("db.sql")
	static let tsvDir = metadataDir.appendingPathComponent("tsv")
	static let jsonDir = metadataDir.appendingPathComponent("json")
	
	static let webURL = URL(string: "http://dreimetadaten.de")!
	static let webDir = url(projectRelativePath: "web")
	private static let webDataDirRelativePath = "data"
	static let webDataURL = webURL.appendingPathComponent(webDataDirRelativePath)
	static let webDataDir = webDir.appendingPathComponent(webDataDirRelativePath)
	static let webIndexDir = webDir.appendingPathComponent("index")
	static let webTemplatesDir = url(projectRelativePath: "web_templates")
	
	static func url(projectRelativePath projectDirRelativePath: String) -> URL {
		let dest = URL(filePath: projectDirRelativePath, relativeTo: projectDir)
		let base = workingDir
		let workingDirRelativePath = dest.relativePath(toDirectory: base)
		return URL(filePath: workingDirRelativePath, relativeTo: workingDir)
	}
}


extension Command {
	static func findExecutablePath(name: String) -> String? {
		let pathVariable = ProcessInfo.processInfo.environment["PATH"]
		let pathVariableComponents = pathVariable?.split(separator: ":").map { String($0) }
		let searchPaths = (pathVariableComponents ?? []) + defaultSearchPaths
		for searchPath in searchPaths {
			let executablePath = String(searchPath) + "/" + name
			if FileManager.default.isExecutableFile(atPath: executablePath) {
				return executablePath
			}
		}
		return nil
	}
	
	private static let defaultSearchPaths = [
		"/usr/bin",
		"/bin",
		"/usr/sbin",
		"/sbin",
		"/usr/local/bin",
	]
}
