//
//  Video.swift
//  Quiz
//
//  Created by picomax on 06/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import Foundation
import FirebaseDatabase

class UserVideo {
    var uid: String
    var name: String
    var mov: String
    var png: String
    
    // to present selected video status.
    var isSelected: Bool = false
    
    required init(uid: String, name: String, mov: String, png: String) {
        self.uid = uid
        self.name = name
        self.mov = mov
        self.png = png
    }
}

extension UserVideo: ModelProtocol {
    static var path: String { return "video" }
    var key: String { return uid }
    var rawValue: [AnyHashable: Any] {
        return ["name": name, "mov": mov, "png": png]
    }
    
    func update() {
        Database.database().reference().child(UserVideo.path).child(key).updateChildValues(rawValue)
    }
    
    func remove() {
        Database.database().reference().child(UserVideo.path).child(key).removeValue()
    }
    
    typealias VideoItem = UserVideo
    static func fetch(callback: @escaping ([VideoItem]) -> Void) {
        Database.database().reference().child(path).observe(.value, with: { (snapshot) in
            guard let items = snapshot.value as? [String: AnyObject] else {
                callback([])
                return
            }
            
            var results: [UserVideo] = []
            for (key, value) in items {
                guard let name = value["name"] as? String,
                    let mov = value["mov"] as? String,
                    let png = value["png"] as? String else {
                        continue
                }
                let item = UserVideo(uid: key, name: name, mov: mov, png: png)
                results.append(item)
                
            }
            callback(results)
        })
    }
}
