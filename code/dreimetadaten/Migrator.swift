//
//  Migrator.swift
//  dreimetadaten
//
//  Created by YourMJK on 29.03.24.
//

import Foundation
import CommandLineTool


class Migrator {
	var objectModel: MetadataObjectModel
	var relationalModel: MetadataRelationalModel
	
	private var personDict = [String: Int]()
	private var pseudonymDict = [String: Int]()
	private var rolleDict = [String: Int]()
	private var tracksDict = [MetadataRelationalModel.Hörspiel.ID: [Int]]()
	
	init(objectModel: MetadataObjectModel) {
		self.objectModel = objectModel
		self.relationalModel = .init(
			serie: [],
			spezial: [],
			kurzgeschichten: [],
			dieDr3i: [],
			hörspiel: [],
			hörspielTeil: [],
			medium: [],
			track: [],
			kapitel: [],
			person: [],
			pseudonym: [],
			rolle: [],
			sprechrolle: [],
			spricht: [],
			hörspielBuchautor: [],
			hörspielSkriptautor: []
		)
	}
	
	
	func migrate() throws {
		var objectHörspiele = [(hörspiel: MetadataObjectModel.Hörspiel, collection: CollectionType)]()
		func add(collection: [MetadataObjectModel.Hörspiel]?, type: CollectionType) {
			objectHörspiele.append(contentsOf: collection?.map { ($0, type) } ?? [])
		}
		
		add(collection: objectModel.serie, type: .serie)
		add(collection: objectModel.spezial, type: .spezial)
		add(collection: objectModel.kurzgeschichten, type: .kurzgeschichten)
		add(collection: objectModel.die_dr3i, type: .die_dr3i)
		objectHörspiele.sort {
			$0.hörspiel.veröffentlichungsdatum! < $1.hörspiel.veröffentlichungsdatum!
		}
		
		try objectHörspiele.forEach {
			let hörspielID = try migrate(hörspiel: $0.hörspiel)!
			stderr("Migrated to \(hörspielID): \($0.hörspiel.titel ?? "nil")")
			
			switch $0.collection {
				case .serie:
					let objectFolge = $0.hörspiel as! MetadataObjectModel.Folge
					relationalModel.serie.append(.init(
						nummer: objectFolge.nummer,
						hörspielID: hörspielID
					))
				
				case .spezial:
					relationalModel.spezial.append(.init(hörspielID: hörspielID))
				
				case .kurzgeschichten:
					relationalModel.kurzgeschichten.append(.init(hörspielID: hörspielID))
				
				case .die_dr3i:
					let objectFolge = $0.hörspiel as! MetadataObjectModel.Folge
					relationalModel.dieDr3i.append(.init(
						nummer: objectFolge.nummer,
						hörspielID: hörspielID
					))
			}
		}
	}
	
	
	private func migrate(hörspiel objectItem: MetadataObjectModel.Hörspiel, rootHörspielID: MetadataRelationalModel.Hörspiel.ID? = nil) throws -> MetadataRelationalModel.Hörspiel.ID? {
		let isSingle = objectItem.teile == nil && rootHörspielID == nil
		let isMedium = objectItem.links?.xld_log != nil || (isSingle && !(objectItem.unvollständig ?? false))
		let isMediumOnly = isMedium && rootHörspielID != nil
		
		var relationalItem: MetadataRelationalModel.Hörspiel?
		if !isMediumOnly {
			// Hörspiel
			guard let titel = objectItem.titel else {
				throw MigrationError.missingTitel(hörspiel: objectItem)
			}
			
			let newID = (relationalModel.hörspiel.last?.hörspielID ?? 0) + 1
			relationalItem = MetadataRelationalModel.Hörspiel(
				hörspielID: newID,
				titel: titel,
				kurzbeschreibung: objectItem.kurzbeschreibung,
				beschreibung: objectItem.beschreibung,
				metabeschreibung: objectItem.metabeschreibung,
				veröffentlichungsdatum: objectItem.veröffentlichungsdatum,
				unvollständig: objectItem.unvollständig ?? false,
				cover: objectItem.links?.cover != nil,
				urlCoverApple: objectItem.links?.cover_itunes,
				urlCoverKosmos: objectItem.links?.cover_kosmos
			)
			relationalModel.hörspiel.append(relationalItem!)
			
			objectItem.autor.map(migrate(multiPerson:))?.forEach {
				relationalModel.hörspielBuchautor.append(.init(
					hörspielID: newID,
					buchautor: $0
				))
			}
			objectItem.hörspielskriptautor.map(migrate(multiPerson:))?.forEach {
				relationalModel.hörspielSkriptautor.append(.init(
					hörspielID: newID,
					skriptautor: $0
				))
			}
		}
		
		if isMedium {
			// Medium
			migrate(medium: objectItem, hörspielID: relationalItem?.hörspielID, rootHörspielID: rootHörspielID)
		}
		else if let objectTeil = objectItem as? MetadataObjectModel.Teil {
			// Teil
			relationalModel.hörspielTeil.append(.init(
				hörspiel: rootHörspielID!,
				teil: relationalItem!.hörspielID,
				position: objectTeil.teilNummer,
				buchstabe: objectTeil.buchstabe
			))
		}
		
		// Recursive teile
		if let teile = objectItem.teile {
			for teil in teile {
				_ = try migrate(hörspiel: teil, rootHörspielID: rootHörspielID ?? relationalItem!.hörspielID)
			}
		}
		
		// Kapitel
		if let objectKapitels = objectItem.kapitel, let relationalItem {
			try migrate(kapitels: objectKapitels, hörspielID: relationalItem.hörspielID, rootHörspielID: rootHörspielID)
		}
		
		// Sprechrollen
		if let objectSprechrollen = objectItem.sprechrollen, (isSingle || rootHörspielID != nil), let relationalItem {
			for (index, objectSprechrolle) in objectSprechrollen.enumerated() {
				try migrate(sprechrolle: objectSprechrolle, hörspielID: relationalItem.hörspielID, position: UInt(index+1))
			}
		}
		
		return relationalItem?.hörspielID
	}
	
