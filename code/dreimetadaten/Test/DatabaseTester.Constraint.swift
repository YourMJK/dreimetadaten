//
//  DatabaseTester.Constraint.swift
//  dreimetadaten
//
//  Created by YourMJK on 22.09.25.
//

extension DatabaseTester {
	enum Constraint: String, CaseIterable {
		/// hörspielTeil: No self reference (already enforced in DDL)
		case compositionA = "Composition Constraint A"
		/// hörspielTeil: Distinct children (already enforced in DDL)
		case compositionB = "Composition Constraint B"
		/// hörspielTeil: Max. depth == 1
		case compositionC = "Composition Constraint C"
		
		/// ∀ hörspielTeil: hörspiel.kapitel == 0
		case compositionD = "Composition Constraint D"
		/// ∀ hörspielTeil: hörspiel.autor == nil
		case compositionE = "Composition Constraint E"
		/// ∀ hörspielTeil: hörspiel.hörspielskriptautor == nil
		case compositionF = "Composition Constraint F"
		/// ∀ hörspielTeil: teil.medien == 0
		case compositionG = "Composition Constraint G"
		/// ∀ hörspielTeil: teil.sprechrollen == 0
		case compositionH = "Composition Constraint H"
		
		/// ∀ kapitel k: k.hörspiel == k.track.medium.hörspiel || k.hörspielTeil.hörspiel == k.track.medium.hörspiel
		case compositionI = "Composition Constraint I"
		/// ∀ sprechrolleTeil st: st.sprechrolle.hörspiel == st.hörspielTeil.hörspiel
		case compositionJ = "Composition Constraint J"
		
		/// version: Sequential version numbers and dates
		case version = "Version Constraint"
		
		
		var sqlQueryForNotExists: String {
			switch self {
				case .compositionA:
					"SELECT * FROM hörspielTeil WHERE teil = hörspiel"
				case .compositionB:
					"SELECT * FROM hörspielTeil GROUP BY teil HAVING COUNT(*) > 1"
				case .compositionC:
					"SELECT t2.teil, t2.hörspiel, t1.teil, t1.hörspiel FROM hörspielTeil t1 JOIN hörspielTeil t2 ON t1.teil = t2.hörspiel"
				
				case .compositionD:
					"SELECT DISTINCT hörspiel, trackID FROM hörspielTeil JOIN kapitel ON hörspiel = hörspielID"
				case .compositionE:
					"SELECT DISTINCT hörspiel, personID FROM hörspielTeil JOIN hörspielBuchautor ON hörspiel = hörspielID"
				case .compositionF:
					"SELECT DISTINCT hörspiel, personID FROM hörspielTeil JOIN hörspielSkriptautor ON hörspiel = hörspielID"
				case .compositionG:
					"SELECT teil, hörspiel, mediumID, hörspielID FROM hörspielTeil JOIN medium ON teil = hörspielID"
				case .compositionH:
					"SELECT teil, hörspiel, sprechrolleID, hörspielID FROM hörspielTeil JOIN sprechrolle ON teil = hörspielID"
				
				case .compositionI:
					"""
					SELECT trackID, k.hörspielID, mediumID, m.hörspielID, hörspiel
					FROM kapitel k
					JOIN track t USING (trackID)
					JOIN medium m USING (mediumID)
					LEFT JOIN hörspielTeil ht ON k.hörspielID = ht.teil
					WHERE k.hörspielID != m.hörspielID AND (ht.hörspiel IS NULL OR ht.hörspiel != m.hörspielID)
					"""
				case .compositionJ:
					"""
					SELECT sprechrolleID, st.hörspielID, s.hörspielID, teil, hörspiel
					FROM sprechrolleTeil st
					JOIN sprechrolle s USING (sprechrolleID)
					JOIN hörspielTeil ht ON st.hörspielID = ht.teil
					WHERE s.hörspielID != ht.hörspiel
					"""
					
				case .version:
					"""
					SELECT * FROM version v1 JOIN version v2 ON v2.date = (
					  SELECT MIN(date) FROM version WHERE date > v1.date
					) WHERE NOT (
					  (v1.major+1 = v2.major AND v2.minor = 0 AND v2.patch = 0) OR
					  (v1.major = v2.major AND v1.minor+1 = v2.minor AND v2.patch = 0) OR
					  (v1.major = v2.major AND v1.minor = v2.minor AND v1.patch+1 = v2.patch)
					);
					"""
			}
		}
	}
}
