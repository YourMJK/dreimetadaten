//
//  LinkTester.CheckMethod.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation
import SwiftSoup


extension LinkTester {
	protocol CheckMethod {
		func check(url: URL) async throws -> (Bool, StatusCode)
	}
}


extension LinkTester {
	struct MetadataCheckMethod: CheckMethod {
		let httpMethod: String
		let statusCodeCheck: (StatusCode) -> Bool
		let urlTransform: ((URL) -> URL?)?
		let userAgent: String?
		
		static func headWith2XX(urlTransform: ((URL) -> URL?)? = nil, userAgent: String? = nil) -> Self {
			Self(httpMethod: "HEAD", statusCodeCheck: { $0.class == .successful }, urlTransform: urlTransform, userAgent: userAgent)
		}
		static func getWith2XX(urlTransform: ((URL) -> URL?)? = nil, userAgent: String? = nil) -> Self {
			Self(httpMethod: "GET", statusCodeCheck: { $0.class == .successful }, urlTransform: urlTransform, userAgent: userAgent)
		}
		
		
		func check(url: URL) async throws -> (Bool, StatusCode) {
			// Transform URL if specified
			let requestURL: URL
			if let urlTransform {
				guard let transformedURL = urlTransform(url) else {
					throw MethodError.urlTransformFailed(url: url)
				}
				requestURL = transformedURL
			} else {
				requestURL = url
			}
			
			var request = URLRequest(url: requestURL)
			request.httpMethod = httpMethod
			
			// Set custom User-Agent
			if let userAgent {
				request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
			}
			
			// Send request, retrieve status code and ignore body data
			let (bytes, response) = try await URLSession.shared.bytes(for: request)
			bytes.task.cancel()
//			let (bodyData, response) = try await URLSession.shared.data(for: request)
//			print(String(data: bodyData, encoding: .utf8)!)
			guard let httpResponse = response as? HTTPURLResponse else {
				throw RequestError.noHTTPResponse
			}
			guard let statusCode = StatusCode(httpResponse.statusCode) else {
				throw RequestError.invalidStatusCode
			}
			
			// Check status code
			let isValid = statusCodeCheck(statusCode)
			
			return (isValid, statusCode)
		}
		
	}
}


extension LinkTester {
	enum ContentCheckMethod: CheckMethod {
		case youTubeMusic
		
		
		private static let youTubePrivacyCookie = HTTPCookie(properties: [
			.domain: ".youtube.com",
			.path: "/",
			.name: "SOCS",
			.value: "CAESNQgREitib3FfaWRlbnRpdHlmcm9udGVuZHVpc2VydmVyXzIwMjQxMDE1LjA2X3AwGgJkZSACGgYIgO3LuAY",
			.secure: "TRUE",
			.discard: "TRUE",
			.maximumAge: "31536000",
			.sameSitePolicy: "Lax",
		])!
		
		
		private var userAgent: String? {
			switch self {
				case .youTubeMusic:
					UserAgent.generic
			}
		}
		
		private var cookie: HTTPCookie? {
			switch self {
				case .youTubeMusic:
					Self.youTubePrivacyCookie
			}
		}
		
		private func isValid(html: Document) throws -> Bool {
			switch self {
				case .youTubeMusic:
					// Check <title> value
					let title = try html.title()
					return title != "undefined"
			}
		}
		
		private func sendRequest(url: URL) async throws -> (Data, StatusCode) {
			var request = URLRequest(url: url)
			
			// Set custom User-Agent
			if let userAgent {
				request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
			}
			
			// Set necessary cookies
			if let cookie {
				HTTPCookieStorage.shared.setCookie(cookie)
			}
			
			// Send request and retrieve status code and body data
			let (bodyData, response) = try await URLSession.shared.data(for: request)
			guard let httpResponse = response as? HTTPURLResponse else {
				throw RequestError.noHTTPResponse
			}
			guard let statusCode = StatusCode(httpResponse.statusCode) else {
				throw RequestError.invalidStatusCode
			}
			
			return (bodyData, statusCode)
		}
		
		
		func check(url: URL) async throws -> (Bool, StatusCode) {
			let (bodyData, statusCode) = try await sendRequest(url: url)
			
			// Check for successful status code
			guard statusCode.class == .successful else {
				return (false, statusCode)
			}
			
			// Parse HTML
			guard let htmlDocument = try? SwiftSoup.parse(bodyData) else {
				throw RequestError.invalidBodyData
			}
			
			let isValid = try isValid(html: htmlDocument)
			
			return (isValid, statusCode)
		}
		
	}
}


extension LinkTester {
	enum UserAgent {
		// Default User-Agent works fine while the following custom one is often "outdated"
		static let generic = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0"
		
		static func urlSessionDynamicVersion(for date: Date = .now) -> String {
			let dateString = dynamicVersionDateFormatter.string(from: date)
			return urlSession(version: dateString)
		}
		static func urlSession(version: String) -> String {
			"dreimetadaten (\(version)) CFNetwork/1498.700.2 Darwin/23.6.0"
		}
		
		
		private static let dynamicVersionDateFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.dateFormat = "yyMMddHHmm"
			return formatter
		}()
	}
}
