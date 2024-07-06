//
//  Command.Export.swift
//  dreimetadaten
//
//  Created by YourMJK on 08.04.24.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command {
	struct Export: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Export dataset into various (more convenient) formats.",
			subcommands: [SQL.self, TSV.self, JSON.self, Web.self],
			helpMessageLabelColumnWidth: 20,
			alwaysCompactUsageOptions: true
		)
	}
}
