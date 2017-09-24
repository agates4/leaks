//
//  DetailViewController.swift
//  leaks
//
//  Created by Aron Gates on 9/23/17.
//  Copyright © 2017 Aron Gates. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class DetailViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var detailTitle: UINavigationItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var coordinateRegion: MKCoordinateRegion!
    
    @IBAction func recenter(_ sender: Any) {
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            detailTitle.title = detail[1].description
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(detail[0].description) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let location = placemarks.first?.location
                    else {
                        // handle no location found
                        return
                }
                // Use your location
                let regionRadius: CLLocationDistance = 100
                self.coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
                self.mapView.setRegion(self.coordinateRegion, animated: true)
                
                let coord1 = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude + 0.0005)
                let coord2 = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude - 0.0005)
                let coord3 = CLLocationCoordinate2D(latitude: location.coordinate.latitude + 0.0005, longitude: location.coordinate.longitude)
                let coord4 = CLLocationCoordinate2D(latitude: location.coordinate.latitude - 0.0005, longitude: location.coordinate.longitude)
                let ourBuilding = Building(coords: [coord1, coord2, coord3, coord4])

                let overlay = BuildingOverlay(building: ourBuilding)
                self.mapView.add(overlay)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        configureView()
    }

    var detailItem: [String]? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is BuildingOverlay {
            let image = UIImage(named: "wendy-avatar.png")!
            return BuildingOverlayView(overlay: overlay, overlayImage: image)
        }
        return MKOverlayRenderer(overlay: overlay)
    }

}

