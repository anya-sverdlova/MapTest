//
//  MapModel.swift
//  MapTest
//
//  Created by Anna Sverdlova on 14.10.2020.
//

import Foundation
import MapKit

final class MapModel {

    private var pins = [PinModel]()
    private var radius: Double = 100

    var coordinates: [CLLocation] {
        return pins.map({CLLocation(latitude: $0.latitude, longitude: $0.longitude)})
    }

    init() {
        pins = getSavedAnnotations()
    }

    private func getSavedAnnotations() -> [PinModel] {
        var data = [PinModel]()
        let defaults = UserDefaults.standard
        if let jsonString = defaults.value(forKey: "SavedAnnotations") as? String, let jsonData = jsonString.data(using: .utf8) {
            let jsonDecoder = JSONDecoder()
            data = try! jsonDecoder.decode([PinModel].self, from: jsonData)
        }
        return data
    }

    func saveAnnotation(_ location: CLLocationCoordinate2D) {
        let pin = PinModel(location)
        pins.append(pin)
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode(pins)
        let json = String(data: jsonData, encoding: String.Encoding.utf8)
        let defaults = UserDefaults.standard
        defaults.setValue(json, forKey: "SavedAnnotations")
        defaults.synchronize()
    }

    func filteredCoordinates(_ location: CLLocation) -> [CLLocation] {
        return coordinates.filter({$0.distance(from: location) <= radius})
    }

    func setRadius(_ radius: Double) {
        self.radius = radius
    }
}

struct PinModel: Codable {
    var longitude: Double
    var latitude: Double

    init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }

    init(_ location: CLLocationCoordinate2D) {
        self.longitude = location.longitude
        self.latitude = location.latitude
    }
}
