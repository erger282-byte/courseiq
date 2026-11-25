import Foundation

enum Motor: String, CaseIterable, Identifiable {
    case essence, diesel, electrique
    var id: String { rawValue }
    var label: String {
        switch self {
        case .essence: return "Essence"
        case .diesel: return "Diesel"
        case .electrique: return "Électrique"
        }
    }
}

struct Settings {
    var motor: Motor = .essence
    var conso: Double = 7.0        // L/100 ou kWh/100
    var prixEnergie: Double = 1.80 // €/L ou €/kWh
    var charges: Double = 600      // €/mois
    var kmMois: Double = 4000
    var tauxCom: Double = 25       // %
    var cible: Double = 20         // €/h net visé
}

struct RideInput {
    var prix: Double = 0
    var dCourse: Double = 0
    var tCourse: Double = 0
    var dApproche: Double = 0
    var tApproche: Double = 0
    var netFrais: Bool = false
    var tCourseEstime: Bool = false
}

enum Verdict: String {
    case rentable, evaluer, perte
    var label: String {
        switch self {
        case .rentable: return "RENTABLE"
        case .evaluer: return "À ÉVALUER"
        case .perte: return "PERTE"
        }
    }
}

struct AnalysisResult {
    var km: Double
    var minutes: Int
    var commission: Double
    var carburant: Double
    var fixes: Double
    var approche: Double
    var net: Double
    var euroHeure: Double
    var euroKm: Double
    var verdict: Verdict
    var tApproche: Int
    var dApproche: Double
    var tCourse: Int
    var dCourse: Double
    var estime: Bool
}

enum Analyzer {
    static func analyse(_ s: Settings, _ i: RideInput) -> AnalysisResult? {
        guard i.prix > 0, i.dCourse > 0 || i.tCourse > 0 else { return nil }
        let km = i.dCourse + i.dApproche
        let minutes = i.tCourse + i.tApproche
        let heures = minutes / 60
        let commission = i.netFrais ? 0 : i.prix * s.tauxCom / 100
        let carburant = km * s.conso / 100 * s.prixEnergie
        let fixeKm = s.charges / max(1, s.kmMois)
        let fixes = km * fixeKm
        let approche = i.dApproche * (s.conso / 100 * s.prixEnergie + fixeKm)
        let net = i.prix - commission - carburant - fixes
        let euroHeure = heures > 0 ? net / heures : net
        let euroKm = km > 0 ? net / km : net
        let verdict: Verdict
        if net <= 0 || euroHeure < s.cible * 0.5 {
            verdict = .perte
        } else if euroHeure >= s.cible {
            verdict = .rentable
        } else {
            verdict = .evaluer
        }
        return AnalysisResult(km: km, minutes: Int(minutes.rounded()), commission: commission,
                              carburant: carburant, fixes: fixes, approche: approche,
                              net: net, euroHeure: euroHeure, euroKm: euroKm, verdict: verdict,
                              tApproche: Int(i.tApproche.rounded()), dApproche: i.dApproche,
                              tCourse: Int(i.tCourse.rounded()), dCourse: i.dCourse,
                              estime: i.tCourseEstime)
    }

    static func explication(_ s: Settings, _ r: AnalysisResult) -> String {
        let eh = String(format: "%.1f", locale: Locale(identifier: "fr_FR"), r.euroHeure)
        let cible = String(format: "%.0f", s.cible)
        let seuil = String(format: "%.1f", locale: Locale(identifier: "fr_FR"), s.cible * 0.5)
        switch r.verdict {
        case .rentable:
            return "À \(eh) €/h net, cette course dépasse ton objectif de \(cible) €/h. Prends-la."
        case .evaluer:
            return "À \(eh) €/h net, tu es sous ton objectif de \(cible) €/h mais au-dessus du seuil critique (\(seuil) €/h). Accepte si la zone te rapproche de la demande."
        case .perte:
            if r.net <= 0 {
                return "Cette course te fait perdre de l'argent une fois tous les coûts retirés. Refuse-la."
            }
            return "À \(eh) €/h net, cette course passe sous le seuil critique de \(seuil) €/h, la moitié de ton objectif. Refuse-la sauf stratégie particulière."
        }
    }

    /// Lit le texte OCR d'une capture d'offre Uber et pré-remplit ce qu'il trouve.
    static func parseOffer(text: String) -> RideInput {
        var input = RideInput()
        // Prix : "9 €", "9,50 €", "12.40€"
        if let m = firstMatch(#"(\d+[.,]\d{1,2})\s*€"#, in: text) ?? firstMatch(#"(\d+)\s*€"#, in: text) {
            input.prix = parseFr(m)
        }
        // Approche : "à 6 min (2.3 km)" ou "à <1 min (0 km)"
        if let m = firstMatch(#"à\s*<?\s*(\d+)\s*min\s*\((\d+[.,]\d+)\s*km"#, in: text, capture: 1) {
            input.tApproche = Double(m) ?? 0
        }
        if let m = firstMatch(#"à\s*\d+\s*min\s*\((\d+[.,]\d+)\s*km"#, in: text) {
            input.dApproche = parseFr(m)
        }
        // Autre format Uber : "8 min (à 2,2 km)"
        if input.tApproche == 0, let m = firstMatch(#"<?\s*(\d+)\s*min\s*\("#, in: text) {
            input.tApproche = Double(m) ?? 0
        }
        if input.dApproche == 0, let m = firstMatch(#"\(\s*à\s*(\d+[.,]\d+)\s*km"#, in: text) {
            input.dApproche = parseFr(m)
        }
        // Course : "Course de 9.7 km"
        if let m = firstMatch(#"[Cc]ourse\s+de\s+(\d+[.,]\d+)\s*km"#, in: text) {
            input.dCourse = parseFr(m)
        }
        // Durée éventuelle : "23min ↔ 12.0 km"
        if let m = firstMatch(#"(\d+)\s*min\s*[↔\-–>]+\s*\d"#, in: text) {
            input.tCourse = Double(m) ?? 0
        }
        // Sinon estimation ville (~24 km/h) comme Ride_IQ le fait avec le trafic
        if input.tCourse == 0 && input.dCourse > 0 {
            input.tCourse = (input.dCourse * 2.5).rounded()
            input.tCourseEstime = true
        }
        // Uber affiche souvent « Montant net de frais » : la commission est déjà déduite
        if text.range(of: "net de frais", options: .caseInsensitive) != nil {
            input.netFrais = true
        }
        return input
    }

    private static func parseFr(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private static func firstMatch(_ pattern: String, in text: String, capture: Int = 1) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = re.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > capture,
              let r = Range(match.range(at: capture), in: text) else { return nil }
        return String(text[r])
    }
}
