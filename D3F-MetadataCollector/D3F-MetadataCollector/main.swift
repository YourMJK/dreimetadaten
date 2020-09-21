//
//  main.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 13.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


let usage = """
Usage:   \(ProgramName) [-c <current JSON>] [--overwrite] -o (json | csv) [-i (csv | ffmetadata | dataDir | mbDiscIDList) (serie | die_dr3i) <input files ...>]

Example: \(ProgramName) -c master.json -o json -i csv daten1.csv daten2.csv
"""



if (CommandLine.arguments.count > 1) {
	var previousFile: URL?
	var overwrite: Bool = false
	var outputType: MetadataCollector.OutputType?
	var inputType: MetadataCollector.InputType?
	var collectionType: MetadataCollector.CollectionType?
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
		func parseNextStringEnum<T>(description: String, contructor: (String) -> T?) -> T {
			let nextArg = getNext(description: description)
			guard let parsed = contructor(nextArg) else {
				exit(error: "Unknown \(description) \"\(nextArg)\"")
			}
			return parsed
		}
		
		switch arg {
			case "-c":
				previousFile = URL(fileURLWithPath: getNext(description: "file path"))
			
			case "--overwrite":
				overwrite = true
			
			case "-o":
				outputType = parseNextStringEnum(description: "output type", contructor: MetadataCollector.OutputType.init(rawValue:))
			
			case "-i":
				inputType = parseNextStringEnum(description: "input type", contructor: MetadataCollector.InputType.init(rawValue:))
				collectionType = parseNextStringEnum(description: "collection type", contructor: MetadataCollector.CollectionType.init(rawValue:))
				
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
	
	if let inputType = inputType, let collectionType = collectionType {
		guard inputFiles.count > 0 else {
			exit(error: "No input files specified")
		}
		metadataCollector.addMetadata(fromURLs: inputFiles, withType: inputType, toCollection: collectionType, overwrite: overwrite)
	}
	metadataCollector.applyCorrections()
	
	stdout(metadataCollector.output(outputType: outputType!))
}
else {
	exit(error: usage, noPrefix: true)
}
