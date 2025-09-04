//
//  LinkTester.CheckMethod.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation


extension LinkTester {
	protocol CheckMethod {
		func check(url: URL) async throws -> (Bool, StatusCode?)
	}
}


extension LinkTester {
	enum MetadataCheckMethod: CheckMethod {
		case headWith2XX
		case getWith2XX
		case custom(httpMethod: String, statusCodeCheck: (StatusCode) -> Bool)
		
		
		var httpMethod: String {
			switch self {
				case .headWith2XX:
					"HEAD"
				case .getWith2XX:
					"GET"
				case .custom(let httpMethod, _):
					httpMethod
			}
		}
		
		func isValid(statusCode: StatusCode) -> Bool {
			switch self {
				case .headWith2XX, .getWith2XX:
					statusCode.class == .successful
				case .custom(_, let statusCodeCheck):
					statusCodeCheck(statusCode)
			}
		}
		
		func check(url: URL) async throws -> (Bool, StatusCode?) {
			var request = URLRequest(url: url)
			request.httpMethod = httpMethod
			// Default User-Agent works fine while the following custom one is "outdated"
			//request.setValue("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0", forHTTPHeaderField: "User-Agent")
			
			// Send request, retrieve status code and ignore body data
			let (bytes, response) = try await URLSession.shared.bytes(for: request)
			bytes.task.cancel()
			guard let httpResponse = response as? HTTPURLResponse else {
				throw RequestError.noHTTPResponse
			}
			guard let statusCode = StatusCode(httpResponse.statusCode) else {
				throw RequestError.invalidStatusCode
			}
			
			// Check status code
			let isValid = isValid(statusCode: statusCode)
			
			return (isValid, statusCode)
		}
		
	}
}
