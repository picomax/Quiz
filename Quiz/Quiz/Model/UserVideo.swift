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
    var url: String
    
    // to present selected video status.
    var isSelected: Bool = false
    
    required init(uid: String, url: String) {
        self.uid = uid
        self.url = url
    }
}

extension UserVideo: ModelProtocol {
    static var path: String { return "video" }
    var key: String { return uid }
    var rawValue: [AnyHashable: Any] {
        return ["url": url]
    }
    
    func update() {
        Database.database().reference().child(UserVideo.path).child(key).updateChildValues(rawValue)
    }
    
    typealias VideoModel = UserVideo
    static func fetch(callback: @escaping (_ result: [VideoModel]) -> Void) {
        Database.database().reference().child(path).observe(.value, with: { (snapshot) in
            guard let items = snapshot.value as? [String: AnyObject] else {
                callback([])
                return
            }
            
            var results: [UserVideo] = []
            for (key, value) in items {
                guard let url = value["url"] as? String else { continue }
                let item = UserVideo(uid: key, url: url)
                results.append(item)
            }
            callback(results)
        })
    }
}
