//
//  FileManager.swift
//  dreimetadaten
//
//  Created by YourMJK on 26.05.26.
//

import Foundation

extension FileManager {
	/// Returns a Boolean value that indicates whether a file or directory exists at a specified URL.
	func fileExists(at url: URL) -> Bool {
		fileExists(atPath: url.absolutePath)
	}
	
	/// Returns a Boolean value that indicates whether a file or directory exists at a specified URL.
	func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
		var _isDirectory: ObjCBool = false
		let result = fileExists(atPath: url.absolutePath, isDirectory: &_isDirectory)
		isDirectory = _isDirectory.boolValue
		return result
	}
	
	/// Creates a file with the specified content and attributes at the given location.
	func createFile(at url: URL, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
		createFile(atPath: url.absolutePath, contents: data, attributes: attr)
	}
	
	/// Creates a symbolic link that points to the specified destination.
	func createSymbolicLink(at url: URL, withDestinationPath destPath: String) throws {
		try createSymbolicLink(atPath: url.absolutePath, withDestinationPath: destPath)
	}
}
