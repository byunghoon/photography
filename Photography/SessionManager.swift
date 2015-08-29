//
//  SessionManager.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-08-29.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation

private let SessionRunningContext = UnsafeMutablePointer<Void>()
private let CapturingStillImageContext = UnsafeMutablePointer<Void>()

enum SessionStatus {
    case Success, NotAuthorized, ConfigurationFailed
}

protocol SessionManagerDelegate {
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) //?
    func sessionManager(sessionManager: SessionManager, didFailResumptionWithStatus: SessionStatus)
    
    func sessionManager(sessionManager: SessionManager, isCapturingStillImage: Bool)
    func sessionManager(sessionManager: SessionManager, isSessionRunning: Bool)
}

class SessionManager: NSObject {
    let session = AVCaptureSession()
    let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
    
    let previewLayer: AVCaptureVideoPreviewLayer
    var delegate: SessionManagerDelegate?
    
    var status: SessionStatus = .NotAuthorized
    var sessionShouldRun = false
    
    
    // MARK: session lifecycle
    
    init(previewLayer layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        previewLayer.session = session
    }
    
    func configure() {
        dispatch_async(queue, { () -> Void in
            if self.status != .Success {
                return
            }
            
            // set background recording ID as UIBackgroundTaskInvalid
            
            self.setupInput(devicePosition: .Back)
            
            // might want to modify previewLayer.connection.videoOrientation from main queue (see line 129 in AAPLCameraViewController.m)
            
            self.setupOutput()
            
            self.session.commitConfiguration()
        })
    }
    
    func resume() {
        dispatch_async(queue, { () -> Void in
            switch (self.status) {
            case .Success:
                self.addObservers()
                
                self.session.startRunning()
                self.sessionShouldRun = self.session.running
                
            default:
                self.delegate?.sessionManager(self, didFailResumptionWithStatus: self.status)
            }
        })
    }
    
    func pause() {
        dispatch_async(queue, { () -> Void in
            if self.status == .Success {
                self.session.stopRunning()
                // is self.sessionShouldRun = self.session.running required?
                
                self.removeObservers()
            }
        })
    }
    
    
    // MARK: camera
    
    func changeCamera() {
        
    }
    
    func snapStillImage() {
        
    }
    
    func focus(atDevicePoint devicePoint: CGPoint) {
        
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
            print("Video device not found")
            return
        }
        
        if let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) where session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            currentInput = videoDeviceInput
            
        } else {
            print("Could not add video device input to the session")
            status = .ConfigurationFailed
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
            print("Could not add still image output to the session")
            status = .ConfigurationFailed
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
                        // show resume button (from main queue)
                    }
                })
            }
            
        } else {
            // show resume button (from main queue)
        }
    }
    
}
