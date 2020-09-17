//
//  CommandLine.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 24.10.18.
//  Copyright © 2018 YourMJK. All rights reserved.
//

import Foundation


let ProgramName = URL(fileURLWithPath: CommandLine.arguments.first!).lastPathComponent


func stdout(_ string: String) {
    FileHandle.standardOutput.write(string.appending("\n").data(using: .utf8)!)
}
func stderr(_ string: String) {
    FileHandle.standardError.write(string.appending("\n").data(using: .utf8)!)
}


func exit(error string: String, noPrefix: Bool = false) -> Never {
    stderr(noPrefix ? string : ("Error:  " + string))
    exit(1)
}
