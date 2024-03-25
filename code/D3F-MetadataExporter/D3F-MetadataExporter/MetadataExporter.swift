//
//  MetadataExporter.swift
//  D3F-MetadataExporter
//
//  Created by YourMJK on 24.09.20.
//  Copyright © 2020 YourMJK. All rights reserved.
//

import Foundation


class MetadataExporter {
	
	enum OutputType: String {
		case webDir = "webDir"
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
	
	
	
	func exportMetadata(to baseURL: URL, outputType: OutputType) {
		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: baseURL.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
			exit(error: "No such directory \"\(baseURL.path)\"")
		}
		
		for collectionType in CollectionType.allCases {
			guard let collection = metadata[keyPath: collectionType.metadataKeyPath] as? [Höreinheit] else { continue }
			
			let collectionURL = baseURL.appendingPathComponent(collectionType.fileName, isDirectory: true)
			guard Self.createDirectoryIfNeccessary(at: collectionURL) else {
				exit(1)
			}
			
			let numberOfDigts: UInt = {
				var number = collection.count
				var orderOfMagnitude: UInt = 0
				while number != 0 {
					orderOfMagnitude += 1
					number /= 10
				}
				return orderOfMagnitude
			}()
			
			for höreinheit in collection {
				
				// Generate directory name for the höreinheit
				let name: String = {
					func formatTitle(_ title: String?) -> String {
						guard title != nil else {
							exit(error: "Missing title for \(höreinheit)")
						}
						let replacements: [Character: String] = [
							"ä": "ae",
							"Ä": "Ae",
							"ö": "oe",
							"Ö": "Oe",
							"ü": "ue",
							"Ü": "Ue",
							"ß": "ss",
							" ": "-",
							".": "",
							":": "",
							",": "",
							";": "",
						]
						var formattedTitle = ""
						for character in title! {
							if let replacement = replacements[character] {
								formattedTitle.append(replacement)
							}
							else {
								formattedTitle.append(character)
							}
						}
						return formattedTitle
					}
					
					if let folge = höreinheit as? Folge {
						if folge.nummer >= 0 {
							return String(format: "%0\(numberOfDigts)d", folge.nummer)
						}
						return formatTitle(folge.titel)
					}
					return formatTitle(höreinheit.titel)
				}()
				let url = collectionURL.appendingPathComponent(name, isDirectory: true)
				
				// Export metadata of höreinheit
				do {
					switch outputType {
						case .webDir: try WebDir.export(höreinheit, type: collectionType, to: url)
					}
				}
				catch {
					stderr("Error: Couldn't export metadata for \"\(höreinheit.titel ?? "(nil)")\": \(error)")
				}
				
			}
			
			// Export metadata of collection as JSON
			do {
				var maskedMetadata = Metadata()
				switch collectionType.metadataKeyPath {
					case let keyPath as WritableKeyPath<Metadata, [Folge]?>:
						maskedMetadata[keyPath: keyPath] = metadata[keyPath: keyPath]
					case let keyPath as WritableKeyPath<Metadata, [Höreinheit]?>:
						maskedMetadata[keyPath: keyPath] = metadata[keyPath: keyPath]
					default:
						fatalError("Unrecognized type for CollectionType.metadataKeyPath")
				}
				
				let jsonURL = baseURL.appendingPathComponent("\(collectionType.fileName).json")
				stdout("> \(jsonURL.path)")
				let jsonString = try Metadata.createJSONString(of: maskedMetadata)
				try jsonString.write(to: jsonURL, atomically: true, encoding: .utf8)
			}
			catch {
				stderr("Error: Couldn't export metadata for \"\(collectionType)\": \(error)")
			}
		}
	}
	
	
	
	static func createDirectoryIfNeccessary(at url: URL) -> Bool {
		do {
			try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
		}
		catch {
			stderr("Error:  Couldn't create directory at \"\(url.path)\": \(error)")
			return false
		}
		return true
	}
	
}
