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
import Alamofire
import AlamofireImage
import SwiftyJSON
import KeychainSwift

class DetailViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var masterOverlay: UIView!
    @IBOutlet weak var floorplanUrl: UITextView!
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var detailTitle: UINavigationItem!
    @IBOutlet weak var mapView: MKMapView!
    var location: CLLocation!
    var coordinateRegion: MKCoordinateRegion!
    var imageUrl: String!
    var downloadedImage: UIImage!
    var selectedAnnotation: MKAnnotationView!
    let keychain = KeychainSwift()
    
    func parseFor(key: String, list: [[String : [[Any]]]]) -> Int {
        var shittyCounter = 0
        for nicknameID in list {
            if nicknameID.first!.key == key {
                return shittyCounter
            }
            shittyCounter += 1
        }
        return -1
    }
    
    @IBAction func recenter(_ sender: Any) {
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @IBAction func deleteLeak(_ sender: Any) {
        let dataObject = self.keychain.getData("leakList")!
        var leakList = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as! [[String : [[Any]]]]
        var shittyIncrement = 0
        let leakListFound = parseFor(key: detailTitle.title!, list: leakList)
        for (annotation) in leakList[leakListFound][detailTitle.title!]! {
            if (annotation[0] as! CLLocationDegrees) == selectedAnnotation.annotation!.coordinate.latitude
            && (annotation[1] as! CLLocationDegrees) == selectedAnnotation.annotation!.coordinate.longitude
            && (annotation[2] as! String) == selectedAnnotation.annotation!.subtitle!! {
                leakList[leakListFound][detailTitle.title!]!.remove(at: shittyIncrement)
            }
            shittyIncrement += 1
        }
        let dataObject2 = NSKeyedArchiver.archivedData(withRootObject: leakList)
        keychain.set(dataObject2, forKey: "leakList")
        mapView.removeAnnotation(selectedAnnotation.annotation!)
    }
    
    @IBAction func tappedMap(_ sender: UILongPressGestureRecognizer) {
        if sender.state != UIGestureRecognizerState.began { return }
        let touchLocation = sender.location(in: mapView)
        let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        let centerCoordinate = CLLocationCoordinate2D(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
        annotation.coordinate = centerCoordinate
        annotation.title = "Leak!"
        let date = Date().description
        annotation.subtitle = date
        mapView.addAnnotation(annotation)

        let checkData = self.keychain.getData("leakList")
        if checkData == nil {
            let initArray : [[String : [[Any]]]] = [[detailTitle.title! : [[annotation.coordinate.latitude, annotation.coordinate.longitude, date]]]]
            let dataObject = NSKeyedArchiver.archivedData(withRootObject: initArray)
            keychain.set(dataObject, forKey: "leakList")
        }
        else {
            let dataObject = self.keychain.getData("leakList")!
            var leakList = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as! [[String : [[Any]]]]
            let leakListFound = parseFor(key: detailTitle.title!, list: leakList)
            if leakListFound == -1 {
                let initArray : [[String : [[Any]]]] = [[detailTitle.title! : [[annotation.coordinate.latitude, annotation.coordinate.longitude, date]]]]
                let dataObject = NSKeyedArchiver.archivedData(withRootObject: initArray)
                keychain.set(dataObject, forKey: "leakList")
                return
            }
            leakList[leakListFound][detailTitle.title!]!.append([annotation.coordinate.latitude, annotation.coordinate.longitude, date])
            let dataObject2 = NSKeyedArchiver.archivedData(withRootObject: leakList)
            keychain.set(dataObject2, forKey: "leakList")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        keychain.synchronizable = true
        
        deleteButton.isEnabled = false
        
        masterOverlay.layer.masksToBounds = false
        masterOverlay.layer.shadowRadius = 2.0
        masterOverlay.layer.shadowColor = UIColor.gray.cgColor
        masterOverlay.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        masterOverlay.layer.shadowOpacity = 0.75
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            let userAddress = detail[0].description
            let userNickname = detail[1].description
            detailTitle.title = userNickname
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(userAddress) { (placemarks, error) in
                guard
                    let placemarks = placemarks,
                    let tempLocation = placemarks.first?.location
                    else {
                        // handle no location found
                        return
                }
                // Use your location
                self.location = tempLocation
                let urlBase = "https://geczy.tech/leaks/get_locations.php?address="
                let url = urlBase + userAddress.replacingOccurrences(of: " ", with: "%20")
                Alamofire.request(url).response { response in // method defaults to `.get`
                    let json = JSON(data: response.data!)
                    DispatchQueue.main.async {
                        if !json.isEmpty {
                            let east = json.first!.1.floatValue
                            let south = json[json.index(json.startIndex, offsetBy: 1)].1.floatValue
                            let west = json[json.index(json.startIndex, offsetBy: 2)].1.floatValue
                            let north = json[json.index(json.startIndex, offsetBy: 3)].1.floatValue
                            self.imageUrl = json[json.index(json.startIndex, offsetBy: 4)].1.stringValue
                            self.floorplanUrl.text = self.imageUrl
                            self.handleData(east: east, south: south, west: west, north: north)
                        }
                        else {
                            self.handleData(east: 0.0, south: 0.0, west: 0.0, north: 0.0)
                        }
                    }
                }
            }
        }
    }
    
    func handleData(east: Float, south: Float, west: Float, north: Float) {

        let topLeft = CLLocationCoordinate2D(latitude: CLLocationDegrees(north), longitude: CLLocationDegrees(west))
        let topRight = CLLocationCoordinate2D(latitude: CLLocationDegrees(north), longitude: CLLocationDegrees(east))
        let bottomLeft = CLLocationCoordinate2D(latitude: CLLocationDegrees(south), longitude: CLLocationDegrees(west))
        let bottomRight = CLLocationCoordinate2D(latitude: CLLocationDegrees(south), longitude: CLLocationDegrees(east))
        let center = CLLocationCoordinate2D(latitude: CLLocationDegrees((north + south)/2), longitude: CLLocationDegrees((east + west)/2))
        
        let regionRadius: CLLocationDistance = 75
        self.coordinateRegion = MKCoordinateRegionMakeWithDistance(center, regionRadius, regionRadius)
        
        var coords = [center, topLeft, topRight, bottomLeft, bottomRight]
        if detailTitle.title! != "Tremco" {
            // this is ONLY to estimate rectangle size
            // remove this if you have exact coordinates for N E S W
            self.coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
            coords = [
                location.coordinate,
                CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude - 0.0005),
                CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude + 0.0005),
                CLLocationCoordinate2D(latitude: location.coordinate.latitude - 0.0005, longitude: location.coordinate.longitude),
                CLLocationCoordinate2D(latitude: location.coordinate.latitude + 0.0005, longitude: location.coordinate.longitude),
            ]
        }
        self.mapView.setRegion(self.coordinateRegion, animated: true)

        let dataObject = self.keychain.getData("leakList")
        if dataObject != nil {
            var leakList = NSKeyedUnarchiver.unarchiveObject(with: dataObject!) as! [[String : [[Any]]]]
            let leakListFound = parseFor(key: detailTitle.title!, list: leakList)
            if leakListFound != -1 && leakList[leakListFound].index(forKey: detailTitle.title!) != nil {
                for (annotation) in leakList[leakListFound][detailTitle.title!]! {
                    let genAnnotation = MKPointAnnotation()
                    let centerCoordinate = CLLocationCoordinate2D(latitude: annotation[0] as! CLLocationDegrees, longitude: annotation[1] as! CLLocationDegrees)
                    genAnnotation.coordinate = centerCoordinate
                    genAnnotation.title = "Leak!"
                    genAnnotation.subtitle = (annotation[2] as! String)
                    mapView.addAnnotation(genAnnotation)
                }
            }
        }
        
        let ourBuilding = Building(coords: coords)
        let overlay = BuildingOverlay(building: ourBuilding)
        if imageUrl != nil {
            Alamofire.request(imageUrl).responseImage { response in
                if let image = response.result.value {
                    DispatchQueue.main.async {
                        self.downloadedImage = image
                        
                        self.mapView.add(overlay, level: .aboveRoads)
                    }
                }
            }
        }
    }

    var detailItem: [String]? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is BuildingOverlay {
            let image = downloadedImage!
            return BuildingOverlayView(overlay: overlay, overlayImage: image)
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        deleteButton.isEnabled = true
        selectedAnnotation = view
        mapView.bringSubview(toFront: view)
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        deleteButton.isEnabled = false
    }

}

