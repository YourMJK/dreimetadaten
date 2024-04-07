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
		subcommands: [Migrate.self],
		helpMessageLabelColumnWidth: 20
	)
}
