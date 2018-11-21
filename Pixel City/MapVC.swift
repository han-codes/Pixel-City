//
//  ViewController.swift
//  Pixel City
//
//  Created by Hannie Kim on 11/17/18.
//  Copyright © 2018 Hannie Kim. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000         // 1000 meters wide and high for our MKCoordinateRegion
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        checkAuthorizationStatus()
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    // center map on user's location
    func centerMapOnLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapVC: CLLocationManagerDelegate {
    func checkAuthorizationStatus() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()            
        } else {
            return
        }
    }
    
    // Delegate Methods
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnLocation()
    }
    
}
