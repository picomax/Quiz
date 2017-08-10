//
//  VideoViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import MediaPlayer
import FirebaseStorage
import FirebaseAuth

class VideoViewController: UIViewController {
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    
    fileprivate var dataSource: [UserVideo] = []
    fileprivate let storage = Storage.storage()
    
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
        
        UserVideo.fetch { [weak self] (videos) in
            guard let strongSelf = self else { return }
            strongSelf.dataSource = videos
            strongSelf.collectionView.reloadData()
        }
    }
    
    func didSelectChooseVideoButton() {
        //let selectedVideos = dataSource.filter({ return $0.isSelected })
        //guard selectedVideos.count == 2 else { return }
        
        let vc = RecordViewController(uid: Auth.auth().currentUser!.uid)
        present(vc, animated: true, completion: nil)
    }
    
    fileprivate func download(url: String, filename: String, callback: @escaping (_ url: URL?) -> Void) {
        let ref = storage.reference(forURL: url)
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let downloadPath = tempPath.appendingPathComponent(filename)
        ref.write(toFile: downloadPath) { (url, error) in
            guard let url = url else {
                callback(nil)
                return
            }
            callback(url)
        }
    }
    
    @IBAction func didSelectMergeButton() {
        let selectedItems = dataSource.filter({ return $0.isSelected })
        guard selectedItems.count == 2 else { return }
        download(url: selectedItems[0].url, filename: "video0.mov") { [weak self] (video1Url) in
            guard let strongSelf = self else { return }
            guard let video1Url = video1Url else {
                return
            }
            dLog(video1Url)
            
            strongSelf.download(url: selectedItems[1].url, filename: "video1.mov", callback: { (video2Url) in
                guard let video2Url = video2Url else {
                    return
                }
                dLog(video2Url)
                
                let first = AVURLAsset(url: video1Url)
                let second = AVURLAsset(url: video2Url)
                
                strongSelf.merge(firstAsset: first, secondAsset: second, callback: { (merged) in
                    dLog(merged)
                })
            })
        }
    }
}

//MARK:- UICollectionView
extension VideoViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionCell", for: indexPath) as! VideoCollectionCell
        let video = dataSource[indexPath.item]
        cell.set(video: video)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = dataSource[indexPath.item]
        if video.isSelected {
            video.isSelected = false
            
        } else {
            // do not allow to choose more than 2
            guard dataSource.filter({ return $0.isSelected }).count < 2 else {
                return
            }
            video.isSelected = true
            
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
}

//MARK:- Merge
extension VideoViewController {
    fileprivate func clearTempDirectory() {
        
    }
    
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
        
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let downloadPath = tempPath.appendingPathComponent("result.mov")
        try? FileManager.default.removeItem(at: downloadPath)
        exporter.outputURL = downloadPath
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

