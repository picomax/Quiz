//
//  VideoCollectionCell.swift
//  Quiz
//
//  Created by picomax on 09/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import FirebaseAuth

class VideoCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var frameView: UIView!
    
    func set(video: UserVideo) {
        imageView.imageFromUrl(link: video.png)
        titleLabel.text = video.name
        
        if let currentUser = Auth.auth().currentUser,
            video.uid == currentUser.uid {
            titleLabel.text = "Mine!"
        }
        
        if video.isSelected {
            //contentView.layer.borderColor = UIColor.red.cgColor
            //contentView.layer.borderWidth = 1.0
            frameView.backgroundColor = UIColor.lightGray
        } else {
            //contentView.layer.borderColor = UIColor.clear.cgColor
            //contentView.layer.borderWidth = 1.0
            frameView.backgroundColor = UIColor.white
        }
    }
}

