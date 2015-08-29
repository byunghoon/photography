//
//  SessionManager.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-08-29.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation

enum SessionStatus {
    case Success, NotAuthorized, ConfigurationFailed
}

protocol SessionManagerDelegate {
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) //?
    func sessionManager(sessionManager: SessionManager, didFailResumptionWithStatus: SessionStatus)
}

let SessionRunningContext = UnsafeMutablePointer<Void>()
let CapturingStillImageContext = UnsafeMutablePointer<Void>()

class SessionManager: NSObject {
    let session = AVCaptureSession()
    let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
    
    let previewLayer: AVCaptureVideoPreviewLayer
    var delegate: SessionManagerDelegate?
    
    var status: SessionStatus = .NotAuthorized
    
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
                
            default:
                self.delegate?.sessionManager(self, didFailResumptionWithStatus: self.status)
            }
        })
    }
    
    func pause() {
        dispatch_async(queue, { () -> Void in
            if self.status == .Success {
                self.session.stopRunning()
                self.removeObservers()
            }
        })
    }
    
    
    // MARK: I/O setup
    
    private var currentInput: AVCaptureDeviceInput?
    private var currentOutput: AVCaptureStillImageOutput?
    
    private func setupInput(devicePosition preferringDevicePosition: AVCaptureDevicePosition) {
        if let input = currentInput {
            session.removeInput(input)
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
        
        var error: NSError?
        if let videoDevice = videoDevice, let videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as? AVCaptureDeviceInput where session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            currentInput = videoDeviceInput
            
        } else {
            println("Could not add video device input to the session")
            if let error = error {
                println(error);
            }
            status = .ConfigurationFailed
        }
    }
    
    private func setupOutput() {
        if let output = currentOutput {
            session.removeOutput(currentOutput)
            currentOutput = nil
        }
        
        let stillImageOutput = AVCaptureStillImageOutput()
        if session.canAddOutput(stillImageOutput) {
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            session.addOutput(stillImageOutput)
            currentOutput = stillImageOutput
            
        } else {
            println("Could not add still image output to the session")
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
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == SessionRunningContext {
            
            
        } else if context == CapturingStillImageContext {
            
            
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func subjectAreaDidChange(notification: NSNotification) {
        
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        
    }
    
}
