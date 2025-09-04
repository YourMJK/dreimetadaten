//
//  LinkTester.LinkType.swift
//  dreimetadaten
//
//  Created by YourMJK on 03.09.25.
//

import Foundation


extension LinkTester {
	enum LinkType: Equatable, Hashable, CaseIterable {
		case cover_itunes
		case cover_kosmos
		case dreifragezeichen
		case appleMusic
		case spotify
		case bookbeat
		//case amazonMusic
		case amazon
		//case youTubeMusic
		case deezer
		
		
		var keyPath: KeyPath<MetadataObjectModel.Links, String?> {
			switch self {
				case .cover_itunes: \.cover_itunes
				case .cover_kosmos: \.cover_kosmos
				case .dreifragezeichen: \.dreifragezeichen
				case .appleMusic: \.appleMusic
				case .spotify: \.spotify
				case .bookbeat: \.bookbeat
				//case .amazonMusic: \.amazonMusic
				case .amazon: \.amazon
				//case .youTubeMusic: \.youTubeMusic
				case .deezer: \.deezer
			}
		}
		
		var checkMethod: CheckMethod {
			switch self {
				//case .amazonMusic, .youTubeMusic: fatalError("Check method not implemented")
				default: .is2XX
			}
		}
		
		var checkInterval: TimeInterval {
			switch self {
				default: 0.25
			}
		}
		
	}
}
