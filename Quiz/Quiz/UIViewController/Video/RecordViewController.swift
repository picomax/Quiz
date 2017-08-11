//
//  RecordViewController.swift
//  Quiz
//
//  Created by picomax on 09/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import AVFoundation
import UIKit
import MobileCoreServices
import MediaPlayer
import SnapKit
import FirebaseAuth
import FirebaseStorage

class RecordViewController: UIViewController {
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var uid: String?
    var name: String?
    var didFinished: Bool = false
    var videoPath: String = ""
    var thumbPath: String = ""
    
    var imagePicker: UIImagePickerController?
    /*
    required init(uid: String, name: String) {
        self.uid = uid
        self.name = name
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
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        uid = Auth.auth().currentUser?.uid
        name = Auth.auth().currentUser?.email
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loading(active: true)
        
        if didFinished == true {
            //self.dismiss(animated: true, completion: nil)
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dLog("no camera source type is available")
            return
        }
        
        guard let types = UIImagePickerController.availableMediaTypes(for: .camera) else {
            dLog("no available media types for camera")
            print("Camera not available.")
            return
        }
        
        for t in types {
            dLog(t)
        }
        
        print("captureVideoPressed and camera available.")
        
        imagePicker = UIImagePickerController()
        
        guard let picker = imagePicker else { return }
        picker.delegate = self
        picker.sourceType = .camera;
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.allowsEditing = false
        //imagePicker.showsCameraControls = true
        
        picker.allowsEditing = false
        picker.videoMaximumDuration = 15.0
        
        self.present(picker, animated: true, completion: { [weak self] () -> Void in
            guard let strongSelf = self else { return }
            strongSelf.loading(active: false)
        })
    }
    
    fileprivate func update() {
        guard let userId = uid, let userName = name else {
            return
        }
        let video = UserVideo(uid: userId, name: userName, mov: videoPath, png: thumbPath)
        video.update()
    }
    
    func loading(active: Bool) {
        if active == true {
            loadingView.isHidden = false
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
            loadingView.isHidden = true
        }
    }
}

extension RecordViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController!, didFinishPickingMediaWithInfo info:NSDictionary!) {
        /*
        let tempImage = info[UIImagePickerControllerMediaURL] as! URL!
        guard let pathString = tempImage?.relativePath else {
            closeCamera()
            return;
        }
        self.dismiss(animated: true, completion: {})
        UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)
        */
        closePicker()
        
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        dLog(mediaType)
        guard mediaType == kUTTypeMovie as String, let url = info[UIImagePickerControllerMediaURL] as? URL else {
            closePicker()
            dismiss(animated: true, completion: {})
            return
        }
        
        let tempVideo = info[UIImagePickerControllerMediaURL] as! URL
        if let thumbnail = generateThumbnail(url: tempVideo) {
            // Use your thumbnail
            uploadImage(image: thumbnail)
        }
        
        guard let userId = uid else {
            //strongSelf.loading(active: false)
            closePicker()
            dismiss(animated: true, completion: {})
            return
        }
        
        let data = try! Data(contentsOf: url, options: [])
        let refVideo = Storage.storage().reference(withPath: "video").child(userId + ".mov")
        let uploadTask = refVideo.putData(data, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else { return }
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                strongSelf.closePicker()
                strongSelf.dismiss(animated: true, completion: {})
                
                let alert = UIAlertController(text: "Upload failed.", actionTitle: "OK")
                strongSelf.present(alert, animated: true, completion: {})
                return
            }
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata.downloadURL()
            strongSelf.videoPath = downloadURL?.absoluteString ?? ""
            
            strongSelf.update()
            
            strongSelf.closePicker()
            strongSelf.dismiss(animated: true, completion: {})
            
            let alert = UIAlertController(text: "Uploaded Completely.", actionTitle: "OK")
            strongSelf.present(alert, animated: true, completion: {})
        }
    }
    
    func uploadImage(image: UIImage) {
        guard let imageData: Data = UIImagePNGRepresentation(image) else {
            return
        }
        
        guard let userId = uid else {
            return
        }
        
        
        let refImage = Storage.storage().reference(withPath: "video").child(userId + ".png")
        let uploadTask = refImage.putData(imageData, metadata: nil) { [weak self] (metadata, error) in
            guard let strongSelf = self else { return }
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type, and download URL.
            let downloadURL = metadata.downloadURL()
            strongSelf.thumbPath = downloadURL?.absoluteString ?? ""
        }
    }
    
    func generateThumbnail(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = CGSize(width: 100, height: 100)
        let time = CMTimeMake(1, 30)
        
        if let img = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil) {
            return UIImage(cgImage: img)
        }
        return nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dLog()
        
        closePicker()
        dismiss(animated: true, completion: {})
    }
    
    func closePicker() {
        didFinished = true
        guard let picker = imagePicker else {
            return
        }
        picker.dismiss(animated: true, completion: {})
    }
}
