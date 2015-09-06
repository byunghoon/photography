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
    private var sessionManager: SessionManager!
    
    private var userInterfaceEnabled: Bool = false {
        didSet {
            shutterButton.enabled = userInterfaceEnabled
        }
    }
    
    @IBOutlet private weak var shutterButton: UIButton!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionManager = SessionManager(previewLayer: view.layer as! AVCaptureVideoPreviewLayer)
        sessionManager.delegate = self
        
        userInterfaceEnabled = false
        
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:
            sessionManager.isAuthorized = true
            
        case .NotDetermined:
            dispatch_suspend(sessionManager.queue)
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
                self.sessionManager.isAuthorized = granted
                dispatch_resume(self.sessionManager.queue)
            })
            
        default:
            sessionManager.isAuthorized = false
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
    
    func sessionManager(sessionManager: SessionManager, didFailWithReason reason: FailureReason) {
        userInterfaceEnabled = false
        presentViewController(UIAlertController(title: "Session resumption failed", message: reason.description, preferredStyle: UIAlertControllerStyle.Alert), animated: true, completion: nil)
    }
    
    func sessionManagerIsReadyForBracketedCapture(sessionManager: SessionManager) {
        userInterfaceEnabled = true
    }
    
    func sessionManager(sessionManager: SessionManager, shouldUpdateOrientation orientation: UIInterfaceOrientation) {
        //
    }
    
    func sessionManager(sessionManager: SessionManager, isCapturingStillImage: Bool) {
        view.layer.opacity = 0
        UIView.animateWithDuration(0.25) { () -> Void in
            self.view.layer.opacity = 1
        }
    }
    
    func sessionManager(sessionManager: SessionManager, isSessionRunning: Bool) {
        //
    }
    
    
    // MARK: outlets
    
    @IBAction func didTapCapture(sender: AnyObject) {
        sessionManager.snapStillImage()
    }
    
}
