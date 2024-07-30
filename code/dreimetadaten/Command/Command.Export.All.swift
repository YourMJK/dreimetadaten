//
//  Command.Export.All.swift
//  dreimetadaten
//
//  Created by YourMJK on 30.07.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command.Export {
	struct All: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Perform all export commands with default arguments.",
			alwaysCompactUsageOptions: true
		)
		
		func run() throws {
			let commandTypes = Command.Export.configuration.subcommands.filter { $0 != Self.self }
			for commandType in commandTypes {
				stderr("Export \(commandType._commandName)")
				var command = try commandType.parse([])
				try command.run()
			}
		}
	}
}
