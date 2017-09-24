//
//  BuildingOverlay.swift
//  leaks
//
//  Created by Aron Gates on 9/23/17.
//  Copyright © 2017 Aron Gates. All rights reserved.
//

import UIKit
import MapKit

class BuildingOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    
    init(building: Building) {
        boundingMapRect = building.overlayBoundingMapRect
        coordinate = building.midCoordinate
    }
}
