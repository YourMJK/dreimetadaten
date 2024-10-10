//
//  Command.Import.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.10.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command {
	struct Import: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Import data from other sources.",
			subcommands: [MusicBrainz.self],
			helpMessageLabelColumnWidth: 20,
			alwaysCompactUsageOptions: true
		)
	}
}
