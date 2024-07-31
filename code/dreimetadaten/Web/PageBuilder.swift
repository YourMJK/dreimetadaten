//
//  PageBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation


class PageBuilder {
	private(set) var content: String
	
	init(templateFile: URL) throws {
		self.content = try String(contentsOf: templateFile, encoding: .utf8)
	}
	
	func build() throws {
		try replaceDatePlaceholder()
	}
	
	func replace(placeholder: String, with replacement: String) throws {
		guard content.contains(placeholder) else {
			throw BuildingError.missingPlaceholderInTemplate(placeholder: placeholder)
		}
		content = content.replacingOccurrences(of: placeholder, with: replacement)  // despite copy overhead, 10x faster than range(of:) + mutating replaceSubrange()
	}
	
	private func replaceDatePlaceholder() throws {
		let placeholder = "%%date%%"
		
		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd.MM.yyyy"
		let dateString = dateFormatter.string(from: date)
		
		try replace(placeholder: placeholder, with: dateString)
	}
}


extension PageBuilder {
	enum BuildingError: LocalizedError {
		case missingPlaceholderInTemplate(placeholder: String)
		
		var errorDescription: String? {
			switch self {
				case .missingPlaceholderInTemplate(let placeholder):
					return "Content of given template file doesn't contain the placeholder \"\(placeholder)\""
			}
		}
	}
}
