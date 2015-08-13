//
//  MainViewController.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-07-25.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {
    private var sessionManager: SessionManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionManager = SessionManager(previewLayer: view.layer as! AVCaptureVideoPreviewLayer)
        
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
        
        sessionManager.start()
        
        // enable UI
        // ...
    }
}

private enum SessionStatus {
    case Success, NotAuthorized, ConfigurationFailed
}

private class SessionManager {
    let session = AVCaptureSession()
    let queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL)
    let previewLayer: AVCaptureVideoPreviewLayer
    
    var status: SessionStatus = .NotAuthorized
    private var currentInput: AVCaptureDeviceInput?

    init(previewLayer layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        previewLayer.session = session
    }
    
    func start() {
        dispatch_async(queue, { () -> Void in
            if self.status != .Success {
                return
            }
            
            self.setupInput(devicePosition: .Back)
            
            // might want to modify previewLayer.connection.videoOrientation from main queue
            
            self.setupOutput()
        })
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
            status = .ConfigurationFailed
        }
    }
    
    private func setupOutput() {
        
    }
}

