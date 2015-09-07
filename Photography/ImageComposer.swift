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
    private var dataArray: [NSData] = []
    
    func addImageData(imageData: NSData) {
        dataArray.append(imageData)
    }
    
    func process() -> NSData {
        let context = CIContext(options: nil)
        
    }
    
    func reset() {
        dataArray.removeAll(keepCapacity: true)
    }
}
