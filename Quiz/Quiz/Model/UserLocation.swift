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
    
    required init(uid: String, username: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.username = username
        self.coordinate = coordinate
    }
}

extension UserLocation: ModelProtocol {
    static var path: String { return "location" }
    var key: String { return uid }
    var rawValue: [AnyHashable: Any] {
        return ["username": username,
                "longitude": coordinate.longitude,
                "latitude": coordinate.latitude]
    }
    
    func update() {
        Database.database().reference().child(UserLocation.path).child(key).updateChildValues(rawValue)
    }
    
    typealias UserModel = UserLocation
    static func fetch(callback: @escaping ([UserModel]) -> Void) {
        Database.database().reference().child(path).observe(.value, with: { (snapshot) in
            guard let items = snapshot.value as? [String: AnyObject] else {
                callback([])
                return
            }
            
            var results: [UserLocation] = []
            for (key, value) in items {
                guard let username = value["username"] as? String,
                    let latitude = value["latitude"] as? Double,
                    let longitude = value["longitude"] as? Double else {
                        continue
                }
                let userLocation = UserLocation(uid: key,
                                            username: username,
                                            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                results.append(userLocation)
                
            }
            callback(results)
        })
    }
}
