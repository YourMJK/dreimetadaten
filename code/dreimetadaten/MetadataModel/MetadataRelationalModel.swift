//
//  MetadataRelationalModel.swift
//  dreimetadaten
//
//  Created by YourMJK on 29.03.24.
//

import Foundation


struct MetadataRelationalModel {
	var serie: [Folge]
	var spezial: [HörspielRef]
	var kurzgeschichten: [HörspielRef]
	var dieDr3i: [Folge]
	
	var hörspiel: [Hörspiel]
	var hörspielTeil: [HörspielTeil]
	
	var medium: [Medium]
	var track: [Track]
	var kapitel: [Kapitel]
	
	var person: [Person]
	var pseudonym: [Pseudonym]
	var rolle: [Rolle]
	var sprechrolle: [Sprechrolle]
	var spricht: [Spricht]
	
	var hörspielBuchautor: [HörspielBuchautor]
	var hörspielSkriptautor: [HörspielSkriptautor]
}


extension MetadataRelationalModel {
	
	struct Folge: Codable {
		var nummer: Int
		
		var hörspielID: Hörspiel.ID
	}
	
	struct HörspielRef: Codable {
		var hörspielID: Hörspiel.ID
	}
	
	
	struct Hörspiel: Codable {
		typealias ID = UInt
		var hörspielID: ID
		
		var titel: String?
		var beschreibung: String?
		var veröffentlichungsdatum: String?
		var unvollständig: Bool
		var cover: Bool
		var urlCoverApple: String?
		var urlCoverKosmos: String?
	}
	
	struct HörspielTeil: Codable {
		var hörspiel: Hörspiel.ID
		var teil: Hörspiel.ID
		
		var position: UInt
		var buchstabe: String?
	}
	
	
	struct Medium: Codable {
		typealias ID = UInt
		var mediumID: ID
		
		var hörspielID: Hörspiel.ID
		var position: UInt
		var xldLog: Bool
	}
	
	struct Track: Codable {
		typealias ID = UInt
		var trackID: ID
		
		var mediumID: Medium.ID
		var position: UInt
		var titel: String
		var dauer: UInt
	}
	
	struct Kapitel: Codable {
		var trackID: Track.ID
		
		var hörspielID: Hörspiel.ID
		var position: UInt
		var abweichenderTitel: String?
	}
	
	
	struct Person: Codable {
		typealias ID = UInt
		var personID: ID
		
		var name: String
	}
	
	struct Pseudonym: Codable {
		typealias ID = UInt
		var pseudonymID: ID
		
		var name: String
	}
	
	struct Rolle: Codable {
		typealias ID = UInt
		var rolleID: ID
		
		var name: String
	}
	
	struct Sprechrolle: Codable {
		typealias ID = UInt
		var sprechrolleID: ID
		
		var hörspielID: Hörspiel.ID
		var rolleID: Rolle.ID
		var position: UInt
	}
	
	struct Spricht: Codable {
		var sprechrolleID: Sprechrolle.ID
		var personID: Person.ID
		
		var pseudonymID: Pseudonym.ID?
	}
	
	
	struct HörspielBuchautor: Codable {
		var hörspielID: Hörspiel.ID
		var buchautor: Person.ID
	}
	
	struct HörspielSkriptautor: Codable {
		var hörspielID: Hörspiel.ID
		var skriptautor: Person.ID
	}
	
}
