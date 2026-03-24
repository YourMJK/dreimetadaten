//
//  HTML.swift
//  dreimetadaten
//
//  Created by YourMJK on 11.03.26.
//

import OrderedCollections

enum HTML {
	protocol Content {
		func serialize(into result: inout String, indentation: String)
	}
	
	class Node: Content {
		let tag: String
		var attributes: OrderedDictionary<String, String>
		var content: [Content]
		var indent: Bool = false
		
		init(tag: String, attributes: OrderedDictionary<String, String> = [:], content: [Content] = []) {
			self.tag = tag
			self.attributes = attributes
			self.content = content
		}
		
		@discardableResult func content(_ element: () -> Content) -> Self {
			content.append(element())
			return self
		}
		@discardableResult func content(_ elements: () -> [Content]) -> Self {
			content.append(contentsOf: elements())
			return self
		}
		
		@discardableResult func attribute(key: String, value: String) -> Self {
			attributes[key] = value
			return self
		}
		
		@discardableResult func indent(_ value: Bool = true) -> Self {
			indent = value
			return self
		}
		
		
		private var openingTag: String {
			let suffix: String
			if attributes.isEmpty {
				suffix = ""
			} else {
				let pairs = attributes.map {
					"\($0.key)=\"\($0.value)\""
				}
				suffix = " \(pairs.joined(separator: " "))"
			}
			return "<\(tag)\(suffix)>"
		}
		private var closingTag: String {
			"</\(tag)>"
		}
		
		func serialize(into result: inout String, indentation: String = "") {
			result.append(openingTag)
			
			guard !content.isEmpty else { return }
			if indent {
				let nextIndentation = "\(indentation)\t"
				content.forEach {
					result.append("\n\(nextIndentation)")
					$0.serialize(into: &result, indentation: nextIndentation)
				}
				result.append("\n\(indentation)")
			} else {
				content.forEach {
					$0.serialize(into: &result, indentation: indentation)
				}
			}
			
			result.append(closingTag)
		}
		
		func serialize(indentation: String = "") -> String {
			var result = ""
			serialize(into: &result, indentation: indentation)
			return result
		}
	}
}

extension String: HTML.Content {
	func serialize(into result: inout String, indentation: String) {
		result.append(self)
	}
}


extension HTML {
	static func table() -> Node { Node(tag: "table") }
	static func thead() -> Node { Node(tag: "thead") }
	static func tbody() -> Node { Node(tag: "tbody") }
	static func tr() -> Node { Node(tag: "tr") }
	static func th() -> Node { Node(tag: "th") }
	static func td() -> Node { Node(tag: "td") }
	static func br() -> Node { Node(tag: "br") }
	static func p() -> Node { Node(tag: "p") }
	static func b() -> Node { Node(tag: "b") }
	static func i() -> Node { Node(tag: "i") }
	static func a() -> Node { Node(tag: "a") }
	static func img() -> Node { Node(tag: "img") }
	static func div() -> Node { Node(tag: "div") }
	static func span() -> Node { Node(tag: "span") }
	static func code() -> Node { Node(tag: "code") }
	static func pre() -> Node { Node(tag: "pre") }
	static func ul() -> Node { Node(tag: "ul") }
	static func li() -> Node { Node(tag: "li") }
	static func details() -> Node { Node(tag: "details") }
	static func summary() -> Node { Node(tag: "summary") }
	static func h(_ n: UInt) -> Node { Node(tag: "h\(n)") }
}

extension HTML.Node {
	@discardableResult func id(_ value: String) -> Self { return attribute(key: "id", value: value) }
	@discardableResult func `class`(_ value: String) -> Self { return attribute(key: "class", value: value) }
	@discardableResult func src(_ value: String) -> Self { return attribute(key: "src", value: value) }
	@discardableResult func href(_ value: String) -> Self { return attribute(key: "href", value: value) }
}
