//
//  Location.swift
//  Quiz
//
//  Created by picomax on 06/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import Foundation
import FirebaseDatabase
import CoreLocation

class UserLocation {
    var coordinate: CLLocationCoordinate2D
    var username: String
    var uid: String
    var timestamp: Int
    
    required init(uid: String, username: String, coordinate: CLLocationCoordinate2D, timestamp: Int) {
        self.uid = uid
        self.username = username
        self.coordinate = coordinate
        self.timestamp = timestamp
    }
}

extension UserLocation: ModelProtocol {
    static var path: String { return "location" }
    var key: String { return uid }
    var rawValue: [AnyHashable: Any] {
        let timestamp = Int(NSDate().timeIntervalSince1970) - 30
        return ["username": username,
                "longitude": coordinate.longitude,
                "latitude": coordinate.latitude,
                "timestamp": timestamp]
    }
    
    func update() {
        Database.database().reference().child(UserLocation.path).child(key).updateChildValues(rawValue)
    }
    
    func remove() {
        Database.database().reference().child(UserLocation.path).child(key).removeValue()
    }
    
    typealias LocationItem = UserLocation
    static func fetch(callback: @escaping ([LocationItem]) -> Void) {
        Database.database().reference().child(path).observe(.value, with: { (snapshot) in
            guard let items = snapshot.value as? [String: AnyObject] else {
                callback([])
                return
            }
            
            var results: [UserLocation] = []
            for (key, value) in items {
                guard let username = value["username"] as? String,
                    let latitude = value["latitude"] as? Double,
                    let longitude = value["longitude"] as? Double,
                    let timestamp = value["timestamp"] as? Int else {
                        continue
                }
                let item = UserLocation(uid: key,
                                            username: username,
                                            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                            timestamp: timestamp)
                results.append(item)
                
            }
            callback(results)
        })
    }
}
