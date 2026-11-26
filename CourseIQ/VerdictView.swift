import SwiftUI

struct VerdictBanner: View {
    let result: AnalysisResult
    let settings: Settings
    let input: RideInput?

    init(result: AnalysisResult, settings: Settings, input: RideInput? = nil) {
        self.result = result
        self.settings = settings
        self.input = input
    }

    private var color: Color {
        switch result.verdict {
        case .rentable: return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .evaluer: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .perte: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Pastille du haut : durée de la course uniquement (comme dans les vidéos)
            HStack(spacing: 6) {
                Image(systemName: "car.fill")
                Text("CourseIQ · \(result.tCourse) min")
                if result.estime {
                    Text("· durée estimée")
                }
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.orange.opacity(0.15))
            .overlay(Capsule().stroke(Color.orange.opacity(0.6), lineWidth: 1))
            .clipShape(Capsule())

            // Panneau inspiré de Ride_IQ : prise en charge vs course
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("PRISE EN CHARGE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(result.tApproche) min · \(fr(result.dApproche, 1)) km")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 34)
                VStack(spacing: 4) {
                    Text("COURSE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("\(result.estime ? "~" : "")\(result.tCourse) min\(result.estime ? " (est.)" : "") · \(fr(result.dCourse, 1)) km")
                        .font(.system(size: 16, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.5), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Trajet : départ → arrivée, et note du client si lue
            if let input, !input.adresseDepart.isEmpty || !input.adresseArrivee.isEmpty {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .foregroundStyle(Color.orange)
                        Text(input.adresseDepart.isEmpty ? "Départ non lu" : input.adresseDepart)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(Color.orange)
                        Text(input.adresseArrivee.isEmpty ? "Arrivée non lue" : input.adresseArrivee)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if input.note > 0 {
                            Label(fr(input.note, 2), systemImage: "star.fill")
                                .foregroundStyle(Color.orange)
                        }
                    }
                }
                .font(.footnote)
            }

            VStack(spacing: 6) {
                Text(result.verdict.label)
                    .font(.system(size: 28, weight: .heavy))
                Text((result.net >= 0 ? "+" : "−") + fr(abs(result.net)) + " €")
                    .font(.system(size: 42, weight: .heavy))
                Text("net après tous les coûts, sur \(result.minutes) min au volant")
                    .font(.subheadline)
                    .opacity(0.8)
                if result.estime {
                    Text("Durée estimée (Apple Plans indisponible) : pas de verdict vert par prudence.")
                        .font(.caption)
                        .opacity(0.9)
                }
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color.opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.6), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 10) {
                StatBox(value: fr(result.euroHeure, 1) + " €", label: "€/h net")
                StatBox(value: fr(result.euroKm) + " €", label: "€/km net")
                StatBox(value: "\(result.minutes) min", label: "temps total")
            }

            VStack(alignment: .leading, spacing: 0) {
                if let input {
                    DeductLine(name: "Prix affiché", value: fr(input.prix) + " €")
                }
                if input?.netFrais == true {
                    DeductLine(name: "Commission déjà déduite (montant net de frais)", value: "0,00 €")
                } else {
                    DeductLine(name: "Commission plateforme (\(fr(settings.tauxCom, 1)) %)",
                               value: "−" + fr(result.commission) + " €")
                }
                DeductLine(name: settings.motor == .electrique ? "Électricité" : "Carburant",
                           value: "−" + fr(result.carburant) + " €")
                DeductLine(name: "Charges fixes (au km)", value: "−" + fr(result.fixes) + " €")
                DeductLine(name: "dont approche à vide", value: "−" + fr(result.approche) + " €")
                DeductLine(name: "Net dans ta poche",
                           value: (result.net >= 0 ? "+" : "−") + fr(abs(result.net)) + " €", bold: true)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(Analyzer.explication(settings, result))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(red: 0.05, green: 0.06, blue: 0.09))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

}

func fr(_ n: Double, _ dec: Int = 2) -> String {
    String(format: "%.\(dec)f", locale: Locale(identifier: "fr_FR"), n)
}

struct StatBox: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 17, weight: .bold))
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DeductLine: View {
    let name: String
    let value: String
    var bold: Bool = false
    var body: some View {
        HStack {
            Text(name).foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(value).fontWeight(bold ? .bold : .regular)
        }
        .font(bold ? .callout : .subheadline)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5) }
    }
}
