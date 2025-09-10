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
	let syntaxOnly: Bool
	let retries: UInt
	private let clock: ContinuousClock
	
	init(objectModel: MetadataObjectModel, syntaxOnly: Bool = false, retries: UInt = 0) {
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
		self.syntaxOnly = syntaxOnly
		self.retries = retries
		self.clock = ContinuousClock()
	}
	
	
	func test(linkTypes: Set<LinkType>, progressHandler: ProgressHandler) async {
		await withTaskGroup(of: Void.self) { group in
			for linkType in linkTypes {
				group.addTask {
					do {
						try await test(linkType: linkType) { progress in
							await progressHandler.update(progress: progress, for: linkType)
						} failedLink: { result in
							await progressHandler.failedLink(type: linkType, result: result)
						}
						await progressHandler.completed(type: linkType)
						await progressHandler.update(progress: nil, for: linkType)
					}
					catch {
						await progressHandler.failedType(error: error)
						await progressHandler.update(progress: nil, for: linkType)
					}
				}
			}
		}
	}
	
	func test(linkType: LinkType, startIndex: UInt = 0, progress: (Progress) async -> Void, failedLink: (Result) async -> Void) async throws {
		let checkMethod = linkType.checkMethod
		let interval: ContinuousClock.Duration = .seconds(linkType.checkInterval)
		var lastRequest: ContinuousClock.Instant?
		
		// Verify that test cases work before continuing
		try await verifyTestCase(linkType: linkType, checkMethod: checkMethod, lastRequest: &lastRequest)
		
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
				await failedLink((hörspielID, urlString, nil))
				continue
			}
			guard !syntaxOnly else {
				continue
			}
			
			await progress((index, filteredItems.count, (hörspielID, url)))
			
			do {
				let (isValid, statusCode) = try await check(url: url, method: checkMethod, lastRequest: &lastRequest, interval: interval)
				if !isValid {
					await failedLink((hörspielID, urlString, statusCode))
				}
			}
			catch {
				await failedLink((hörspielID, urlString, nil))
			}
		}
		
		await progress((filteredItems.count, filteredItems.count, nil))
	}
	
	func verifyTestCase(linkType: LinkType, checkMethod: CheckMethod, lastRequest: inout ContinuousClock.Instant?) async throws {
		guard let testCase = TestCase.all[linkType] else {
			return
		}
		let interval: ContinuousClock.Duration = .seconds(linkType.checkInterval)
		
		func checkCase(url urlString: String, shouldPass: Bool) async throws {
			var result: (isValid: Bool, statusCode: StatusCode)?
			if let url = URL(string: urlString) {
				result = try? await check(url: url, method: checkMethod, lastRequest: &lastRequest, interval: interval)
			}
			guard let result, result.isValid == shouldPass else {
				throw MethodError.testCaseFailed(linkType: linkType, url: urlString, shouldPass: shouldPass, statusCode: result?.statusCode)
			}
		}
		try await checkCase(url: testCase.valid, shouldPass: true)
		try await checkCase(url: testCase.invalid, shouldPass: false)
	}
	
	
	private func check(url: URL, method: CheckMethod, lastRequest: inout ContinuousClock.Instant?, interval: ContinuousClock.Duration) async throws -> (Bool, StatusCode) {
		var result: (isValid: Bool, statusCode: StatusCode)
		var remainingTries = retries + 1
		
		repeat {
			// Wait before next request to respect rate limits
			await nextRequestInstant(lastRequest: &lastRequest, interval: interval)
			
			// Check URL
			result = try await method.check(url: url)
			guard !result.isValid else { break }
			
			remainingTries -= 1
		}
		while remainingTries > 0
		
		return result
	}
	
	private func nextRequestInstant(lastRequest: inout ContinuousClock.Instant?, interval: ContinuousClock.Duration) async {
		if let lastRequest {
			try? await Task.sleep(until: lastRequest + interval, clock: clock)
		}
		lastRequest = .now
	}
	
}


extension LinkTester {
	typealias Progress = (checked: Int, total: Int, current: (hörspielID: UInt, url: URL)?)
	typealias Result = (hörspielID: UInt, url: String, statusCode: StatusCode?)
	
	actor ProgressHandler {
		var progressPerLinkType = [LinkType: Progress]()
		private let progressCallback: ([LinkType: Progress]) -> Void
		private let failedLinkCallback: (LinkType, Result) -> Void
		private let failedTypeCallback: (Error) -> Void
		private let completedCallback: (LinkType) -> Void
		
		init(progress: @escaping ([LinkType : Progress]) -> Void, failedLink: @escaping (LinkType, Result) -> Void, failedType: @escaping (Error) -> Void, completed: @escaping (LinkType) -> Void) {
			self.progressCallback = progress
			self.failedLinkCallback = failedLink
			self.failedTypeCallback = failedType
			self.completedCallback = completed
		}
		
		func update(progress: Progress?, for linkType: LinkType) {
			progressPerLinkType[linkType] = progress
			progressCallback(progressPerLinkType)
		}
		func failedLink(type: LinkType, result: Result) {
			failedLinkCallback(type, result)
		}
		func failedType(error: Error) {
			failedTypeCallback(error)
		}
		func completed(type: LinkType) {
			completedCallback(type)
		}
	}
	
	enum DatasetError: LocalizedError {
		case missingHörspielID
		
		var errorDescription: String? {
			switch self {
				case .missingHörspielID:
					return "An item is missing a hörspielID"
			}
		}
	}
	
	enum MethodError: LocalizedError {
		case urlTransformFailed(url: URL)
		case testCaseFailed(linkType: LinkType, url: String, shouldPass: Bool, statusCode: StatusCode?)
		
		var errorDescription: String? {
			switch self {
				case .urlTransformFailed(let url):
					"Transforming URL failed: \(url)"
				case .testCaseFailed(let linkType, let url, let shouldPass, let statusCode):
					"""
					Test case for \"\(linkType)\" failed (\(url), expected: \(shouldPass), response: \(statusCode.map { "\($0.value)" } ?? "-")).
					Aborting because results for this link type may be misleading. Try again or fix method/test case.
					"""
			}
		}
	}
	
	enum RequestError: LocalizedError {
		case noHTTPResponse
		case invalidStatusCode
		case invalidBodyData
		
		var errorDescription: String? {
			switch self {
				case .noHTTPResponse:
					return "Response is not a HTTPURLResponse"
				case .invalidStatusCode:
					return "Response contains an invalid status code"
				case .invalidBodyData:
					return "Response contains invalid body data"
			}
		}
	}
}
