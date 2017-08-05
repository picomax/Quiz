//
//  MapViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import GoogleMaps
import SnapKit
import FirebaseAuth
import FirebaseDatabase

class MapViewController: UIViewController {
    
    let mapView: GMSMapView = {
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        GMSServices.provideAPIKey("AIzaSyCMwpcqS0QBRhwQ6Y9Ia-EemyB_KdBx9cs")
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        return mapView
    }()
    
    var didFindMyLocation = false
    
    deinit {
        mapView.removeObserver(self, forKeyPath:"myLocation")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(mapView)
        title = "MAP"
        mapView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAllMarkers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapView.isMyLocationEnabled = true
    }
    
    fileprivate func addMarker(user: String, latitude: Double, longitude: Double, oneself: Bool) {
        dLog("coordinate : \(latitude), \(longitude)")
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        marker.map = mapView;
    }
    
    fileprivate func updateAllMarkers() {
        let databaseReference = Database.database().reference()
        //let userListHandler = databaseReference.child("users").observe(.value, with: { (snapshot) in
        _ = databaseReference.child("users").observe(.value, with: { [weak self] (snapshot) in
            guard let strongSelf = self else { return }
            //let itemDictionary = snapshot.value as? [String : AnyObject] ?? [:]
            guard let itemDictionary = snapshot.value as? [String: AnyObject] else { return }
            
            for item in itemDictionary {
                guard let itemValue = item.value as? [String: AnyObject],
                    let username = itemValue["username"] as? String,
                    let latitude = itemValue["latitude"] as? Double,
                    let longitude = itemValue["longitude"] as? Double else {
                        continue
                }
                
                strongSelf.addMarker(user: username, latitude: latitude, longitude: longitude, oneself: false)
            }
            
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "myLocation", let change = change, let myLocation: CLLocation = change[.newKey] as? CLLocation {
            didFindMyLocation = false
            if !didFindMyLocation {
                mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 11.0)
                mapView.settings.myLocationButton = true
                didFindMyLocation = true
                
                update(location: myLocation.coordinate)
            }
        }
    }
    
    fileprivate func update(location: CLLocationCoordinate2D) {
        let databaseReference = Database.database().reference()
        
        guard let currentUser = Auth.auth().currentUser else { return }
        guard let userName = currentUser.email else { return }
        let userReference = databaseReference.child("users").child(currentUser.uid)
        
        userReference.updateChildValues(["username":userName, "latitude":location.latitude, "longitude":location.longitude])
    }
}
