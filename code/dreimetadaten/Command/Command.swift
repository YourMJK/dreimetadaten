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
struct Command: ParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: executableName,
		version: "2.0.0",
		subcommands: [Load.self, Export.self, WebBuild.self, Migrate.self],
		helpMessageLabelColumnWidth: 20
	)
	
	static let workingDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
	static let projectDir = URL(fileURLWithPath: CommandLine.arguments.first!, isDirectory: false)
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
	static var webDataURL = webURL.appendingPathComponent(webDataDirRelativePath)
	static var webDataDir = webDir.appendingPathComponent(webDataDirRelativePath)
	static var webIndexDir = webDir.appendingPathComponent("index")
	static let webTemplatesDir = url(projectRelativePath: "web_templates")
	
	static func url(projectRelativePath projectDirRelativePath: String) -> URL {
		let dest = URL(fileURLWithPath: projectDirRelativePath, relativeTo: projectDir)
		let base = workingDir
		let workingDirRelativePath = relativePath(of: dest, toDirectory: base)
		return URL(fileURLWithPath: workingDirRelativePath, relativeTo: workingDir)
	}
	static func relativePath(of dest: URL, toDirectory base: URL) -> String {
		let destComponents = dest.standardizedFileURL.pathComponents
		let baseComponents = base.standardizedFileURL.pathComponents
		var index = 0
		while index < destComponents.count && index < baseComponents.count && destComponents[index] == baseComponents[index] {
			index += 1
		}
		var relComponents = Array(repeating: "..", count: baseComponents.count - index)
		relComponents.append(contentsOf: destComponents[index...])
		return relComponents.joined(separator: "/")
	}
}