	private func migrate(medium objectItem: MetadataObjectModel.Hörspiel, hörspielID: MetadataRelationalModel.Hörspiel.ID?, rootHörspielID: MetadataRelationalModel.Hörspiel.ID?) {
		let newID = (relationalModel.medium.last?.mediumID ?? 0) + 1
		let xldLog = objectItem.links?.xld_log != nil
		let relationalItem: MetadataRelationalModel.Medium
		if let objectTeil = objectItem as? MetadataObjectModel.Teil {
			relationalItem = .init(
				mediumID: newID,
				hörspielID: rootHörspielID!,
				position: objectTeil.teilNummer,
				xldLog: xldLog
			)
		}
		else {
			relationalItem = .init(
				mediumID: newID,
				hörspielID: hörspielID!,
				position: 1,
				xldLog: xldLog
			)
		}
		relationalModel.medium.append(relationalItem)
		for (index, objectKapitel) in objectItem.kapitel!.enumerated() {
			migrate(track: objectKapitel, mediumID: relationalItem.mediumID, position: UInt(index+1))
			let trackIndex = relationalModel.track.indices.last!
			tracksDict[rootHörspielID ?? hörspielID!, default: []].append(trackIndex)
		}
	}
	
	private func migrate(track objectItem: MetadataObjectModel.Kapitel, mediumID: MetadataRelationalModel.Hörspiel.ID, position: UInt) {
		let newID = (relationalModel.track.last?.trackID ?? 0) + 1
		let relationalItem = MetadataRelationalModel.Track(
			trackID: newID,
			mediumID: mediumID,
			position: position,
			titel: objectItem.titel,
			dauer: UInt(objectItem.end!-objectItem.start!)
		)
		relationalModel.track.append(relationalItem)
	}
	
	private func migrate(kapitels objectItems: [MetadataObjectModel.Kapitel], hörspielID: MetadataRelationalModel.Hörspiel.ID, rootHörspielID: MetadataRelationalModel.Hörspiel.ID?) throws {
		let tracks = tracksDict[rootHörspielID ?? hörspielID]!.map { relationalModel.track[$0] }
		for (index, objectItem) in objectItems.enumerated() {
			let kapitelDauer = UInt(objectItem.end! - objectItem.start!)
			let filteredTracks = tracks.filter {
				$0.titel.contains(objectItem.titel) && $0.dauer == kapitelDauer
			}
			guard let track = filteredTracks.first, filteredTracks.count == 1 else {
				throw MigrationError.missingOrMultipleTracks(kapitel: objectItem)
			}
			let kapitelTitel = (objectItem.titel != track.titel) ? objectItem.titel : nil
			if let kapitelTitel {
				stderr("Overriding track titel \"\(track.titel)\" with kapitel titel \"\(kapitelTitel)\"")
			}
			relationalModel.kapitel.append(.init(
				trackID: track.trackID,
				hörspielID: hörspielID,
				position: UInt(index+1),
				abweichenderTitel: kapitelTitel
			))
		}
	}
	
