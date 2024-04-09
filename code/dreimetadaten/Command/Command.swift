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
		version: "1.0.0",
		subcommands: [Migrate.self, Export.self, WebBuild.self],
		helpMessageLabelColumnWidth: 20
	)
	
	static let workingDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
	static let projectDir = URL(fileURLWithPath: CommandLine.arguments.first!, isDirectory: false)
		.deletingLastPathComponent()
		.appendingPathComponent("..")
	
	static func url(projectRelativePath projectDirRelativePath: String) -> URL {
		let dest = URL(fileURLWithPath: projectDirRelativePath, relativeTo: projectDir)
		let base = workingDir
		let destComponents = dest.standardizedFileURL.pathComponents
		let baseComponents = base.standardizedFileURL.pathComponents
		var index = 0
		while index < destComponents.count && index < baseComponents.count && destComponents[index] == baseComponents[index] {
			index += 1
		}
		var workingDirRelativeComponents = Array(repeating: "..", count: baseComponents.count - index)
		workingDirRelativeComponents.append(contentsOf: destComponents[index...])
		let workingDirRelativePath = workingDirRelativeComponents.joined(separator: "/")
		return URL(fileURLWithPath: workingDirRelativePath, relativeTo: workingDir)
	}
}
