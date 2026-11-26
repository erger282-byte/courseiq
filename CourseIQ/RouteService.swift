import Foundation
import CoreLocation
import MapKit

/// Calcule la durée de la course avec Apple Plans.
/// MKDirections.calculateETA tient compte du trafic prévu (doc Apple),
/// contrairement à MKRoute.expectedTravelTime calculé dans des conditions idéales.
/// L'app n'affiche donc pas le mot « trafic » : elle affiche une durée.
enum RouteService {

    /// Résultat : durée de la course en minutes, et si elle est estimée (repli).
    static func dureeCourse(depart: String, arrivee: String, kmCourse: Double, minParKm: Double) async -> (minutes: Int, estime: Bool)? {
        if !depart.isEmpty && !arrivee.isEmpty,
           let minutes = await etaMinutes(depart: depart, arrivee: arrivee) {
            return (minutes, false)
        }
        // Repli : estimation réglable dans les réglages de l'app (valeur prudente par défaut).
        if kmCourse > 0 {
            return (max(1, Int((kmCourse * minParKm).rounded())), true)
        }
        return nil
    }

    private static func etaMinutes(depart: String, arrivee: String) async -> Int? {
        let geocoder = CLGeocoder()
        do {
            guard let pd = try await geocoder.geocodeAddressString(depart).first,
                  let pa = try await geocoder.geocodeAddressString(arrivee).first,
                  let cd = pd.location?.coordinate,
                  let ca = pa.location?.coordinate else { return nil }
            let requete = MKDirections.Request()
            requete.source = MKMapItem(placemark: MKPlacemark(coordinate: cd))
            requete.destination = MKMapItem(placemark: MKPlacemark(coordinate: ca))
            requete.transportType = .automobile
            requete.departureDate = Date()
            let eta = try await MKDirections(request: requete).calculateETA()
            return max(1, Int((eta.expectedTravelTime / 60).rounded()))
        } catch {
            return nil
        }
    }
}
