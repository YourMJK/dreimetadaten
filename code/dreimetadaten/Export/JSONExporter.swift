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
		let objectModel = try MetadataObjectModel(fromDatabase: db, withBaseURL: webDataURL)
		
		for (objectModel, collectionType) in objectModel.separateByCollectionType(withDBInfo: true) {
			let jsonURL = outputDir.appendingPathComponent(collectionType.jsonFile)
			let jsonString = try objectModel.jsonString()
			try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
		}
		
		let jsonURL = outputDir.appendingPathComponent(CollectionType.allCasesJSONFile)
		let jsonString = try objectModel.jsonString()
		try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
	}
}
