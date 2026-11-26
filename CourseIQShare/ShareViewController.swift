import UIKit
import SwiftUI
import Vision
import UniformTypeIdentifiers

/// Extension de partage : depuis la capture d'écran d'une offre Uber,
/// Partager > CourseIQ affiche le verdict directement dans la feuille de partage.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1)
        loadSharedImage()
    }

    private func loadSharedImage() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first else {
            show(.failure("Aucune image reçue. Partage une capture d'écran de l'offre."))
            return
        }
        let type = UTType.image.identifier
        guard provider.hasItemConformingToTypeIdentifier(type) else {
            show(.failure("Ce partage n'est pas une image."))
            return
        }
        provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] data, _ in
            var image: UIImage?
            if let img = data as? UIImage { image = img }
            else if let url = data as? URL { image = UIImage(contentsOfFile: url.path) }
            else if let d = data as? Data { image = UIImage(data: d) }
            guard let self, let image, let cg = image.cgImage else {
                DispatchQueue.main.async { self?.show(.failure("Image illisible.")) }
                return
            }
            self.recognize(cgImage: cg)
        }
    }

    private func recognize(cgImage: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] request, _ in
            let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
            let text = lines.joined(separator: "\n")
            DispatchQueue.main.async {
                guard let self else { return }
                let input = Analyzer.parseOffer(text: text)
                if input.prix > 0 || input.dCourse > 0 {
                    self.show(.loading)
                    self.route(input)
                } else {
                    self.show(.failure("Je n'ai rien réussi à lire sur cette capture. Essaie une capture nette de l'offre."))
                }
            }
        }
        request.recognitionLanguages = ["fr-FR", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    /// Calcule la durée de la course avec Apple Plans (calculateETA, trafic prévu pris en compte).
    /// Si le calcul échoue ou qu'une adresse manque : repli min/km réglable, marqué « durée estimée ».
    private func route(_ input: RideInput) {
        let settings = Settings()
        Task { [weak self] in
            var final = input
            if let duree = await RouteService.dureeCourse(depart: input.adresseDepart,
                                                          arrivee: input.adresseArrivee,
                                                          kmCourse: input.dCourse,
                                                          minParKm: settings.minParKm) {
                final.tCourse = Double(duree.minutes)
                final.tCourseEstime = duree.estime
            }
            await MainActor.run { self?.show(.parsed(final)) }
        }
    }

    private enum Outcome {
        case loading
        case parsed(RideInput)
        case failure(String)
    }

    private func show(_ outcome: Outcome) {
        let root: AnyView
        switch outcome {
        case .loading:
            root = AnyView(ShareLoadingView())
        case .parsed(let input):
            root = AnyView(ShareVerdictView(input: input, onClose: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }))
        case .failure(let message):
            root = AnyView(ShareErrorView(message: message, onClose: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }))
        }
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        view.subviews.forEach { $0.removeFromSuperview() }
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }
}

private struct ShareLoadingView: View {
    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().tint(.white).scaleEffect(1.4)
            Text("Analyse en cours…").font(.headline)
            Text("Lecture de la capture, puis calcul de la durée du trajet avec Apple Plans.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
    }
}

private struct ShareVerdictView: View {
    let input: RideInput
    let onClose: () -> Void

    // Réglages par défaut : l'extension ne lit pas ceux de l'app (pas d'App Group avec un compte gratuit).
    private let settings = Settings()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CourseIQ").font(.headline)
                Spacer()
                Button("Fermer", action: onClose)
            }
            if let r = Analyzer.analyse(settings, input) {
                VerdictBanner(result: r, settings: settings, input: input)
                Text("L'image reste sur ton iPhone, seules les adresses sont envoyées à Apple Plans pour calculer la durée du trajet.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Réglages par défaut (essence, 7 L/100, 25 % de commission, objectif 20 €/h, secours \(fr(settings.minParKm, 1)) min/km). Ajuste-les dans l'app CourseIQ.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Prix lu : \(fr(input.prix)) € · course \(fr(input.dCourse, 1)) km. Ouvre l'app CourseIQ pour compléter.")
                    .font(.footnote)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .foregroundStyle(.white)
    }
}

private struct ShareErrorView: View {
    let message: String
    let onClose: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.largeTitle)
            Text(message).multilineTextAlignment(.center)
            Button("Fermer", action: onClose).buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
    }
}
