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
        sessionManager.delegate = self
        
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
    
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) {
        //
    }
    
    func sessionManager(sessionManager: SessionManager, didFailResumptionWithStatus: SessionStatus) {
        presentViewController(UIAlertController(title: "Session resumption failed", message: nil, preferredStyle: UIAlertControllerStyle.Alert), animated: true, completion: nil)
    }
    
    func sessionManager(sessionManager: SessionManager, isCapturingStillImage: Bool) {
        //
    }
    
    func sessionManager(sessionManager: SessionManager, isSessionRunning: Bool) {
        //
    }
    
}
