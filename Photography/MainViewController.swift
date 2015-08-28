//
//  MainViewController.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-07-25.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewView: UIView {
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

class MainViewController: UIViewController, SessionManagerDelegate {
    private var previewView: PreviewView = PreviewView()
    private var sessionManager: SessionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(previewView)
        
        sessionManager = SessionManager(previewLayer: previewView.layer as! AVCaptureVideoPreviewLayer)
        
        // disable UI
        // ...
        
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:
            sessionManager.status = .Success
        case .NotDetermined:
            dispatch_suspend(sessionManager.queue)
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
                self.sessionManager.status = granted ? .Success : .NotAuthorized
                dispatch_resume(self.sessionManager.queue)
            })
        default:
            sessionManager.status = .NotAuthorized
        }
        
        sessionManager.configure()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        sessionManager.resume()
    }
    
    override func viewWillDisappear(animated: Bool) {
        sessionManager.pause()
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: session manager delegate
    
    private func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) {
        //
    }
    
    private func sessionManager(sessionManager: SessionManager, didFailResumptionWithStatus: SessionStatus) {
        presentViewController(UIAlertController(title: "Session resumption failed", message: nil, preferredStyle: UIAlertControllerStyle.Alert), animated: true, completion: nil)
    }
}

private enum SessionStatus {
    case Success, NotAuthorized, ConfigurationFailed
}

private protocol SessionManagerDelegate {
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) //?
    func sessionManager(sessionManager: SessionManager, didFailResumptionWithStatus: SessionStatus)
}

private class SessionManager {
    let session = AVCaptureSession()
    let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
    
    let previewLayer: AVCaptureVideoPreviewLayer
    var delegate: SessionManagerDelegate?
    
    var status: SessionStatus = .NotAuthorized
    private var currentInput: AVCaptureDeviceInput?
    private var currentOutput: AVCaptureStillImageOutput?

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
    
    func addObservers() {
        
    }
    
    func removeObservers() {
        
    }
    
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
}

