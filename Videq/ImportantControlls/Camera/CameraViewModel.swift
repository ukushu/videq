import SwiftUI
import Foundation
import AVFoundation

class CameraModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    @Published var output = AVCaptureMovieFileOutput()
    
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    // MARK: Video Recorder Properties
    @Published private(set) var isRecording: Bool = false
    @Published var recordedURLs: [URL] = [] { didSet { if recordedURLs.count == 0 && showPreview { showPreview = false} } }
    var previewURL: URL? {
        if recordedURLs.indices.contains(previewURLidx) {
            return previewURLidx == -1 ? nil : recordedURLs[previewURLidx]
        }
        
        return nil
    }
    
    @Published var previewURLidx: Int = -1 { didSet { if previewURLidx == -1 && showPreview { showPreview = false} } }
    @Published var showPreview: Bool = false
    
    let qualityPersets: [AVCaptureSession.Preset]
    
    override init() {
        let sess = AVCaptureSession()
        self.qualityPersets = sess.sessionPersetsAvailable
        _session = Published(initialValue: sess)
        super.init()
    }
}

extension CameraModel {
    func startRecording() {
        let tempURL = NSTemporaryDirectory() + "\(Date() ).mov"
        output.startRecording(to: URL(fileURLWithPath: tempURL) , recordingDelegate: self)
        
        isRecording = true
    }
    
    func stopRecording() {
        output.stopRecording()
        isRecording = false
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print (error.localizedDescription)
            return
        }
        
        //CREATED SUCCESSFULLY
        //print(outputFileURL)
        
        self.recordedURLs.append(outputFileURL)
        self.previewURLidx = recordedURLs.count - 1
    }
    
    func saveResult() {
        // Converting URLS to assets
        let assets = recordedURLs.compactMap{ url -> AVURLAsset in
            return AVURLAsset(url: url)
        }
        
        mergeVideos(assets: assets) { exporter in
            exporter.exportAsynchronously {
                if exporter.status == .failed {
                    // HANDLE error
                    print(exporter.error!)
                } else {
                    if let finalURL = exporter.outputURL {
                        print("EXPORT SUCCESS: \(finalURL)")
                        
                        DispatchQueue.main.async {
                            self.recordedURLs = []
                        }
                        
                        UISaveVideoAtPathToSavedPhotosAlbum(finalURL.path, nil, nil, nil)
                    }
                }
            }
        }
    }
}

extension CameraModel {
//    func setResolution(format: CMFormatDescription) {
//        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device
//        else { return }
//
//    }
    
    func switchCamera() {
        guard let currDevicePos = (session.inputs.first as? AVCaptureDeviceInput)?.device.position
        else { return }
        
        //Indicate that some changes will be made to the session
        session.beginConfiguration()
        
        //session.sessionPreset = .hd4K3840x2160
        
        //Get new input
        guard let newCamera = cameraWithPosition(position: (currDevicePos == .back) ? .front : .back )
        else {
            print("ERROR: Issue in cameraWithPosition() method")
            return
        }
        
        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            
            while session.inputs.count > 0 {
                session.removeInput(session.inputs[0])
            }
            
            session.addInput(newVideoInput)
        } catch let err1 as NSError {
            print("Error creating capture device input: \(err1.localizedDescription)")
        }
        
        //Commit all the configuration changes at once
        session.commitConfiguration()
    }
}

extension CameraModel {
    func checkPermission() {
        print ("checkPermission()...")
        
        // first checking camera has got permission...
        switch AVCaptureDevice.authorizationStatus (for: .video) {
        
        case .authorized:
            self.setUp()
            return
            // Setting Up Session...
        case .notDetermined:
            AVCaptureDevice.requestAccess (for: .video) { (status) in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
        default:
            return
        }
    }
    
    func setQuality(perset: AVCaptureSession.Preset) {
        session.beginConfiguration()
        
        self.session.sessionPreset = perset
        
        session.commitConfiguration()
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position : .front)
            let videoInput = try AVCaptureDeviceInput (device: videoDevice!)
            
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioInput = try AVCaptureDeviceInput (device: audioDevice!)
            
            // checking and adding to session .. .
            if self.session.canAddInput(videoInput) && self.session.canAddInput(audioInput)  {
                self.session.addInput(videoInput)
                self.session.addInput(audioInput)
            }
            
            // same for output. ...
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
}


/////////////////////////////
///HELPERS
//////////////////////////////

extension AVCaptureSession.Preset {
    var asStr: String {
        switch self {
        case .hd4K3840x2160:
            return "3840x2160"
        case .hd1920x1080:
            return "1920x1080"
        case .hd1280x720:
            return "1280x720"
        case .iFrame960x540:
            return "960x540"
        default:
            return "unsupported"
        }
    }
}

extension AVCaptureSession {
    var sessionPersetsAvailable: [AVCaptureSession.Preset] {
        var rez: [AVCaptureSession.Preset] = []
        
        if self.canSetSessionPreset(.iFrame960x540) {
            rez.append(.iFrame960x540)
        }
        if self.canSetSessionPreset(.hd1280x720) {
            rez.append(.hd1280x720)
        }
        if self.canSetSessionPreset(.hd1920x1080) {
            rez.append(.hd1920x1080)
        }
        if self.canSetSessionPreset(.hd4K3840x2160) {
            rez.append(.hd4K3840x2160)
        }
        
        return rez
    }
}

fileprivate extension CameraModel {
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        for device in discoverySession.devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    func mergeVideos(assets: [AVURLAsset], completion: @escaping (_ exporter: AVAssetExportSession) -> () ) {
        let composition = AVMutableComposition()
        var lastTime: CMTime = .zero
        
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        else { return }
        
        for asset in assets {
            do {
                try videoTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: asset.tracks(withMediaType: .video)[0],
                    at: lastTime
                )
                // safe check if video has an audio
                if !asset.tracks(withMediaType: .audio).isEmpty {
                    try audioTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: asset.duration),
                        of: asset.tracks(withMediaType: .audio)[0],
                        at: lastTime
                    )
                }
            } catch {
                print(error.localizedDescription)
            }
            
            lastTime = CMTimeAdd(lastTime, asset.duration)
        }
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()+"Reel-\(UUID().uuidString)-\(Date()).mp4")
        
        //Video is rotated
        // bringing back to original transform
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // transform
        var transform = CGAffineTransform.identity
        transform = transform.rotated(by: 90 * (.pi / 180) )
        transform = transform.translatedBy(x: 0, y: -videoTrack.naturalSize.height)
        layerInstructions.setTransform(transform, at: .zero)
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRange(start: .zero, duration: lastTime)
        instructions.layerInstructions = [layerInstructions]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        else { return }
        
        exporter.outputFileType = .mp4
        exporter.outputURL = tempURL
        exporter.videoComposition = videoComposition
        completion(exporter)
    }
}

//fileprivate extension CameraModel {
//    // all is available in iOS 11.1
//    var supportedDevices: [AVCaptureDevice.DeviceType] { return [.builtInWideAngleCamera,.builtInTripleCamera, .builtInDualCamera] }
//}


// Need to look
//https://gist.github.com/yusuke024/3b5a89835deab5b9027efea794b80a45
