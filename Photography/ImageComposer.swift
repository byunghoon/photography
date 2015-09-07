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
    private var pictures: [GPUImagePicture] = []
    
    func addSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
        let image = UIImage(data: imageData)
        let picture = GPUImagePicture(image: image)
        pictures.append(picture)
    }
    
    func process() -> UIImage {
        let filter = MedianBlendingFilter()
        
        for var i = 0; i < pictures.count; i++ {
            pictures[i].addTarget(filter, atTextureLocation: i)
        }
        
        for var i = 0; i < pictures.count; i++ {
            pictures[i].processImage()
        }
        
        return filter.imageFromCurrentFramebuffer()
    }
    
    func reset() {
        pictures.removeAll(keepCapacity: true)
    }
}
