//
//  LinkTester.CheckMethod.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//


extension LinkTester {
	enum CheckMethod {
		case is2XX
		
		func isValid(statusCode: StatusCode) -> Bool {
			switch self {
				case .is2XX:
					return statusCode.class == .successful
			}
		}
	}
}
