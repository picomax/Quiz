//
//  VideoViewController.swift
//  Quiz
//
//  Created by picomax on 04/08/2017.
//  Copyright © 2017 picomax. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import FirebaseStorage
import FirebaseAuth

class VideoViewController: UIViewController {
    
    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var imageView1: UIImageView!
    @IBOutlet fileprivate weak var imageView2: UIImageView!
    @IBOutlet fileprivate weak var imageView3: UIImageView!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    var uid: String?
    var name: String?
    var mergedVideo: MergedVideo?
    var videoPath: String = ""
    var thumbPath: String = ""
    
    fileprivate var dataSource: [UserVideo] = []
    fileprivate let storage = Storage.storage()
    fileprivate var index1: Int = -1
    fileprivate var index2: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VIDEO"
        //view.backgroundColor = .lightGray
        view.backgroundColor = .white
        
        let chooseVideoButton = UIButton(frame: .zero)
        chooseVideoButton.setTitle("RECORD", for: .normal)
        chooseVideoButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        chooseVideoButton.setTitleColor(.blue, for: .normal)
        chooseVideoButton.sizeToFit()
        chooseVideoButton.addTarget(self, action: #selector(didSelectChooseVideoButton), for: .touchUpInside)
        let rightBarButtonItem = UIBarButtonItem(customView: chooseVideoButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        uid = Auth.auth().currentUser?.uid
        name = Auth.auth().currentUser?.email
        
        loading(active: true)
        UserVideo.fetch { [weak self] (videos) in
            guard let strongSelf = self else { return }
            strongSelf.dataSource = videos
            strongSelf.collectionView.reloadData()
            strongSelf.loading(active: false)
        }
        
        loadMergedVideo()
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
    
    func loadMergedVideo() {
        MergedVideo.fetch { [weak self] (videos) in
            guard let strongSelf = self else { return }
            guard let userId = strongSelf.uid else { return }
            for merged: MergedVideo in videos {
                if merged.uid == userId {
                    strongSelf.mergedVideo = merged
                    break
                }
            }
            
            guard let path = strongSelf.mergedVideo?.png else { return }
            //strongSelf.imageView3.imageFromUrl(link: path)
            strongSelf.imageView3.kf.setImage(with: URL(string: path))
        }
    }
    
    func didSelectChooseVideoButton() {
        //let selectedVideos = dataSource.filter({ return $0.isSelected })
        //guard selectedVideos.count == 2 else { return }
        
        clearSlot()
        
        self.loading(active: true)
        
        //let vc = RecordViewController(uid: Auth.auth().currentUser!.uid)
        //let vc = RecordViewController(uid: userId, name: userName)
        let storyboard = UIStoryboard(name: "Video", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "RecordViewController")
        present(vc, animated: true, completion: { [weak self] ()->Void in
            guard let strongSelf = self else { return }
            strongSelf.loading(active: false)
            strongSelf.loadMergedVideo()
        })
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
    
    func playVideo(url: URL) {
        let player: AVPlayer = AVPlayer(url: url)
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    @IBAction func didSelectImageView1(_ sender: Any) {
        if index1 > -1 {
            let video: UserVideo = dataSource[index1]
            guard let itemUrl = URL(string: video.mov) else { return }
            playVideo(url: itemUrl)
        }
    }
    
    @IBAction func didSelectImageView2(_ sender: Any) {
        if index2 > -1 {
            let video: UserVideo = dataSource[index2]
            guard let itemUrl = URL(string: video.mov) else { return }
            playVideo(url: itemUrl)
        }
    }
    
    @IBAction func didSelectImageView3(_ sender: Any) {
        guard let itemUrl = URL(string: (mergedVideo?.mov)!) else { return }
        playVideo(url: itemUrl)
    }
    
    @IBAction func didSelectMergeButton() {
        let selectedItems = dataSource.filter({ return $0.isSelected })
        guard selectedItems.count == 2 else {
            let alert = UIAlertController(text: "You need to select two videos to merge.", actionTitle: "OK")
            present(alert, animated: true, completion: {})
            return
        }
        
        let video1: UserVideo = dataSource[index1]
        let video2: UserVideo = dataSource[index2]
        
        let url1 = video1.mov
        let url2 = video2.mov
        
        loading(active: true)
        
        download(url: url1, filename: "video1.mov") { [weak self] (video1Url) in
            guard let strongSelf = self else { return }
            guard let video1Url = video1Url else {
                return
            }
            dLog(video1Url)
            
            strongSelf.download(url: url2, filename: "video2.mov", callback: { (video2Url) in
                guard let video2Url = video2Url else {
                    strongSelf.loading(active: false)
                    return
                }
                dLog(video2Url)
                
                let first = AVURLAsset(url: video1Url)
                let second = AVURLAsset(url: video2Url)
                
                strongSelf.merge(firstAsset: first, secondAsset: second, callback: { (merged) in
                    dLog(merged)
                    guard let url = merged?.url else {
                        strongSelf.loading(active: false)
                        return
                    }
                    
                    /*
                    guard let pathString = url.path else {
                        return
                    }
                    UISaveVideoAtPathToSavedPhotosAlbum(pathString, self, nil, nil)
                    */
                    
                    if let thumbnail = strongSelf.generateThumbnail(url: url) {
                        // Use your thumbnail
                        strongSelf.uploadImage(image: thumbnail)
                    }
                    
                    guard let userId = strongSelf.uid else {
                        strongSelf.loading(active: false)
                        return
                    }
                    
                    let data = try! Data(contentsOf: url, options: [])
                    let refVideo = Storage.storage().reference(withPath: "merge").child(userId + ".mov")
                    let uploadTask = refVideo.putData(data, metadata: nil) { [weak self] (metadata, error) in
                        guard let strongSelf = self else { return }
                        guard let metadata = metadata else {
                            // Uh-oh, an error occurred!
                            let alert = UIAlertController(text: "Upload failed.", actionTitle: "OK")
                            strongSelf.present(alert, animated: true, completion: {})
                            return
                        }
                        // Metadata contains file metadata such as size, content-type, and download URL.
                        let downloadURL = metadata.downloadURL()
                        strongSelf.videoPath = downloadURL?.absoluteString ?? ""
                        
                        strongSelf.update()
                        
                        let alert = UIAlertController(text: "Uploaded Completely.", actionTitle: "OK")
                        strongSelf.present(alert, animated: true, completion: {})
                        
                        strongSelf.loading(active: false)
                    }
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
            removeToSlot(index: indexPath.item)
        } else {
            // do not allow to choose more than 2
            guard dataSource.filter({ return $0.isSelected }).count < 2 else {
                return
            }
            video.isSelected = true
            addToSlot(index: indexPath.item)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func removeToSlot(index: Int) {
        if index1 == index {
            index1 = -1;
            imageView1.image = nil
            imageView3.image = nil
        }
        else if index2 == index {
            index2 = -1;
            imageView2.image = nil
            imageView3.image = nil
        }
        
        if index1 < 0 && index2 < 0 {
            loadMergedVideo()
        }
    }
    
    func addToSlot(index: Int) {
        let video: UserVideo = dataSource[index]
        if index1 < 0 {
            index1 = index
            //imageView1.imageFromUrl(link: video.png)
            imageView1.kf.setImage(with: URL(string: video.png))
            imageView3.image = nil
        }
        else if index2 < 0 {
            index2 = index
            //imageView2.imageFromUrl(link: video.png)
            imageView2.kf.setImage(with: URL(string: video.png))
            imageView3.image = nil
        }
        else {
            loadMergedVideo()
        }
    }
    
    func clearSlot() {
        index1 = -1
        imageView1.image = nil
        index2 = -1
        imageView2.image = nil
        imageView3.image = nil
        
        let selectedItems = dataSource.filter({ return $0.isSelected })
        for video in selectedItems {
            video.isSelected = false
        }
        collectionView.reloadData()
    }
}

//MARK:- Firebase
extension VideoViewController {
    fileprivate func update() {
        guard let userId = uid, let userName = name else {
            return
        }
        
        let video = MergedVideo(uid: userId, name: userName, mov: videoPath, png: thumbPath)
        video.update()
    }
    
    func uploadImage(image: UIImage) {
        guard let imageData: Data = UIImagePNGRepresentation(image) else {
            return
        }
        
        guard let userId = uid else {
            return
        }
        
        let refImage = Storage.storage().reference(withPath: "merge").child(userId + ".png")
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

