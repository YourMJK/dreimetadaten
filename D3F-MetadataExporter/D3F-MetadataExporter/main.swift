//
//  main.swift
//  D3F-MetadataExporter
//
//  Created by YourMJK on 24.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


let usage = """
Usage:   \(ProgramName) -c <master JSON> -o json <destination directory>

Example: \(ProgramName) -c master.json -o json ./web/data/
"""



if (CommandLine.arguments.count > 1) {
	var masterFile: URL?
	var outputType: MetadataExporter.OutputType?
	var outputDirectory: URL?
	
	// Parse arguments
	var arguments = CommandLine.arguments[1...]
	while arguments.count > 0 {
		let arg = arguments.popFirst()!
		
		func getNext(description: String) -> String {
			if let next = arguments.popFirst() {
				return next
			}
			else {
				exit(error: "Missing \(description) for option \"\(arg)\"")
			}
		}
		func parseNextStringEnum<T>(description: String, contructor: (String) -> T?) -> T {
			let nextArg = getNext(description: description)
			guard let parsed = contructor(nextArg) else {
				exit(error: "Unknown \(description) \"\(nextArg)\"")
			}
			return parsed
		}
		
		switch arg {
			case "-c":
				masterFile = URL(fileURLWithPath: getNext(description: "file path"))
			
			case "-o":
				outputType = parseNextStringEnum(description: "output type", contructor: MetadataExporter.OutputType.init(rawValue:))
				outputDirectory = URL(fileURLWithPath: getNext(description: "destination directory"))
			
			default:
				exit(error: "Unknown argument \"\(arg)\"")
		}
	}
	
	// Check neccessary arguments
	guard masterFile != nil else {
		exit(error: "Missing master JSON metadata file")
	}
	guard outputType != nil else {
		exit(error: "Missing output type")
	}
	guard outputDirectory != nil else {
		exit(error: "Missing destination directory")
	}
	
	// Start program
	let metadataExporter = MetadataExporter(withMasterFile: masterFile!)
	metadataExporter.exportMetadata(to: outputDirectory!, outputType: outputType!)
}
else {
	exit(error: usage, noPrefix: true)
}
