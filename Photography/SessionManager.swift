//
//  SessionManager.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-08-29.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

private let SessionRunningContext = UnsafeMutablePointer<Void>()
private let CapturingStillImageContext = UnsafeMutablePointer<Void>()

typealias ImageCompletion = (success: Bool) -> Void

protocol SessionManagerDelegate {
    func sessionManager(sessionManager: SessionManager, didFailWithReason reason: FailureReason)
    
    func sessionManagerIsReadyForBracketedCapture(sessionManager: SessionManager)
    
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) //?
    
    func sessionManager(sessionManager: SessionManager, isCapturingStillImage: Bool)
    func sessionManager(sessionManager: SessionManager, isSessionRunning: Bool)
}

enum FailureReason: String, CustomStringConvertible {
    case
    CameraAccessNotAuthorized,
    PhotosAccessNotAuthorized,
    
    CaptureDeviceNotFound,
    CaptureDeviceCannotBeOpened,
    CaptureDeviceInputCannotBeAdded,
    
    StillImageOutputCannotBeAdded,
    StillImageOutputDoesNotExist,
    
    BracketsCannotBePrepared,
    
    ImageTemporaryFileCannotBeCreated,
    ImageCannotBeSaved,
    
    SessionNotConfigured,
    SessionRuntimeError, // should show resume button (from main queue)
    
    Unknown
    
    var description: String {
        return self.rawValue
    }
}

private struct SessionConfiguration {
    static let maxBracketedImageCount = 3
}

class SessionManager: NSObject {
    private let session = AVCaptureSession()
    let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
    
    let previewLayer: AVCaptureVideoPreviewLayer
    var delegate: SessionManagerDelegate?
    
    var isAuthorized = false
    private(set) var isConfigured = false
    private var sessionShouldRun = false
    
    var exposureBias: Float = 0
    var bracketSettings: [AVCaptureAutoExposureBracketedStillImageSettings] = []
    
    let imageComposer = ImageComposer()
    
    
    // MARK: session lifecycle
    
    init(previewLayer layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        previewLayer.session = session
    }
    
