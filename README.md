# dreimetadaten
#### Die drei ??? Metadaten – Datenbank, API und Website: [dreimetadaten.de](https://dreimetadaten.de)

Vollständige und korrekte Metadaten zu allen *Die drei ???* Folgen, inklusive Spezial-Folgen, DiE DR3i und Kurzgeschichten.  
Darunter:
* Hochauflösende Coverbilder
* Kapiteldaten mit Zeitangaben
* Sprecher- und Rollenangaben
* Veröffentlichungsdaten
* Titel, Beschreibungstexte und Autoren
* Links zu Streaming-Plattformen und offiziellen Coverbildern

Verfügbar in mehreren Formaten:
* Relationale Datenbank in **SQL** (und als **TSV**)
* Daten als **JSON** (pro Folge oder komplett) – auch als Web-API
* Reduzierte Daten im **`ffmetadata`**-Format zum Anwenden auf Audiodateien mithilfe von `ffmpeg`

## Externe Projekte
Die Verwendung der Daten in eigenen Projekte ist freudig erwünscht!  
Bitte beachte den Hinweis zur Namensnennung unter [*Verwendung*](#verwendung).

Folgende Projekte greifen bereits auf diesen Datensatz zurück:
* [**Hörspielzentrale**](https://testflight.apple.com/join/BDnhdAVH): iOS-App zum Durchstöbern und Abspielen der Folgen (über Apple Music) von *Philipp*
* [**dreifragezeichenportal.de**](https://dreifragezeichenportal.de): Website zum (thematischen) Durchsuchen der Folgen und Sprecher von *Alex*
* [**Die random ???**](https://die-random-fragezeichen.levrik.io): Zufallsgenerator von *levrik.io*
* [**ddf-random**](https://github.com/MeFisto94/ddf-random): Zufallsgenerator zum selber hosten von *MeFisto94*

## Struktur
### Relationales Modell (SQL-Datenbank, TSV)

<img src="model/relationalModel.svg?raw=1" width="100%" height="100%">

<details>
<summary>SQL Schema</summary>

``` sql
CREATE TABLE IF NOT EXISTS "hörspiel"(
  "hörspielID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "titel" TEXT NOT NULL,
  "kurzbeschreibung" TEXT,
  "beschreibung" TEXT,
  "metabeschreibung" TEXT,
  "veröffentlichungsdatum" DATE,
  "unvollständig" BOOLEAN NOT NULL,
  "cover" BOOLEAN NOT NULL,
  "urlCoverApple" TEXT,
  "urlCoverKosmos" TEXT,
  "urlDreifragezeichen" TEXT,
  "urlAppleMusic" TEXT,
  "urlSpotify" TEXT,
  "urlBookbeat" TEXT
);
CREATE TABLE IF NOT EXISTS "hörspielTeil"(
  "teil" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspiel" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "buchstabe" TEXT CHECK(LENGTH("buchstabe") = 1),
  UNIQUE("hörspiel", "position"),
  UNIQUE("hörspiel", "buchstabe")
);
CREATE TABLE IF NOT EXISTS "serie"(
  "nummer" INTEGER PRIMARY KEY NOT NULL,
  "hörspielID" INTEGER NOT NULL UNIQUE REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE IF NOT EXISTS "spezial"(
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL UNIQUE CHECK("position" > 0)
);
CREATE TABLE IF NOT EXISTS "kurzgeschichten"(
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE IF NOT EXISTS "dieDr3i"(
  "nummer" INTEGER PRIMARY KEY NOT NULL,
  "hörspielID" INTEGER NOT NULL UNIQUE REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE IF NOT EXISTS "medium"(
  "mediumID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "ripLog" BOOLEAN NOT NULL,
  UNIQUE("hörspielID", "position")
);
CREATE TABLE IF NOT EXISTS "track"(
  "trackID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "mediumID" INTEGER NOT NULL REFERENCES "medium"("mediumID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "titel" TEXT NOT NULL,
  "dauer" INTEGER NOT NULL CHECK("dauer" > 0),
  UNIQUE("mediumID", "position")
);
CREATE TABLE IF NOT EXISTS "kapitel"(
  "trackID" INTEGER PRIMARY KEY NOT NULL REFERENCES "track"("trackID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "abweichenderTitel" TEXT,
  UNIQUE("hörspielID", "position")
);
CREATE TABLE IF NOT EXISTS "person"(
  "personID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS "pseudonym"(
  "pseudonymID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS "rolle"(
  "rolleID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS "sprechrolle"(
  "sprechrolleID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "rolleID" INTEGER NOT NULL REFERENCES "rolle"("rolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  UNIQUE("hörspielID", "rolleID"),
  UNIQUE("hörspielID", "position")
);
CREATE TABLE IF NOT EXISTS "sprechrolleTeil"(
  "sprechrolleID" INTEGER NOT NULL REFERENCES "sprechrolle"("sprechrolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  PRIMARY KEY("sprechrolleID", "hörspielID"),
  UNIQUE("hörspielID", "position")
);
CREATE TABLE IF NOT EXISTS "spricht"(
  "sprechrolleID" INTEGER NOT NULL REFERENCES "sprechrolle"("sprechrolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  "pseudonymID" INTEGER REFERENCES "pseudonym"("pseudonymID") ON DELETE SET NULL ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  PRIMARY KEY("sprechrolleID", "personID"),
  UNIQUE("sprechrolleID", "position")
);
CREATE TABLE IF NOT EXISTS "hörspielBuchautor"(
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY("hörspielID", "personID")
);
CREATE TABLE IF NOT EXISTS "hörspielSkriptautor"(
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY("hörspielID", "personID")
);
```

</details>

### Objekt-orientiertes Modell (JSON)

<img src="model/objectModel.svg?raw=1" width="100%" height="100%">

<details>
<summary>JSON Schema (in Swift)</summary>

``` swift
struct MetadataObjectModel {
  var serie: [Folge]?
  var spezial: [Hörspiel]?
  var kurzgeschichten: [Hörspiel]?
  var die_dr3i: [Folge]?
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
  var unvollständig: Bool?
  var medien: [Medium]?
  var teile: [Teil]?
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

struct Links {
  var json: String?
  var ffmetadata: String?
  var cover: String?
  var cover_itunes: String?
  var cover_kosmos: String?
  var dreifragezeichen: String?
  var appleMusic: String?
  var spotify: String?
  var bookbeat: String?
}

struct Medium {
  var tracks: [Kapitel]
  var ripLog: String?
}
```

</details>

## Beitragen
**Die "Single Source of Truth" für die Metadaten ist die SQL-Datenbank**.  
Alle anderen Formate (wie TSV, JSON, `ffmetadata`) werden davon abgeleitet.  
(Die Coverbilder und Rip-Logdateien sind nicht in der Datenbank gespeichert, sondern als eigene Dateien hinterlegt, derer Existenz vermerkt ist)

Zum reibungsfreien Ergänzen oder Korrigieren der Daten sollte also die Datenbank über das Dump geladen, bearbeitet und anschließend wieder gespeichert werden.  
Bei kleineren Korrekturhinweisen reicht aber natürlich auch ein Issue.

### Voraussetzungen
* `bash`-Shell
* [`sqlite3`](https://sqlite.org/cli.html) CLI tool
  * Ubuntu/Debian: `sudo apt install sqlite3`
  * macOS: (vorinstalliert)

### Ablauf
1. **Datenbank laden**:  
`$ tools/loadDB.sh`
2. **Datenbank editieren**:  
Beispiel:  
`$ sqlite3 metadata/db.sqlite < commands.txt`  
wobei Inhalt von `commands.txt` z.B.:
``` sql
UPDATE hörspiel SET urlSpotify = "https://…" WHERE titel = "und der Super-Papagei";
...
```
3. **Datenbank speichern**:  
`$ tools/saveDB.sh`
4. **PR erstellen**

## Verwendung
Inhalte der Website und die Datensätze (ausgenommen Coverbilder und Beschreibungstexte) stehen unter der [CC BY 4.0 Lizenz](https://creativecommons.org/licenses/by/4.0/legalcode.de) zur Verfügung.  
Bei Verwendung genügt als Namensnennung "dreimetadaten.de".

Sämtlicher Quellcode steht unter der [MIT License](https://opensource.org/license/MIT).
