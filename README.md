# dreimetadaten
#### Die drei ??? Metadaten – Datenbank, API und Website: [dreimetadaten.de](https://dreimetadaten.de)

Vollständige und korrekte Metadaten zu allen *Die drei ???* Folgen, inklusive Spezial-Folgen, *DiE DR3i*, Kurzgeschichten und *Die drei ??? Kids*.

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
* [**Hörspielzentrale**](https://apps.apple.com/us/app/hörspielzentrale/id6503214441): iOS-App zum Durchstöbern und Abspielen der Folgen (über Apple Music) von *Philipp*
* [**Rocky Beach**](https://apps.apple.com/de/app/rocky-beach-f%C3%BCr-die-drei/id6743175834): iOS-App zum Tracken gehörter Folgen, sowie Filtern nach Themen und Charakteren von *Jonas*
* [**dreifragezeichenportal.de**](https://dreifragezeichenportal.de): Website zum (thematischen) Durchsuchen der Folgen und Sprecher von *Alex*
* [**kassettenwechsler.de**](https://kassettenwechsler.de): Website mit Zufallsauswahl und Streaming-Links zu den Folgen (und anderen Hörspielreihen) von *Johannes*
* [**Die random ???**](https://die-random-fragezeichen.levrik.io): Zufallsgenerator von *levrik.io*
* [**ddf-random**](https://github.com/MeFisto94/ddf-random): Zufallsgenerator zum selber hosten von *MeFisto94*

## Struktur
### Relationales Modell (SQL-Datenbank, TSV)

<a href="model/relationalModel.svg?raw=1">
  <img src="model/relationalModel.svg">
</a>

<p>
<details>
<summary><b>SQL Schema</b></summary>

``` sql
CREATE TABLE "hörspiel"(
  "hörspielID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "titel" TEXT NOT NULL,
  "kurzbeschreibung" TEXT,
  "beschreibung" TEXT,
  "metabeschreibung" TEXT,
  "veröffentlichungsdatum" DATE,
  "unvollständig" BOOLEAN NOT NULL,
  "cover" INTEGER NOT NULL CHECK("cover" >= 0),
  "urlCoverApple" TEXT,
  "urlCoverKosmos" TEXT,
  "urlDreifragezeichen" TEXT,
  "idAppleMusic" TEXT,
  "idSpotify" TEXT,
  "idBookbeat" TEXT,
  "idAmazonMusic" TEXT,
  "idAmazon" TEXT,
  "idYouTubeMusic" TEXT,
  "idDeezer" TEXT
);
CREATE TABLE "hörspielTeil"(
  "teil" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspiel" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "buchstabe" TEXT CHECK(LENGTH("buchstabe") = 1),
  UNIQUE("hörspiel", "position"),
  UNIQUE("hörspiel", "buchstabe")
);
CREATE TABLE "serie"(
  "nummer" INTEGER PRIMARY KEY NOT NULL,
  "hörspielID" INTEGER NOT NULL UNIQUE REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "spezial"(
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL UNIQUE CHECK("position" > 0)
);
CREATE TABLE "kurzgeschichten"(
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "dieDr3i"(
  "nummer" INTEGER,
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "kids"(
  "nummer" INTEGER,
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "sonstige"(
  "hörspielID" INTEGER PRIMARY KEY NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "medium"(
  "mediumID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "ripLog" BOOLEAN NOT NULL,
  "musicBrainzID" TEXT,
  UNIQUE("hörspielID", "position")
);
CREATE TABLE "track"(
  "trackID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "mediumID" INTEGER NOT NULL REFERENCES "medium"("mediumID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "titel" TEXT NOT NULL,
  "dauer" INTEGER NOT NULL CHECK("dauer" > 0),
  UNIQUE("mediumID", "position")
);
CREATE TABLE "kapitel"(
  "trackID" INTEGER PRIMARY KEY NOT NULL REFERENCES "track"("trackID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  "abweichenderTitel" TEXT,
  UNIQUE("hörspielID", "position")
);
CREATE TABLE "person"(
  "personID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE "pseudonym"(
  "pseudonymID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE "rolle"(
  "rolleID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "name" TEXT NOT NULL UNIQUE
);
CREATE TABLE "sprechrolle"(
  "sprechrolleID" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "rolleID" INTEGER NOT NULL REFERENCES "rolle"("rolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  UNIQUE("hörspielID", "rolleID"),
  UNIQUE("hörspielID", "position")
);
CREATE TABLE "sprechrolleTeil"(
  "sprechrolleID" INTEGER NOT NULL REFERENCES "sprechrolle"("sprechrolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  PRIMARY KEY("sprechrolleID", "hörspielID"),
  UNIQUE("hörspielID", "position")
);
CREATE TABLE "spricht"(
  "sprechrolleID" INTEGER NOT NULL REFERENCES "sprechrolle"("sprechrolleID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  "pseudonymID" INTEGER REFERENCES "pseudonym"("pseudonymID") ON DELETE SET NULL ON UPDATE CASCADE,
  "position" INTEGER NOT NULL CHECK("position" > 0),
  PRIMARY KEY("sprechrolleID", "personID"),
  UNIQUE("sprechrolleID", "position")
);
CREATE TABLE "hörspielBuchautor"(
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY("hörspielID", "personID")
);
CREATE TABLE "hörspielSkriptautor"(
  "hörspielID" INTEGER NOT NULL REFERENCES "hörspiel"("hörspielID") ON DELETE CASCADE ON UPDATE CASCADE,
  "personID" INTEGER NOT NULL REFERENCES "person"("personID") ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY("hörspielID", "personID")
);
```

</details>
</p>

### Objekt-orientiertes Modell (JSON)

<a href="model/objectModel.svg?raw=1">
  <img src="model/objectModel.svg">
</a>

<p>
<details>
<summary><b>JSON Schema (in Swift)</b></summary>

``` swift
struct MetadataObjectModel {
  var serie: [Folge]?
  var spezial: [Hörspiel]?
  var kurzgeschichten: [Hörspiel]?
  var die_dr3i: [Hörspiel]?
  var kids: [Hörspiel]?
  var sonstige: [Hörspiel]?
  
  var dbInfo: DBInfo?
}


class Hörspiel {
  var titel: String?
  var autor: String?
  var hörspielskriptautor: String?
  var gesamtbeschreibung: String?
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
  var amazonMusic: String?
  var amazon: String?
  var youTubeMusic: String?
  var deezer: String?
}

struct IDs {
  var dreimetadaten: UInt
  var appleMusic: String?
  var spotify: String?
  var bookbeat: String?
  var amazonMusic: String?
  var amazon: String?
  var youTubeMusic: String?
  var deezer: String?
}

struct Medium {
  var tracks: [Kapitel]
  var ripLog: String?
  var musicBrainzID: String?
}


struct DBInfo {
  var version: String
  var lastModified: String
}
```

</details>
</p>

## Unterstützen über GitHub Sponsors
Wenn dir dieses Projekt gefällt oder der Datensatz hilfreich war, würde ich mich sehr über deine [Unterstützung durch eine Spende](https://github.com/sponsors/YourMJK) freuen!  
Das Geld hilft mir, die Kosten für das Hosting und die CDs zu tragen und motiviert mich, die Daten zu erweitern und weiterhin zeitnah aktuell zu halten :)

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
