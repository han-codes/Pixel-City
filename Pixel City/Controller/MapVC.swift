//
//  ViewController.swift
//  Pixel City
//
//  Created by Hannie Kim on 11/17/18.
//  Copyright © 2018 Hannie Kim. All rights reserved.
//

import UIKit
import MapKit
// import CoreLocation
import Alamofire
import AlamofireImage

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
    
    var flowLayout = UICollectionViewFlowLayout()     // need to create collection view programmatically
    var collectionView: UICollectionView?
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        checkAuthorizationStatus()
        centerMapOnLocation()
        doubleTapped()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        registerForPreviewing(with: self, sourceView: collectionView!)  // register the VC for 3D Touch
        
        pullUpView.addSubview(collectionView!)
        
    }
    
    // animates the pullUpView up by increasing height constant constraint
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()          // updates view layout before drawing
        }
    }
    
    // swipe down to hide pullUpView
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        collectionView?.addGestureRecognizer(swipe)
    }
    
    @objc func animateViewDown() {
        cancelAllSession()
        pullUpViewHeightConstraint.constant = 0     // hides the pullUpView
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // add spinner when pullUpView animates up
    func addSpinner() {
        // Needs center, style, start animating, and color for spinner
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)       // centers the spinner vertically and horizontally in pullUpView
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner?.startAnimating()
        
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl?.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        progressLbl?.textAlignment = .center
        pullUpView.addSubview(progressLbl!)
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnLocation()
        }
    }
    
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {   // don't want to make changes to the user's location annotation
            return nil
        }
        
        // Creates an annotation w/ a pin image
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
        removeSpinner()
        removeProgressLbl()
        cancelAllSession()
        
        imageUrlArray = []
        imageArray = []
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)       // returns x, y values of the UITapGestureRecognizer touched point
        
        // converts the x,y axis of the touch point to coordinates (lat, lon)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")        
        
        mapView.addAnnotation(annotation)
        
        let coordinatRegion = MKCoordinateRegion.init(center: touchCoordinate, latitudinalMeters: regionRadius * 2, longitudinalMeters: regionRadius * 2)
        mapView.setRegion(coordinatRegion, animated: true)
        
        retrieveUrls(annotation: annotation) { (finished) in
            if finished{
                self.retrieveImages(handler: { (finished) in
                    if finished {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
    }
    
    func removePins() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrls(annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()) {
        
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { response in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]       // array of dictionaries
            for photo in photosDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            handler(true)
        }
    }
    
    // use the image urls to get UIImages
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        
        for url in imageUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return } // pulls out image value
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 Images Downloaded"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
                
            }
        }
    }
    
    // cancels Alamofire requests
    func cancelAllSession() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadTask, downloadTask) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadTask.forEach({ $0.cancel() })
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

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopVC else { return }
        popVC.initData(forImage: imageArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

// Using 3D Touch
extension MapVC: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil }
        
        // pass the image we want to PopVC before
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopVC else { return nil }
        popVC.initData(forImage: imageArray[indexPath.row])
        
        // set the size of the rectangle of the 3D touch preview
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
    
}

