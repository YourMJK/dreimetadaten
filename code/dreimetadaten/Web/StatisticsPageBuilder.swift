//
//  StatisticsPageBuilder.swift
//  dreimetadaten
//
//  Created by YourMJK on 31.07.24.
//

import Foundation
import GRDB


class StatisticsPageBuilder: PageBuilder {
	let db: Database
	
	init(db: Database, templateFile: URL) throws {
		self.db = db
		try super.init(templateFile: templateFile)
	}
	
	override func build() throws {
		try super.build()
		try replaceContentPlaceholder()
	}
	
	private func replaceContentPlaceholder() throws {
		var content = ""
		
		let decimalFormatter = NumberFormatter()
		decimalFormatter.numberStyle = .decimal
		decimalFormatter.usesGroupingSeparator = false
		
		func addLine(_ line: String) {
			content.append(line)
			content.append("\n")
		}
		func format(_ value: DatabaseValue) -> String {
			switch value.storage {
				case .string(let string): return string
				case .double(let double): return decimalFormatter.string(from: NSNumber(value: double))!
				default: return "\(value)"
			}
		}
		func createSection(title: String, subtitle: String? = nil, description: String? = nil, inline: Bool = false, noHeaders: Bool = false, query: String) throws {
			addLine("<div class=\"statistic\">")
			
			// Query result
			let rows = try Row.fetchAll(db, sql: query)
			guard let columnNames = rows.first?.columnNames else {
				throw ResultError.queryHasNoResults(query: query)
			}
			
			// Inline result
			var title = title
			if inline {
				title.append(":")
				addLine("<div class=\"inline\">")
				addLine("<div>")
			}
			
			// Title
			addLine("<h3>\(title)</h3>")
			if let subtitle {
				addLine("<h4>\(subtitle)</h4>")
			}
			
			if inline {
				addLine("</div>")
				addLine("<div>")
			}
			
			// Table
			let table = TableBuilder()
			table.startTable(class: .datatable)
			// Headers
			if !noHeaders {
				table.startRow()
				columnNames.forEach {
					table.addCell(type: .th, content: $0)
				}
				table.endRow()
			}
			// Data
			for row in rows {
				table.startRow()
				row.databaseValues.enumerated().forEach {
					let first = $0.offset == 0 && row.count != 1
					table.addCell(class: first ? .nr : .data, content: format($0.element))
				}
				table.endRow()
			}
			table.endTable()
			
			content.append(table.content)
			
			if inline {
				addLine("</div>")
				addLine("</div>")
			}
			
			if let description {
				addLine("<p>\(description)</p>")
			}
			
			// Query
			addLine("<details>")
			addLine("\t<summary><b>SQL</b></summary>")
			addLine("\t<pre><code class=\"hljs language-sql\">\(query)</code></pre>")
			addLine("</details>")
			
			addLine("</div>\n")
		}
		func createSingleSection(title: String, subtitle: String? = nil, description: String? = nil, query: String) throws {
			try createSection(title: title, subtitle: subtitle, description: description, inline: true, noHeaders: true, query: query)
		}
		
		try createSection(
			title: "Top 10 Sprecher",
			subtitle: "nach gesprochenen Sprechrollen",
			query:
			"""
			SELECT name AS Sprecher, COUNT(*) AS Anzahl
			FROM spricht JOIN person USING (personID)
			GROUP BY Sprecher ORDER BY Anzahl DESC, Sprecher LIMIT 10
			"""
		)
		try createSection(
			title: "Top 10 Rollen",
			subtitle: "nach vorkommenden Hörspielen",
			query:
			"""
			SELECT name AS Rolle, COUNT(*) AS Anzahl
			FROM sprechrolle JOIN rolle USING (rolleID)
			GROUP BY Rolle ORDER BY Anzahl DESC, Rolle LIMIT 10
			"""
		)
		try createSection(
			title: "Top 10 Autoren",
			subtitle: "nach geschriebenen Buchvorlagen",
			description: "(max. ein Credit pro Autor pro Folge mit mehreren Teilen)",
			query:
			"""
			WITH buchautorCredits AS (
			  SELECT DISTINCT personID, COALESCE(hörspiel, hörspielID)
			  FROM hörspiel LEFT OUTER JOIN hörspielTeil ON teil = hörspielID
			  JOIN hörspielBuchautor USING (hörspielID)
			)
			SELECT name AS Autor, COUNT(*) AS Anzahl
			FROM buchautorCredits JOIN person USING (personID)
			GROUP BY personID ORDER BY Anzahl DESC, Autor LIMIT 10
			"""
		)
		try createSection(
			title: "Top 10 Hörspiele",
			subtitle: "nach Dauer",
			query:
			"""
			WITH hörspielDauer AS (
			  SELECT hörspielID, SUM(dauer) AS dauer
			  FROM hörspiel JOIN kapitel USING (hörspielID) JOIN track USING (trackID)
			  GROUP BY hörspielID
			),
			multiHörspielDauer AS (
			  SELECT hörspiel AS hörspielID, SUM(dauer) AS dauer
			  FROM hörspielTeil JOIN hörspielDauer ON teil = hörspielID
			  GROUP BY hörspiel
			  UNION SELECT * FROM hörspielDauer
			),
			rootHörspiel AS (
			  SELECT hörspielID FROM hörspiel
			  WHERE NOT EXISTS (
			    SELECT * FROM hörspielTeil WHERE hörspielID = teil
			  )
			)
			SELECT titel as Titel, dauer/1000 as Sekunden
			FROM rootHörspiel JOIN hörspiel USING (hörspielID) JOIN multiHörspielDauer USING (hörspielID)
			ORDER BY dauer DESC LIMIT 10
			"""
		)
		try createSingleSection(
			title: "Gesamtdauer aller Hörspiele",
			subtitle: "in Stunden",
			query:
			"""
			SELECT ROUND(SUM(dauer)/1000/3600.0, 2)
			FROM kapitel JOIN track USING (trackID)
			"""
		)
		try createSingleSection(
			title: "Anzahl an Hörspielen",
			subtitle: "ohne Teile",
			query:
			"""
			SELECT COUNT(*) FROM hörspiel h
			WHERE NOT EXISTS (
			  SELECT * FROM hörspielTeil ht WHERE ht.teil = h.hörspielID
			)
			"""
		)
		try createSingleSection(
			title: "Anzahl an Sprechern",
			query:
			"""
			SELECT COUNT(*) FROM (
			  SELECT DISTINCT personID FROM spricht
			)
			"""
		)
		try createSingleSection(
			title: "Anzahl an Rollen",
			query:
			"""
			SELECT COUNT(*) FROM rolle
			"""
		)
		try createSingleSection(
			title: "Anzahl an Buchautoren",
			query:
			"""
			SELECT COUNT(*) FROM (
			  SELECT DISTINCT personID FROM hörspielBuchautor
			)
			"""
		)
		try createSingleSection(
			title: "Anzahl an Hörspielskriptautoren",
			query:
			"""
			SELECT COUNT(*) FROM (
			  SELECT DISTINCT personID FROM hörspielSkriptautor
			)
			"""
		)
		
		try replace(placeholder: "%%content%%", with: content)
	}
	
}


extension StatisticsPageBuilder {
	enum ResultError: LocalizedError {
		case queryHasNoResults(query: String)
		
		var errorDescription: String? {
			switch self {
				case .queryHasNoResults(let query):
					return "Query has no results: \"\(query)\""
			}
		}
	}
}
