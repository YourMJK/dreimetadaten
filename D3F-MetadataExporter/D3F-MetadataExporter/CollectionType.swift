//
//  CollectionType.swift
//  D3F-MetadataExporter
//
//  Created by YourMJK on 12.04.21.
//  Copyright © 2021 YourMJK. All rights reserved.
//

import Foundation


enum CollectionType: String {
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
	
	var nummerFormat: String? {
		switch self {
			case .serie: return "Nr. %03d"
			case .die_dr3i: return "Nr. %d"
			default: return nil
		}
	}
}
