//
//  ViewController.swift
//  MapTest
//
//  Created by Anna Sverdlova on 14.10.2020.
//

import UIKit
import MapKit

final class MainViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    private var data = MapModel()

    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.showInputDialog(title: "Set searching radius",
                        subtitle: "Please enter the radius in metres to show you your saved locations.",
                        actionTitle: "Set radius",
                        inputPlaceholder: "Radius",
                        inputKeyboardType: .numberPad, actionHandler:
                            { [weak self] (input:String?) in
                                if let this = self, let string = input, let radius = Double(string) {
                                    this.data.setRadius(radius)
                                }
                            })
    }

    private func setup() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()

        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
    }
    
    @IBAction func returnToCurrentLocation(_ sender: Any) {
        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenter(coor, animated: true)
        }
    }

    @IBAction func addNewAnnotation(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        data.saveAnnotation(coordinate)
    }

    private func addExistingAnnotations(coords: [CLLocation]){
        var coordinates = coords
        let annotations = mapView.annotations.filter({ !($0 is MKUserLocation) })
        coords.forEach ({ item in
            annotations.forEach({ anno in
                if anno.coordinate.latitude == item.coordinate.latitude && anno.coordinate.longitude == item.coordinate.longitude {
                    if let indexNeeded = coordinates.firstIndex(of: item) {
                        coordinates.remove(at: indexNeeded)
                    }
                    return
                }
                mapView.removeAnnotation(anno)
            })
        })
        for coord in coordinates {
            let CLLCoordType = CLLocationCoordinate2D(latitude: coord.coordinate.latitude,
                                                      longitude: coord.coordinate.longitude);
            let anno = MKPointAnnotation();
            anno.coordinate = CLLCoordType;
            mapView.addAnnotation(anno);
        }
    }

    func showInputDialog(title:String? = nil,
                             subtitle:String? = nil,
                             actionTitle:String? = "Add",
                             inputPlaceholder:String? = nil,
                             inputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                             cancelHandler: ((UIAlertAction) -> Swift.Void)? = nil,
                             actionHandler: ((_ text: String?) -> Void)? = nil) {

            let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
            alert.addTextField { (textField:UITextField) in
                textField.placeholder = inputPlaceholder
                textField.keyboardType = inputKeyboardType
            }
            alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { (action:UIAlertAction) in
                guard let textField =  alert.textFields?.first else {
                    actionHandler?(nil)
                    return
                }
                actionHandler?(textField.text)
            }))

            self.present(alert, animated: true, completion: nil)
        }
}

extension MainViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location = locations.last! as CLLocation
        let currentLocation = location.coordinate
        let coordinateRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(coordinateRegion, animated: true)
        addExistingAnnotations(coords: data.filteredCoordinates(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil;
        }else{
            let pinIdent = "Pin";
            var pinView: MKPinAnnotationView;
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: pinIdent) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation;
                pinView = dequeuedView;
            }else{
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinIdent);

            }
            return pinView;
        }
    }
    
}

