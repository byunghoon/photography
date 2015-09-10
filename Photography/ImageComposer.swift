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
    private let filter = MedianBlendingFilter()
    private var dataArray: [NSData] = []
    
    func addImageData(imageData: NSData) {
        dataArray.append(imageData)
    }
    
    func process() -> UIImage? {
        if dataArray.count < 3 {
            return nil
        }
        
        filter.inputImage0 = CIImage(data: dataArray[0])
        filter.inputImage1 = CIImage(data: dataArray[1])
        filter.inputImage2 = CIImage(data: dataArray[2])
        
        if let outputImage = filter.outputImage {
            return UIImage(CIImage: outputImage)
        }
        
        return nil
    }
    
    func reset() {
        dataArray.removeAll(keepCapacity: true)
    }
}