	private func migrate(multiPerson name: String) -> [MetadataRelationalModel.Person.ID] {
		let separators: [Character] = [",", "/"]
		
		var names = name
			.split {
				separators.contains($0)
			}
			.map {
				$0.trimmingCharacters(in: .whitespaces)
			}
		if name.contains("www.") {
			stderr("Not splitting name \"\(name)\"")
			names = [name]
		}
		else if names.count != 1 {
			stderr("Split name \"\(name)\" into \(names)")
		}
		return names.map { migrate(person: $0) }
	}
	private func migrateNameable<T>(name: String, array: inout [T], dict: inout [String: Int], idKeyPath: KeyPath<T, UInt>, constructor: (UInt, String) -> T) -> UInt {
		if let index = dict[name] {
			return (array[index])[keyPath: idKeyPath]
		}
		let newID = (array.last?[keyPath: idKeyPath] ?? 0) + 1
		let relationalItem = constructor(newID, name)
		array.append(relationalItem)
		dict[name] = array.indices.last!
		return relationalItem[keyPath: idKeyPath]
	}
	private func migrate(person name: String) -> MetadataRelationalModel.Person.ID {
		migrateNameable(
			name: name,
			array: &relationalModel.person,
			dict: &personDict,
			idKeyPath: \.personID,
			constructor: MetadataRelationalModel.Person.init(personID:name:)
		)
	}
	private func migrate(pseudonym name: String) -> MetadataRelationalModel.Pseudonym.ID {
		migrateNameable(
			name: name,
			array: &relationalModel.pseudonym,
			dict: &pseudonymDict,
			idKeyPath: \.pseudonymID,
			constructor: MetadataRelationalModel.Pseudonym.init(pseudonymID:name:)
		)
	}
	private func migrate(rolle name: String) -> MetadataRelationalModel.Rolle.ID {
		migrateNameable(
			name: name,
			array: &relationalModel.rolle,
			dict: &rolleDict,
			idKeyPath: \.rolleID,
			constructor: MetadataRelationalModel.Rolle.init(rolleID:name:)
		)
	}
	
	private func migrate(sprechrolle objectItem: MetadataObjectModel.Sprechrolle, hörspielID: MetadataRelationalModel.Hörspiel.ID, position: UInt) throws {
		let rolleID = migrate(rolle: objectItem.rolle)
		let personIDs = migrate(multiPerson: objectItem.sprecher)
		let pseudonymID = objectItem.pseudonym.map(migrate(pseudonym:))
		let newID = (relationalModel.sprechrolle.last?.sprechrolleID ?? 0) + 1
		let relationalItem = MetadataRelationalModel.Sprechrolle(
			sprechrolleID: newID,
			hörspielID: hörspielID,
			rolleID: rolleID,
			position: position
		)
		relationalModel.sprechrolle.append(relationalItem)
		precondition(!personIDs.isEmpty, "Empty sprecher after migration")
		if personIDs.count > 1 {
			guard pseudonymID == nil else {
				throw MigrationError.pseudonymWithMultiPerson(sprechrolle: objectItem)
			}
		}
		for personID in personIDs {
			relationalModel.spricht.append(.init(
				sprechrolleID: newID,
				personID: personID,
				pseudonymID: pseudonymID
			))
		}
	}
	
}


extension Migrator {
	enum MigrationError: LocalizedError {
		case missingTitel(hörspiel: MetadataObjectModel.Hörspiel)
		case missingOrMultipleTracks(kapitel: MetadataObjectModel.Kapitel)
		case pseudonymWithMultiPerson(sprechrolle: MetadataObjectModel.Sprechrolle)
		
		var errorDescription: String? {
			switch self {
				case .missingTitel(let hörspiel):
					var hörspielDump = String()
					dump(hörspiel, to: &hörspielDump, maxDepth: 2)
					return "Hörspiel has no titel:\n\(hörspielDump)"
				case .missingOrMultipleTracks(let kapitel):
					return "Found no or multiple tracks for kapitel: \(kapitel)"
				case .pseudonymWithMultiPerson(let sprechrolle):
					return "Sprechrolle contains pseudonym with multiple sprecher: \(sprechrolle)"
			}
		}
	}
}
