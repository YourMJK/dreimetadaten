//
//  main.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 13.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


let usage = """
Usage:   \(ProgramName) [-c <current JSON>] [--overwrite] -o (json | csv) [-i (csv | ffmetadata) <input files ...>]

Example: \(ProgramName) -c master.json -o json -i csv daten1.csv daten2.csv
"""



if (CommandLine.arguments.count > 1) {
	var previousFile: URL?
	var overwrite: Bool = false
	var outputType: MetadataCollector.OutputType?
	var inputType: MetadataCollector.InputType?
	var inputFiles = [URL]()
	
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
		
		switch arg {
			case "-c":
				previousFile = URL(fileURLWithPath: getNext(description: "file path"))
			
			case "--overwrite":
				overwrite = true
			
			case "-o":
				let descr = "output type"
				let nextArg = getNext(description: descr)
				guard let parsedOutputType = MetadataCollector.OutputType(rawValue: nextArg) else {
					exit(error: "Unknown \(descr) \"\(nextArg)\"")
				}
				outputType = parsedOutputType
			
			case "-i":
				let descr = "input type"
				let nextArg = getNext(description: descr)
				guard let parsedInputType = MetadataCollector.InputType(rawValue: nextArg) else {
					exit(error: "Unknown \(descr) \"\(nextArg)\"")
				}
				inputType = parsedInputType
				
				inputFiles = arguments.map { URL(fileURLWithPath: $0) }
				arguments.removeAll()
			
			default:
			exit(error: "Unknown argument \"\(arg)\"")
		}
	}
	
	// Check neccessary arguments
	guard outputType != nil else {
		exit(error: "Missing output type")
	}
	
	// Start program
	let metadataCollector = MetadataCollector(withPreviousFile: previousFile)
	
	if let inputType = inputType {
		guard inputFiles.count > 0 else {
			exit(error: "No input files specified")
		}
		metadataCollector.addMetadata(fromFiles: inputFiles, withType: inputType, overwrite: overwrite)
	}
	
	stdout(metadataCollector.output(outputType: outputType!))
}
else {
	exit(error: usage, noPrefix: true)
}
