//
//  Command.Test.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation
import CommandLineTool
import ArgumentParser


extension Command {
	struct Test: AsyncParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Test dataset completeness, validity and up-to-dateness.",
			subcommands: [DB.self, Strings.self, Links.self],
			helpMessageLabelColumnWidth: 20,
			alwaysCompactUsageOptions: true
		)
	}
}
