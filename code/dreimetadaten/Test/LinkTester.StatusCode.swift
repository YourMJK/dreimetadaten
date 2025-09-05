//
//  LinkTester.StatusCode.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

extension LinkTester {
	struct StatusCode {
		let value: UInt16
		
		init?(_ value: Int) {
			guard value >= 100, value < 1000 else {
				return nil
			}
			self.value = UInt16(value)
		}
		
		var numericClass: UInt8 {
			UInt8(value / 100)
		}
		var `class`: Class? {
			Class(rawValue: numericClass)
		}
		
		enum Class: UInt8 {
			case informational = 1
			case successful = 2
			case redirection = 3
			case clientError = 4
			case serverError = 5
		}
	}
}
