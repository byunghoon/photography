//
//  Utility.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-08-29.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import Foundation

class Utility {
    class func getTemporaryFileURL() -> NSURL? {
        guard let temporaryFileName = (NSProcessInfo.processInfo().globallyUniqueString as NSString).stringByAppendingPathExtension("jpg") else {
            return nil
        }
        let temporaryFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(temporaryFileName)
        return NSURL.fileURLWithPath(temporaryFilePath)
    }
}