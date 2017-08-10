//
//  VideoCollectionCell.swift
//  Quiz
//
//  Created by picomax on 09/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit

class VideoCollectionCell: UICollectionViewCell {
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    func set(video: UserVideo) {
        titleLabel.text = video.uid
        
        if video.isSelected {
            contentView.layer.borderColor = UIColor.red.cgColor
            contentView.layer.borderWidth = 1.0
        } else {
            contentView.layer.borderColor = UIColor.clear.cgColor
            contentView.layer.borderWidth = 1.0
        }
    }
}

