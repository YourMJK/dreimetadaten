//
//  CommandLine.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 24.10.18.
//  Copyright © 2018 YourMJK. All rights reserved.
//

import Foundation


let ProgramName = URL(fileURLWithPath: CommandLine.arguments.first!).lastPathComponent


extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		guard let data = string.data(using: .utf8) else { return }
		self.write(data)
	}
}
func stdout(_ string: String, terminator: String = "\n") {
	var stream = FileHandle.standardOutput
	print(string, terminator: terminator, to: &stream)
}
func stderr(_ string: String, terminator: String = "\n") {
	var stream = FileHandle.standardError
	print(string, terminator: terminator, to: &stream)
}


func exit(error string: String, noPrefix: Bool = false) -> Never {
	stderr(noPrefix ? string : ("Error:  " + string))
	exit(1)
}
