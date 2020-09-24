//
//  MetadataExporter.swift
//  D3F-MetadataExporter
//
//  Created by Max-Joseph on 24.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


class MetadataExporter {
	
	enum OutputType: String {
		case json = "json"
	}
	
	
	var metadata: Metadata
	
	
	convenience init(withMasterFile file: URL) {
		self.init(metadata: Self.parseJSON(url: file))
	}
	init(metadata: Metadata) {
		self.metadata = metadata
	}
	
	
	static func parseJSON(url: URL) -> Metadata {
		do {
			let jsonData = try Data(contentsOf: url)
			return try parseJSON(data: jsonData)
		}
		catch {
			exit(error: "Couldn't parse JSON file \"\(url.path)\":  \(error.localizedDescription)")
		}
	}
	static func parseJSON(data jsonData: Data) throws -> Metadata {
		let jsonDecoder = JSONDecoder()
		let metadata = try jsonDecoder.decode(Metadata.self, from: jsonData)
		return metadata
	}
	
	
	
	func exportMetadata(to: URL, outputType: OutputType) {
		//TODO
	}
	
}
