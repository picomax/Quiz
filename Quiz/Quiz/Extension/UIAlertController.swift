//
//  UIAlertController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit

extension UIAlertController {
    convenience init(text: String, actionTitle: String) {
        self.init(title: nil,
                  message: text,
                  preferredStyle: .alert)
        let action = UIAlertAction(title: actionTitle,
                                   style: .default,
                                   handler: nil)
        addAction(action)
    }
}