    func configure() {
        dispatch_async(queue, { () -> Void in
            if !self.isAuthorized {
                self.failedWithReason(.CameraAccessNotAuthorized)
                return
            }
            
            // TODO: better way to set isConfigured
            self.isConfigured = true
            
            self.session.beginConfiguration()
            
            if self.session.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
                self.session.sessionPreset = AVCaptureSessionPresetPhoto
            }
            
            // set background recording ID as UIBackgroundTaskInvalid
            
            self.setupInput(devicePosition: .Back)
            
            // might want to modify previewLayer.connection.videoOrientation from main queue (see line 129 in AAPLCameraViewController.m from AVCam)
            
            self.setupOutput()
            
            self.session.commitConfiguration()
        })
    }
    
    func resume() {
        dispatch_async(queue, { () -> Void in
            if !(self.isAuthorized && self.isConfigured) {
                self.failedWithReason(.SessionNotConfigured)
                return
            }
            
            self.addObservers()
            
            self.session.startRunning()
            self.sessionShouldRun = self.session.running
            
            self.prepareBrackets()
        })
    }
    
    func pause() {
        dispatch_async(queue, { () -> Void in
            if !self.isAuthorized && self.isConfigured {
                return
            }
            
            self.session.stopRunning()
            // is self.sessionShouldRun = self.session.running required?
            
            self.removeObservers()
        })
    }
    
    
    // MARK: camera
    
    func changeCamera() {
    }
    
    func snapStillImage() {
        dispatch_async(queue, { () -> Void in
            //self.performSingleCapture()
            self.performBracketedCapture({ (success) -> Void in
                //
            })
        })
    }
    
    func focus(atDevicePoint devicePoint: CGPoint) {
        
    }
    
    
    // MARK: helper
    
    private func failedWithReason(reason: FailureReason) {
        delegate?.sessionManager(self, didFailWithReason: reason)
        isConfigured = false
    }
    
    
    // MARK: in-queue operation
    
    private func prepareBrackets() {
        guard let stillImageOutput = currentOutput else {
            failedWithReason(.StillImageOutputDoesNotExist)
            return
        }
        
        let connection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        connection.videoOrientation = previewLayer.connection.videoOrientation
        
        for var i = 0; i < min(SessionConfiguration.maxBracketedImageCount, stillImageOutput.maxBracketedCaptureStillImageCount); i++ {
            bracketSettings.append(AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettingsWithExposureTargetBias(exposureBias))
        }
        
        stillImageOutput.prepareToCaptureStillImageBracketFromConnection(connection, withSettingsArray: bracketSettings, completionHandler: { (prepared: Bool, error: NSError!) -> Void in
            if prepared {
                print("Successfully prepared brackets (max: \(stillImageOutput.maxBracketedCaptureStillImageCount), actual: \(self.bracketSettings.count))")
                self.delegate?.sessionManagerIsReadyForBracketedCapture(self)
                
            } else {
                self.failedWithReason(.BracketsCannotBePrepared)
            }
        })
    }
    
    private func performBracketedCapture(completion: ImageCompletion) {
        guard let stillImageOutput = currentOutput else {
            failedWithReason(.StillImageOutputDoesNotExist)
            return
        }
        
        let connection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        connection.videoOrientation = previewLayer.connection.videoOrientation
        
        var numberOfWaitingBrackets = bracketSettings.count
        var failure = false
        
        stillImageOutput.captureStillImageBracketAsynchronouslyFromConnection(connection, withSettingsArray: bracketSettings) { (sampleBuffer: CMSampleBuffer!, stillImageSettings: AVCaptureBracketedStillImageSettings!, error: NSError!) -> Void in
            
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
            print("captured!")
            self.saveImage(imageData)
        }
    }
    
    private func performSingleCapture() {
        guard let stillImageOutput = self.currentOutput else {
            self.failedWithReason(.StillImageOutputDoesNotExist)
            return
        }
        
        let connection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
        connection.videoOrientation = self.previewLayer.connection.videoOrientation
        
        // might want to update flash settings (see line 558 in AAPLCameraViewController.m from AVCam)
        
        stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataSampleBuffer: CMSampleBuffer!, error: NSError!) -> Void in
            // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
            self.saveImage(imageData)
        })
    }
    
    private func saveImage(imageData: NSData) {
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
            if status != .Authorized {
                self.failedWithReason(.PhotosAccessNotAuthorized)
                return
            }
            
            // TODO: iOS9 - use PHAssetCreationRequest.addResourceWithType() instead
            // see line 569 in AAPLCameraViewController.m from AVCam
            
            guard let temporaryFileURL = Utility.getTemporaryFileURL() else {
                self.failedWithReason(.ImageTemporaryFileCannotBeCreated)
                return
            }
            
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                imageData.writeToURL(temporaryFileURL, atomically: true)
                PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(temporaryFileURL)
                
                }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        if let _ = error {
                            self.failedWithReason(.ImageCannotBeSaved)
                            print("Error occurred while saving image to photo library: \(error)")
                            
                        } else {
                            self.failedWithReason(.Unknown)
                        }
                        
                        try! NSFileManager.defaultManager().removeItemAtURL(temporaryFileURL)
                    }
            })
        })
    }

    
    // MARK: I/O setup
    
    private var currentInput: AVCaptureDeviceInput?
    private var currentOutput: AVCaptureStillImageOutput?
    
    private func setupInput(devicePosition preferringDevicePosition: AVCaptureDevicePosition) {
        if let _ = currentInput {
            session.removeInput(currentInput)
            currentInput = nil
        }
        
        var videoDevice: AVCaptureDevice?
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            if let device = device as? AVCaptureDevice {
                videoDevice = device
                if device.position == preferringDevicePosition {
                    break
                }
            }
        }
        
        guard let _ = videoDevice else {
            self.failedWithReason(.CaptureDeviceNotFound)
            return
        }
        
        if let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) {
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                currentInput = videoDeviceInput
                
            } else {
                self.failedWithReason(.CaptureDeviceInputCannotBeAdded)
            }
            
        } else {
            self.failedWithReason(.CaptureDeviceCannotBeOpened)
        }
    }
    
    private func setupOutput() {
        if let _ = currentOutput {
            session.removeOutput(currentOutput)
            currentOutput = nil
        }
        
        let stillImageOutput = AVCaptureStillImageOutput()
        if session.canAddOutput(stillImageOutput) {
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            session.addOutput(stillImageOutput)
            currentOutput = stillImageOutput
            
        } else {
            self.failedWithReason(.StillImageOutputCannotBeAdded)
        }
    }
    
    
    // MARK: KVO
    
    private let kSessionRunning = "sessionRunning"
    private let kCapturingStillImage = "capturingStillImage"
    
    private func addObservers() {
        // TODO: try removing context and use keyPath
        session.addObserver(self, forKeyPath: kSessionRunning, options: NSKeyValueObservingOptions.New, context: SessionRunningContext)
        currentOutput?.addObserver(self, forKeyPath: kCapturingStillImage, options: NSKeyValueObservingOptions.New, context: CapturingStillImageContext)
        
        if let device = currentInput?.device {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "subjectAreaDidChange:", name: AVCaptureDeviceSubjectAreaDidChangeNotification, object: device)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionRuntimeError:", name: AVCaptureSessionRuntimeErrorNotification, object: session)
        
        // for iOS 9: may need to listen to AVCaptureSessionWasInterruptedNotification AVCaptureSessionInterruptionEndedNotification
    }
    
    private func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        session.removeObserver(self, forKeyPath: kSessionRunning, context: SessionRunningContext)
        currentOutput?.removeObserver(self, forKeyPath: kCapturingStillImage, context: CapturingStillImageContext)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == SessionRunningContext {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.delegate?.sessionManager(self, isCapturingStillImage: change?[NSKeyValueChangeNewKey]?.boolValue ?? false)
            })
            
        } else if context == CapturingStillImageContext {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.delegate?.sessionManager(self, isSessionRunning: change?[NSKeyValueChangeNewKey]?.boolValue ?? false)
            })
            
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func subjectAreaDidChange(notification: NSNotification) {
        //CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
        //[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        if let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError {
            print("Capture session runtime error \(error)")
            
            // Automatically try to restart the session running if media services were reset and the last start running succeeded.
            // Otherwise, enable the user to try to resume the session running.
            if error.code == AVError.MediaServicesWereReset.rawValue {
                dispatch_async(queue, { () -> Void in
                    if self.sessionShouldRun {
                        self.session.startRunning()
                        self.sessionShouldRun = self.session.running
                        
                    } else {
                        self.failedWithReason(.SessionRuntimeError)
                    }
                })
            }
            
        } else {
            self.failedWithReason(.SessionRuntimeError)
        }
    }
    
}
