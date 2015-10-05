//
//  ImageViewController.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-10-04.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fullImageView: UIImageView!
    @IBOutlet weak var scaledImageView: UIImageView!
    @IBOutlet weak var fullImageWidth: NSLayoutConstraint!
    @IBOutlet weak var fullImageHeight: NSLayoutConstraint!
    
    var originalImage: UIImage? { didSet { updateViews() } }
    var processedImage: UIImage? { didSet { updateViews() } }
    
    enum ImageViewMode { case Full, Scaled }
    var viewMode: ImageViewMode = .Scaled { didSet { updateViews() } }
    
    enum ImageType { case Original, Processed }
    var presentedImage: ImageType = .Original { didSet { updateViews() } }
    
    class func controllerFromStoryboard() -> ImageViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ImageViewController") as! ImageViewController
    }

    
    // MARK: view
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItems = [UIBarButtonItem(title: "Mode", style: UIBarButtonItemStyle.Plain, target: self, action: "didTapMode"), UIBarButtonItem(title: "Type", style: UIBarButtonItemStyle.Plain, target: self, action: "didTapType")]
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "didTapDone")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        viewMode = .Scaled
        presentedImage = .Original
    }
    
    private func updateViews() {
        switch viewMode {
        case .Full:
            scrollView.hidden = false
            scaledImageView.hidden = true
            
            fullImageView.image = presentedImage == .Original ? originalImage : processedImage
            if let image = fullImageView.image {
                fullImageWidth.constant = image.size.width
                fullImageHeight.constant = image.size.height
                scrollView.contentSize = image.size
            }
            
        case .Scaled:
            scrollView.hidden = true
            scaledImageView.hidden = false
            
            scaledImageView.image = presentedImage == .Original ? originalImage : processedImage
        }
    }
    
    
    // MARK: actions
    
    func didTapMode() {
        viewMode = viewMode == .Full ? .Scaled : .Full
    }
    
    func didTapType() {
        presentedImage = presentedImage == .Original ? .Processed : .Original
    }
    
    func didTapDone() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
