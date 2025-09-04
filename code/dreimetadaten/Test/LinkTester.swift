//
//  LinkTester.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation
import CommandLineTool
import GRDB


struct LinkTester {
	let items: [MetadataObjectModel.Hörspiel]
	
	init(objectModel: MetadataObjectModel) {
		// Consider root items of every collection
		let rootItems = [objectModel.serie, objectModel.spezial, objectModel.kurzgeschichten, objectModel.die_dr3i, objectModel.kids, objectModel.sonstige]
			.compactMap { $0 }
			.joined()
			.reversed()
		var items = Array(rootItems)
		
		// Also consider teile of each item
		var teile = [MetadataObjectModel.Hörspiel]()
		for item in items {
			teile.append(contentsOf: item.teile ?? [])
		}
		items.append(contentsOf: teile)
		
		// Sort by hörspieldID in descending order (i.e. more recent items first)
		items.sort {
			$0.ids?.dreimetadaten ?? 0 > $1.ids?.dreimetadaten ?? 0
		}
		
		self.items = items
	}
	
	
	func test(linkType: LinkType, startIndex: UInt = 0, syntaxOnly: Bool = false, progress: (Progress) -> Void, failedLink: (Result) -> Void) async throws {
		let clock = ContinuousClock()
		let interval = ContinuousClock.Duration.seconds(linkType.checkInterval)
		
		// Filter only for items having linkType and skip items until startIndex
		let filteredItems = items.filter {
			guard let links = $0.links, let _ = links[keyPath: linkType.keyPath] else {
				return false
			}
			return true
		}
		let indices = filteredItems.indices.dropFirst(Int(startIndex))
		
		for index in indices {
			let item = filteredItems[index]
			
			// Get URL string and hörspielID
			guard let links = item.links, let urlString = links[keyPath: linkType.keyPath] else {
				continue
			}
			guard let hörspielID = item.ids?.dreimetadaten else {
				throw DatasetError.missingHörspielID
			}
			
			// Check if string is valid URL
			guard
				let components = URLComponents(string: urlString),
				components.scheme != nil,
				components.host != nil,
				let url = URL(string: urlString)
			else {
				failedLink((hörspielID, urlString, nil))
				continue
			}
			guard !syntaxOnly else {
				continue
			}
			
			progress((index, filteredItems.count, (hörspielID, url)))
			let requestInstant = clock.now
			
			do {
				// Check URL
				let (isValid, statusCode) = try await linkType.checkMethod.check(url: url)
				
				if !isValid {
					failedLink((hörspielID, urlString, statusCode))
				}
			}
			catch {
				failedLink((hörspielID, urlString, nil))
			}
			
			// Wait before next request to respect rate limits
			try? await Task.sleep(until: requestInstant + interval, clock: clock)
		}
		
		progress((filteredItems.count, filteredItems.count, nil))
	}
}


extension LinkTester {
	typealias Progress = (checked: Int, total: Int, current: (hörspielID: UInt, url: URL)?)
	typealias Result = (hörspielID: UInt, url: String, statusCode: StatusCode?)
	
	enum DatasetError: LocalizedError {
		case missingHörspielID
		
		var errorDescription: String? {
			switch self {
				case .missingHörspielID:
					return "An item is missing a hörspielID"
			}
		}
	}
	
	enum RequestError: LocalizedError {
		case noHTTPResponse
		case invalidStatusCode
		
		var errorDescription: String? {
			switch self {
				case .noHTTPResponse:
					return "Response is not a HTTPURLResponse"
				case .invalidStatusCode:
					return "Response contains an invalid status code"
			}
		}
	}
}
