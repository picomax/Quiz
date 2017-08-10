//
//  RecordViewController.swift
//  Quiz
//
//  Created by picomax on 09/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import SnapKit
import FirebaseStorage

class RecordViewController: UIImagePickerController {
    let uid: String
    
    required init(uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
        sourceType = .camera
        mediaTypes = [kUTTypeMovie as String]
        allowsEditing = false
        delegate = self
        videoMaximumDuration = 15.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dLog("no camera source type is available")
            return
        }
        
        guard let types = UIImagePickerController.availableMediaTypes(for: .camera) else {
            dLog("no available media types for camera")
            return
        }
        
        for t in types {
            dLog(t)
        }
        
    }
}

extension RecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        dLog(mediaType)
        guard mediaType == kUTTypeMovie as String, let url = info[UIImagePickerControllerMediaURL] as? URL else {
            return
        }
        
        // todo:
        let data = try! Data(contentsOf: url, options: [])
        let ref = Storage.storage().reference().child("uid.mov")
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = ref.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata.downloadURL
        }
        
        // hide this vc and reload collection view in videoViewController
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dLog()
    }
}

