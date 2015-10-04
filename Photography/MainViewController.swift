//
//  MainViewController.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-07-25.
//  Copyright (c) 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

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
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet private weak var shutterButton: UIButton!
    
    
    // MARK: view
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionManager = SessionManager(previewLayer: previewView.layer as! AVCaptureVideoPreviewLayer)
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
    
    func sessionManager(sessionManager: SessionManager, originalImage: UIImage?, processedImage: UIImage?) {
        let imageViewController = ImageViewController.controllerFromStoryboard()
        imageViewController.originalImage = originalImage
        imageViewController.processedImage = processedImage
        
        let navigationController = UINavigationController(rootViewController: imageViewController)
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
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
        previewView.layer.opacity = 0
        UIView.animateWithDuration(0.25) { () -> Void in
            self.previewView.layer.opacity = 1
        }
    }
    
    func sessionManager(sessionManager: SessionManager, isSessionRunning: Bool) {
        //
    }
    
//    func sessionManager(sessionManager: SessionManager, didUpdateAttitude attitude: CMAttitude) {
//        let r = attitude.rotationMatrix
//        previewImageView.layer.transform = CATransform3D(m11: CGFloat(r.m11), m12: CGFloat(r.m12), m13: CGFloat(r.m13), m14: 0, m21: CGFloat(r.m21), m22: CGFloat(r.m22), m23: CGFloat(r.m23), m24: 0, m31: CGFloat(r.m31), m32: CGFloat(r.m32), m33: CGFloat(r.m33), m34: 0, m41: 0, m42: 0, m43: 0, m44: 1)
//    }
    
    
    // MARK: outlets
    
    @IBAction func didTapCapture(sender: AnyObject) {
        sessionManager.snapStillImage()
    }
}
