//
//  StringEnum.swift
//  D3F-MetadataCollector
//
//  Created by YourMJK on 05.05.21.
//  Copyright © 2021 YourMJK. All rights reserved.
//

import Foundation


extension RawRepresentable where RawValue == String, Self: CaseIterable {
	static var allCasesString: String {
		allCases.map { $0.rawValue }.joined(separator: " | ")
	}
} 
