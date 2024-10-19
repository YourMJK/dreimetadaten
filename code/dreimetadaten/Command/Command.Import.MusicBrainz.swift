//
//  Command.Import.MusicBrainz.swift
//  dreimetadaten
//
//  Created by YourMJK on 10.10.24.
//

import Foundation
import CommandLineTool
import ArgumentParser
import GRDB


extension Command.Import {
	struct MusicBrainz: ParsableCommand {
		static let configuration = CommandConfiguration(
			commandName: "mb",
			abstract: "Import data from MusicBrainz.",
			alwaysCompactUsageOptions: true
		)
		
		@Option(name: .customLong("hörspielID"), help: ArgumentHelp("The \"hörspielID\" of the recipient \"hörspiel\" to import data to.", valueName: "id"))
		var hörspielID: MetadataRelationalModel.Hörspiel.ID
		
		@Option(name: .customLong("discID"), help: ArgumentHelp("The MusicBrainz Disc-ID to read track data from.", valueName: "id"))
		var mbDiscID: String
		
		@Option(name: .long, help: ArgumentHelp("The position of the medium in the release and of the new \"medium\" to create.", valueName: "number"))
		var position: UInt = 1
		
		@Option(name: .customLong("db"), help: ArgumentHelp("The path to the SQLite database file.", valueName: "sqlite file"))
		var databaseFilePath: String = Command.databaseFile.relativePath
		
		func run() throws {
			let dbQueue = try DatabaseQueue(path: databaseFilePath)
			try dbQueue.write { db in
				let importer = MusicBrainzImporter(db: db)
				try importer.addMedium(to: hörspielID, at: position, usingDisc: mbDiscID)
			}
		}
	}
}
