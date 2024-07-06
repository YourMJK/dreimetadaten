//
//  JSONExporter.swift
//  dreimetadaten
//
//  Created by YourMJK on 07.07.24.
//

import Foundation
import GRDB


struct JSONExporter {
	let db: Database
	let webDataURL: URL
	
	func export(to outputDir: URL) throws {
		let objectModels = try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL).separateByCollectionType()
		
		for (objectModel, collectionType) in objectModels {
			let jsonURL = outputDir.appendingPathComponent("\(collectionType.fileName).json")
			let jsonString = try objectModel.jsonString()
			try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
		}
	}
}
