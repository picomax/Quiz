//
//  VideoViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer

class VideoViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VIDEO"
        view.backgroundColor = .lightGray
        
        let chooseVideoButton = UIButton(frame: .zero)
        chooseVideoButton.setTitle("RECORD", for: .normal)
        chooseVideoButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        chooseVideoButton.setTitleColor(.blue, for: .normal)
        chooseVideoButton.sizeToFit()
        chooseVideoButton.addTarget(self, action: #selector(didSelectChooseVideoButton), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: chooseVideoButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    func didSelectChooseVideoButton() {
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
        
        // needs NSPhotoLibraryUsageDescription key in info.plist
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.mediaTypes = [kUTTypeMovie as String]
        vc.allowsEditing = false
        vc.delegate = self
        vc.videoMaximumDuration = 15.0
        present(vc, animated: true, completion: nil)
    }
}

extension VideoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        dLog(mediaType)
        guard mediaType == kUTTypeMovie as String, let url = info[UIImagePickerControllerMediaURL] as? URL else {
            return
        }
        
        // todo:
        // 1. store firstAsset somewhere
        // 2. fetch second asset from firebase storage
        // 3. merge(firstAsset: secondAsset: callback:)
        let firstAsset = AVURLAsset(url: url)
        
        // not sure we need to hide picker here
        //        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dLog()
    }
}

//MARK:- Merge
extension VideoViewController {
    fileprivate func merge(firstAsset: AVURLAsset, secondAsset: AVURLAsset, callback: @escaping (_ merged: AVURLAsset?) -> Void) {
        let mixComposition = AVMutableComposition()
        let firstTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                                        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        try! firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                                        of: firstAsset.tracks(withMediaType: AVMediaTypeVideo)[0],
                                        at: kCMTimeZero)
        
        let secondTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                                         preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        try! secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                                         of: secondAsset.tracks(withMediaType: AVMediaTypeVideo)[0],
                                         at: firstAsset.duration)
        
        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
        
        // 2.2
        let firstInstruction = videoCompositionInstructionForTrack(track: firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, at: firstAsset.duration)
        let secondInstruction = videoCompositionInstructionForTrack(track: secondTrack, asset: secondAsset)
        
        // 2.3
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition
        
        exporter.exportAsynchronously {
            guard exporter.status == AVAssetExportSessionStatus.completed else { return }
            guard let url = exporter.outputURL else {
                callback(nil)
                return
            }
            callback(AVURLAsset(url: url))
        }
    }
    
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    fileprivate func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            
            let concat = assetTrack.preferredTransform.concatenating(scaleFactor)
            instruction.setTransform(concat, at: kCMTimeZero)
            
        } else {
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            let concatening = assetTrack.preferredTransform.concatenating(scaleFactor)
            var concat = concatening.concatenating(CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.width / 2))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: .pi)
                let windowBounds = UIScreen.main.bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(translationX: assetTrack.naturalSize.width, y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: kCMTimeZero)
        }
        return instruction
    }
}
