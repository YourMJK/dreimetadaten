//
//  MetadataExporter.WebDir.swift
//  D3F-MetadataExporter
//
//  Created by YourMJK on 12.04.21.
//  Copyright © 2021 YourMJK. All rights reserved.
//

import Foundation


extension MetadataExporter {
	enum WebDir {
		
		static func export(_ höreinheit: Höreinheit, type: CollectionType, to baseDirectory: URL) throws {
			func recursive(_ höreinheit: Höreinheit, to baseDirectory: URL) throws {
				stdout("> \(baseDirectory.path)")
				guard MetadataExporter.createDirectoryIfNeccessary(at: baseDirectory) else {
					return
				}
				
				func writeFile(filename: String, content: String) throws {
					let fileURL = baseDirectory.appendingPathComponent(filename)
					try content.write(to: fileURL, atomically: true, encoding: .utf8)
				}
				
				// Create metadata.json file
				let jsonString = try Metadata.createJSONString(of: höreinheit)
				try writeFile(filename: "metadata.json", content: jsonString)
				
				// Create *.url files
				func urlFileContent(name: String, url: String) -> String {
					return "[\(name)]\nURL=\(url)\n"
				}
				if let links = höreinheit.links {
					if let itunesURL = links.cover_itunes {
						try writeFile(filename: "cover_itunes.url", content: urlFileContent(name: "iTunes-URL", url: itunesURL))
					}
					if let kosmosURL = links.cover_kosmos {
						try writeFile(filename: "cover_kosmos.url", content: urlFileContent(name: "Kosmos-URL", url: kosmosURL))
					}
				}
				
				// Handle teile
				if let teile = höreinheit.teile {
					for teil in teile {
						let teilURL = baseDirectory.appendingPathComponent(String(teil.teilNummer))
						try recursive(teil, to: teilURL)
					}
				}
			}
			try recursive(höreinheit, to: baseDirectory)
			
			let ffmetadata = FFmetadata.create(forCollectionItem: höreinheit, type: type)
			
			// Create ffmetadata.txt file if links.ffmetadata exists
			func writeFile(ffmetadata: FFmetadata, at url: URL, for höreinheit: Höreinheit) throws {
				guard höreinheit.links?.ffmetadata != nil else {
					return
				}
				let content = ffmetadata.formattedContent
				let filename = "ffmetadata.txt"
				let fileURL = url.appendingPathComponent(filename)
				try content.write(to: fileURL, atomically: true, encoding: .utf8)
			}
			
			// Base
			try writeFile(ffmetadata: ffmetadata.base, at: baseDirectory, for: höreinheit)
			
			// Teile
			if let teile = höreinheit.teile, let ffmetadataTeile = ffmetadata.teile {
				try zip(teile, ffmetadataTeile).forEach { (teil, ffmetadata) in
					let teilURL = baseDirectory.appendingPathComponent(String(teil.teilNummer))
					try writeFile(ffmetadata: ffmetadata, at: teilURL, for: teil)
				}
			}
		}
		
	}
}
