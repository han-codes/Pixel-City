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
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 1000         // 1000 meters wide and high for our MKCoordinateRegion
    
    var screenSize = UIScreen.main.bounds   // gets the size of the screen
    
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        checkAuthorizationStatus()
        centerMapOnLocation()
        doubleTapped()
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()          // updates view layout before drawing
        }
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    @objc func animateViewDown() {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner() {
        // Needs center, style, start animating, and color
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)       // centers the spinner vertically and horizontally in pullUpView
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner?.startAnimating()
        
        pullUpView.addSubview(spinner!)
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.tintColor = #colorLiteral(red: 0.9759346843, green: 0.5839473009, blue: 0.02618087828, alpha: 1)
        pinAnnotation.animatesDrop = true
        
        return pinAnnotation
    }
    
   
    // center map on user's location
    func centerMapOnLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // gets called by doubleTapped()
    @objc func dropPin(sender: UITapGestureRecognizer) {
        removePins()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        
        let touchPoint = sender.location(in: mapView)       // returns x, y values of the touched point
        
        // converts the x,y axis of the touch point to coordinates (lat, lon)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinatRegion = MKCoordinateRegion.init(center: touchCoordinate, latitudinalMeters: regionRadius * 2, longitudinalMeters: regionRadius * 2)
        mapView.setRegion(coordinatRegion, animated: true)
    }
    
    func removePins() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
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
        mapView.showsUserLocation = true
    }
}

extension MapVC: UIGestureRecognizerDelegate {
    func doubleTapped() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
}
