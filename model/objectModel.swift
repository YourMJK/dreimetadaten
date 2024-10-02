struct MetadataObjectModel {
	var serie: [Folge]?
	var spezial: [Hörspiel]?
	var kurzgeschichten: [Hörspiel]?
	var die_dr3i: [Hörspiel]?
	var kids: [Hörspiel]?
}


class Hörspiel {
	var titel: String?
	var autor: String?
	var hörspielskriptautor: String?
	var kurzbeschreibung: String?
	var beschreibung: String?
	var metabeschreibung: String?
	var veröffentlichungsdatum: String?
	var kapitel: [Kapitel]?
	var sprechrollen: [Sprechrolle]?
	var links: Links?
	var ids: IDs?
	var unvollständig: Bool?
	var medien: [Medium]?
	var teile: [Teil]?
}

class Folge: Hörspiel {
	var nummer: UInt
}

class Teil: Hörspiel {
	var teilNummer: UInt
	var buchstabe: String?
}


struct Kapitel {
	var titel: String
	var start: Int?
	var end: Int?
}

struct Sprechrolle {
	var rolle: String
	var sprecher: String
	var pseudonym: String?
}

struct Links {
	var json: String?
	var ffmetadata: String?
	var cover: String?
	var cover2: [String]?
	var cover_itunes: String?
	var cover_kosmos: String?
	var dreifragezeichen: String?
	var appleMusic: String?
	var spotify: String?
	var bookbeat: String?
}

struct IDs {
	var dreimetadaten: UInt
}

struct Medium {
	var tracks: [Kapitel]
	var ripLog: String?
	var musicBrainzID: String?
}
