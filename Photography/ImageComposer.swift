//
//  ImageComposer.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-09-06.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import UIKit
import AVFoundation
//import Photos

class ImageComposer: NSObject {
    let images: [UIImage] = []
    
    func addSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
        images.append(<#T##newElement: UIImage##UIImage#>)

    }
    
    func process() {
        
    }
}
