import SwiftUI

struct ContentView: View {
    @AppStorage("motor") private var motorRaw: String = Motor.essence.rawValue
    @AppStorage("conso") private var conso: Double = 7.0
    @AppStorage("prixEnergie") private var prixEnergie: Double = 1.80
    @AppStorage("charges") private var charges: Double = 600
    @AppStorage("kmMois") private var kmMois: Double = 4000
    @AppStorage("tauxCom") private var tauxCom: Double = 25
    @AppStorage("cible") private var cible: Double = 20
    @AppStorage("minParKm") private var minParKm: Double = 3.0

    @State private var prix: String = ""
    @State private var dCourse: String = ""
    @State private var tCourse: String = ""
    @State private var dApproche: String = ""
    @State private var tApproche: String = ""
    @State private var netFrais: Bool = false
    @State private var showSettings: Bool = false
    @State private var showHelp: Bool = false

    private var settings: Settings {
        Settings(motor: Motor(rawValue: motorRaw) ?? .essence, conso: conso, prixEnergie: prixEnergie,
                 charges: charges, kmMois: kmMois, tauxCom: tauxCom, cible: cible, minParKm: minParKm)
    }

    private var input: RideInput {
        var i = RideInput(prix: num(prix), dCourse: num(dCourse), tCourse: num(tCourse),
                          dApproche: num(dApproche), tApproche: num(tApproche), netFrais: netFrais)
        // Saisie manuelle sans adresses : si la durée n'est pas donnée,
        // repli au min/km réglable (valeur prudente), marqué « durée estimée ».
        if i.tCourse == 0 && i.dCourse > 0 {
            i.tCourse = (i.dCourse * minParKm).rounded()
            i.tCourseEstime = true
        }
        return i
    }

    private var result: AnalysisResult? { Analyzer.analyse(settings, input) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // La carte en premier
                    if let r = result {
                        VerdictBanner(result: r, settings: settings, input: input)
                    } else {
                        Text("Entre le prix, la distance et la durée de la course pour voir le verdict.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    DisclosureGroup {
                        VStack(spacing: 12) {
                            Field(label: "Prix affiché (€)", text: $prix)
                            HStack(spacing: 10) {
                                Field(label: "Course (km)", text: $dCourse)
                                Field(label: "Course (min)", text: $tCourse)
                            }
                            HStack(spacing: 10) {
                                Field(label: "Approche (km)", text: $dApproche)
                                Field(label: "Approche (min)", text: $tApproche)
                            }
                            Toggle(isOn: $netFrais) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Prix déjà net de commission")
                                    Text("Comme « montant net de frais » sur Uber")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .tint(.green)
                            Text("Sans adresses, la durée est estimée au min/km des réglages, jamais en verdict vert.")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)
                    } label: {
                        Text("Saisie manuelle (secours)")
                            .font(.callout).fontWeight(.semibold)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button { showSettings.toggle() } label: {
                        HStack {
                            Text("Réglages du véhicule et seuils").fontWeight(.semibold)
                            Spacer()
                            Image(systemName: showSettings ? "chevron.up" : "chevron.down")
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .foregroundStyle(.primary)

                    if showSettings {
                        GroupBox {
                            VStack(spacing: 12) {
                                Picker("Motorisation", selection: $motorRaw) {
                                    ForEach(Motor.allCases) { Text($0.label).tag($0.rawValue) }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: motorRaw) { newValue in
                                    let m = Motor(rawValue: newValue) ?? .essence
                                    if m == .electrique {
                                        if conso > 15 || conso == 7 || conso == 6 { conso = 18 }
                                        if prixEnergie > 1 { prixEnergie = 0.25 }
                                    } else {
                                        if conso >= 18 { conso = (m == .diesel ? 6 : 7) }
                                        if prixEnergie < 1 { prixEnergie = (m == .diesel ? 1.75 : 1.80) }
                                    }
                                }
                                Stepper(value: $conso, in: 0...40, step: 0.5) {
                                    LabeledContent(settings.motor == .electrique ? "Conso (kWh/100)" : "Conso (L/100)",
                                                   value: fr(conso, 1))
                                }
                                Stepper(value: $prixEnergie, in: 0...5, step: 0.01) {
                                    LabeledContent(settings.motor == .electrique ? "Prix (€/kWh)" : "Prix (€/L)",
                                                   value: fr(prixEnergie))
                                }
                                Stepper(value: $charges, in: 0...5000, step: 25) {
                                    LabeledContent("Charges fixes (€/mois)", value: fr(charges, 0))
                                }
                                Stepper(value: $kmMois, in: 100...20000, step: 100) {
                                    LabeledContent("Km parcourus / mois", value: fr(kmMois, 0))
                                }
                                Stepper(value: $tauxCom, in: 0...60, step: 0.5) {
                                    LabeledContent("Commission plateforme (%)", value: fr(tauxCom, 1))
                                }
                                Stepper(value: $cible, in: 1...60, step: 1) {
                                    LabeledContent("Objectif (€/h net)", value: fr(cible, 0))
                                }
                                Stepper(value: $minParKm, in: 1.5...6, step: 0.5) {
                                    LabeledContent("Min/km de secours", value: fr(minParKm, 1))
                                }
                                Text("Le min/km de secours sert uniquement quand Apple Plans ne peut pas calculer la durée : le verdict n'est alors jamais vert.")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("Assurance, entretien, usure, abonnements : mets-les dans les charges fixes, elles sont ramenées au kilomètre.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        } label: {
                            Text("RÉGLAGES").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Button { showHelp = true } label: {
                        Label("Comment analyser une offre Uber ?", systemImage: "questionmark.circle")
                            .font(.footnote)
                    }
                    .sheet(isPresented: $showHelp) { HelpView() }
                }
                .padding(16)
            }
            .background(Color(red: 0.04, green: 0.05, blue: 0.08))
            .navigationTitle("CourseIQ")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }

    private func num(_ s: String) -> Double {
        Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
    }
}

struct Field: View {
    let label: String
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .font(.system(size: 19, weight: .semibold))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Quand une offre Uber apparaît avec Accepter / Refuser :")
                    Label("Fais une capture d'écran de l'offre.", systemImage: "camera.viewfinder")
                    Label("Ouvre la capture, touche Partager, puis choisis CourseIQ.", systemImage: "square.and.arrow.up")
                    Label("Le verdict s'affiche tout de suite, avec le temps de trajet en premier.", systemImage: "bolt.fill")
                    Text("L'image reste sur ton iPhone, seules les adresses sont envoyées à Apple Plans pour calculer la durée du trajet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("Comment ça marche")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { dismiss() } } }
        }
    }
}

#Preview {
    ContentView()
}
