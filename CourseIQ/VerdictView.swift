import SwiftUI

struct VerdictBanner: View {
    let result: AnalysisResult
    let settings: Settings

    private var color: Color {
        switch result.verdict {
        case .rentable: return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .evaluer: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .perte: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(result.verdict.label)
                    .font(.system(size: 28, weight: .heavy))
                Text((result.net >= 0 ? "+" : "−") + fr(abs(result.net)) + " €")
                    .font(.system(size: 42, weight: .heavy))
                Text("net après tous les coûts")
                    .font(.subheadline)
                    .opacity(0.8)
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
                DeductLine(name: "Commission plateforme (\(fr(settings.tauxCom, 1)) %)",
                           value: "−" + fr(result.commission) + " €")
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
