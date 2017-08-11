//
//  VideoCollectionCell.swift
//  Quiz
//
//  Created by picomax on 09/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit

class VideoCollectionCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func set(video: UserVideo) {
        imageView.imageFromUrl(link: video.png)
        titleLabel.text = video.name
        
        if video.isSelected {
            contentView.layer.borderColor = UIColor.red.cgColor
            contentView.layer.borderWidth = 1.0
        } else {
            contentView.layer.borderColor = UIColor.clear.cgColor
            contentView.layer.borderWidth = 1.0
        }
    }
}

