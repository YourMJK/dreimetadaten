//
//  URL.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.05.26.
//

import Foundation

extension URL {
	func relativePath(toDirectory base: URL) -> String {
		let destComponents = self.standardizedFileURL.pathComponents
		let baseComponents = base.standardizedFileURL.pathComponents
		var index = 0
		while index < destComponents.count && index < baseComponents.count && destComponents[index] == baseComponents[index] {
			index += 1
		}
		var relComponents = Array(repeating: "..", count: baseComponents.count - index)
		relComponents.append(contentsOf: destComponents[index...])
		return relComponents.joined(separator: "/")
	}
	
	var absolutePath: String {
		self.absoluteURL.path(percentEncoded: false)
	}
}
