//
//  main.swift
//  D3F-WebGenerator
//
//  Created by YourMJK on 26.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


let usage = """
Usage:   \(ProgramName) -c <master JSON> -o (\(CollectionType.allCasesString)) -i <HTML template file>

Example: \(ProgramName) -c master.json -o serie -i template.html
"""



if (CommandLine.arguments.count > 1) {
	var masterFile: URL?
	var collectionType: CollectionType?
	var templateFile: URL?
	
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
				collectionType = parseNextStringEnum(description: "collection type", contructor: CollectionType.init(rawValue:))
				
			case "-i":
				templateFile = URL(fileURLWithPath: getNext(description: "template file"))
			
			default:
				exit(error: "Unknown argument \"\(arg)\"")
		}
	}
	
	// Check neccessary arguments
	guard masterFile != nil else {
		exit(error: "Missing master JSON metadata file")
	}
	guard collectionType != nil else {
		exit(error: "Missing collection type")
	}
	guard templateFile != nil else {
		exit(error: "Missing template file")
	}
	
	// Start program
	let webGenerator = WebGenerator(withMasterFile: masterFile!, templateFile: templateFile!)
	webGenerator.replaceTableRowPlaceholder(withDataFrom: collectionType!)
	webGenerator.replaceDatePlaceholder()
	
	stdout(webGenerator.content)
}
else {
	exit(error: usage, noPrefix: true)
}
