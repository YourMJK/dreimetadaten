struct MetadataObjectModel {
	var serie: [Folge]?
	var spezial: [Hörspiel]?
	var kurzgeschichten: [Hörspiel]?
	var die_dr3i: [Folge]?
}


class Hörspiel {
	var teile: [Teil]?
	var titel: String?
	var autor: String?
	var hörspielskriptautor: String?
	var kurzbeschreibung: String?
	var beschreibung: String?
	var metabeschreibung: String?
	var veröffentlichungsdatum: String?
	var kapitel: [Kapitel]?
	var sprechrollen: [Sprechrolle]?
	var medien: [Medium]?
	var links: Links?
	var unvollständig: Bool?
}

class Folge: Hörspiel {
	var nummer: Int
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

struct Medium {
	var tracks: [Kapitel]
	var xld_log: String?
}

struct Links {
	var json: String?
	var ffmetadata: String?
	var cover: String?
	var cover_itunes: String?
	var cover_kosmos: String?
}
