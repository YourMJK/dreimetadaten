struct Metadata {
	var serie: [Folge]?
	var spezial: [Höreinheit]?
	var kurzgeschichten: [Höreinheit]?
	var die_dr3i: [Folge]?
}


class Höreinheit {
	var teile: [Teil]?
	var titel: String?
	var autor: String?
	var hörspielskriptautor: String?
	var beschreibung: String?
	var veröffentlichungsdatum: String?
	var kapitel: [Kapitel]?
	var sprechrollen: [Sprechrolle]?
	var links: Links?
	var unvollständig: Bool?
}

class Folge: Höreinheit {
	let nummer: Int
}

class Teil: Höreinheit {
	let teilNummer: UInt
	var buchstabe: String?
}


class Kapitel {
	let titel: String
	var start: Int?
	var end: Int?
}

class Sprechrolle {
	var rolle: String
	var sprecher: String
	var pseudonym: String?
}

class Links {
	var json: String?
	var ffmetadata: String?
	var xld_log: String?
	var cover: String?
	var cover_itunes: String?
	var cover_kosmos: String?
}
