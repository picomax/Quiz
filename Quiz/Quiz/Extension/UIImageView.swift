//
//  UIImageView.swift
//  Quiz
//
//  Created by picomax on 11/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit

extension UIImageView {
    /*
    func imageFromUrl(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    
    func imageFromUrl(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        imageFromUrl(url: url, contentMode: mode)
    }
    */
}
