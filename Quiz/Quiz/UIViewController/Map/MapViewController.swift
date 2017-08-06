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
        let camera = GMSCameraPosition.camera(withLatitude: -37.33233141, longitude: -122.0312186, zoom: 1.0)
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
        
        mapView.addObserver(self, forKeyPath:"myLocation", options:NSKeyValueObservingOptions.new, context:nil)
    }
    
    /*
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAllMarkers()
    }
    */
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapView.isMyLocationEnabled = true
    }
    
    fileprivate func addMarker(location: UserLocation) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                 longitude: location.coordinate.longitude)
        marker.title = location.username
        marker.map = mapView;
    }
    
    fileprivate func updateMarkers(location: CLLocationCoordinate2D) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let stdLocation: CLLocation = CLLocation.init(latitude: location.latitude, longitude: location.longitude)
        
        UserLocation.fetch { [weak self] (locations) in
            guard let strongSelf = self else { return }
            for l in locations {
                if l.username == currentUser.email {
                    continue
                }
                
                let newLocation: CLLocation = CLLocation.init(latitude: l.coordinate.latitude, longitude: l.coordinate.longitude)
                let distanceKiloMeters = (newLocation.distance(from: stdLocation))/1000
                let distanceMiles = distanceKiloMeters * 0.621371
                if distanceMiles > 5 {
                    continue
                }
                
                strongSelf.addMarker(location: l)
            }
        }
    }
    /*
    fileprivate func updateMarkers(location: CLLocationCoordinate2D) {
        let databaseReference = Database.database().reference()
        
        guard let currentUser = Auth.auth().currentUser else { return }
        let stdLocation: CLLocation = CLLocation.init(latitude: location.latitude, longitude: location.longitude)
        
        //let timestamp = Int(NSDate().timeIntervalSince1970) - 30
        
        //let userListHandler = databaseReference.child("location").observe(.value, with: { (snapshot) in
        _ = databaseReference.child("location").observe(.value, with: { [weak self] (snapshot) in
        //_ = databaseReference.child("location").queryOrdered(byChild: "timestamp").queryStarting(atValue: timestamp).observe(.value, with: { [weak self] (snapshot) in
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
                
                if username == currentUser.email {
                    continue
                }
                
                let newLocation: CLLocation = CLLocation.init(latitude: latitude, longitude: longitude)
                let distanceKiloMeters = (newLocation.distance(from: stdLocation))/1000
                let distanceMiles = distanceKiloMeters * 0.621371
                if distanceMiles > 5 {
                    continue
                }
                
                strongSelf.addMarker(user: username, latitude: latitude, longitude: longitude)
            }
            
        })
    }
    */

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "myLocation", let change = change, let myLocation: CLLocation = change[.newKey] as? CLLocation {
            didFindMyLocation = false
            if !didFindMyLocation {
                mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 12.0)
                mapView.settings.myLocationButton = true
                didFindMyLocation = true
                
                update(location: myLocation.coordinate)
                updateMarkers(location: myLocation.coordinate)
            }
        }
    }
    
    //fileprivate func update(location: CLLocationCoordinate2D) {
    fileprivate func update(location: CLLocationCoordinate2D) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let location = UserLocation(uid: currentUser.uid,
                                  username: currentUser.email ?? "NA",
                                  coordinate: location)
        location.update()
    }
    
}
