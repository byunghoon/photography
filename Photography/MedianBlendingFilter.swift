//
//  MedianBlendingFilter.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-09-07.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import CoreImage

private var medianBlendingKernel: CIColorKernel?

class MedianBlendingFilter: CIFilter {
    var inputImage0: CIImage?
    var inputImage1: CIImage?
    var inputImage2: CIImage?
    
    override init() {
        if medianBlendingKernel == nil {
            let bundle = NSBundle(forClass: MedianBlendingFilter.self)
            if let contents = bundle.pathForResource("MedianBlending", ofType: "cikernel"), let code = try? String(contentsOfFile: contents) {
                medianBlendingKernel = CIColorKernel(string: code)
            }
        }
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        guard let inputImage0 = inputImage0, let inputImage1 = inputImage1, let inputImage2 = inputImage2, let kernel = medianBlendingKernel else {
            return nil
        }
        
        let dod = inputImage0.extent
        let args = [inputImage0 as AnyObject, inputImage1 as AnyObject, inputImage2 as AnyObject]
        return kernel.applyWithExtent(dod, arguments: args)
    }
}
