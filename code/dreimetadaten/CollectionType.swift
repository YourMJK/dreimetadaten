//
//  CollectionType.swift
//  dreimetadaten
//
//  Created by YourMJK on 05.04.24.
//

import Foundation
import CommandLineTool


enum CollectionType: String, ArgumentEnum {
	case serie = "serie"
	case spezial = "spezial"
	case kurzgeschichten = "kurzgeschichten"
	case die_dr3i = "die_dr3i"
	
	var name: String {
		switch self {
			case .serie: return "Serie"
			case .spezial: return "Spezial"
			case .kurzgeschichten: return "Kurzgeschichten"
			case .die_dr3i: return "DiE DR3i"
		}
	}
	
	var fileName: String {
		switch self {
			case .die_dr3i: return "DiE_DR3i"
			default: return name
		}
	}
	
	var titlePrefix: String {
		let base = "Die drei ???"
		switch self {
			case .serie: return base
			case .die_dr3i: return name
			default: return "\(base) \(name)"
		}
	}
	
	var titleNummerFormat: String? {
		nummerFormat.map { "Nr. \($0)" }
	}
	var nummerFormat: String? {
		switch self {
			case .serie: return "%03d"
			case .die_dr3i: return "%d"
			default: return nil
		}
	}
	
	var objectModelKeyPath: PartialKeyPath<MetadataObjectModel> {
		switch self {
			case .serie: return \.serie
			case .spezial: return \.spezial
			case .kurzgeschichten: return \.kurzgeschichten
			case .die_dr3i: return \.die_dr3i
		}
	}
	
	var jsonFilePath: String {
		"metadata/json/\(fileName).json"
	}
	
	private var htmlFileName: String {
		switch self {
			case .serie: return "index"
			default: return rawValue
		}
	}
	var htmlFilePath: String {
		"web/\(htmlFileName).html"
	}
	var htmlTemplateFilePath: String {
		"web_templates/\(htmlFileName).html"
	}
}
