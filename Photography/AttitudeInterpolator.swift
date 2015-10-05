//
//  AttitudeCubicSpline.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-10-04.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import UIKit
import CoreMotion

struct Attitude {
    let pitch: CGFloat
    let roll: CGFloat
    let yaw: CGFloat
}

struct TimeAttitudePair {
    let time: CGFloat
    let attitude: Attitude
    
    init() {
        self.time = 0
        self.attitude = Attitude(pitch: 0, roll: 0, yaw: 0)
    }
    
    init(time: NSTimeInterval, attitude: CMAttitude) {
        self.time = CGFloat(time)
        self.attitude = Attitude(pitch: CGFloat(attitude.pitch), roll: CGFloat(attitude.roll), yaw: CGFloat(attitude.yaw))
    }
}

class AttitudeInterpolator {
    class func interpolate(points: [TimeAttitudePair], time: NSTimeInterval) -> Attitude {
        var p0 = points[0]
        var p1 = points[1]
        for var i = 2; i < points.count - 1; i++ {
            if points[i].time > CGFloat(time) {
                p0 = points[i - 1]
                p1 = points[i]
                break
            }
        }
        return interpolate(p0: p0, p1: p1, x: CGFloat(time))
    }
    
    private class func interpolate(p0 p0: TimeAttitudePair, p1: TimeAttitudePair, x: CGFloat) -> Attitude {
        let pitch = interpolate(p0: CGPointMake(p0.time, p0.attitude.pitch), p1: CGPointMake(p1.time, p1.attitude.pitch), x: x)
        let roll = interpolate(p0: CGPointMake(p0.time, p0.attitude.roll), p1: CGPointMake(p1.time, p1.attitude.roll), x: x)
        let yaw = interpolate(p0: CGPointMake(p0.time, p0.attitude.yaw), p1: CGPointMake(p1.time, p1.attitude.yaw), x: x)
        
        return Attitude(pitch: pitch, roll: roll, yaw: yaw)
    }
    
    private class func interpolate(p0 p0: CGPoint, p1: CGPoint, x: CGFloat) -> CGFloat {
        let a = (p1.y - p0.y) / (p1.x - p0.x)
        let b = p0.y - (a * p0.x)
        let y = (a * x) + b
        print("Given \(p0) and \(p1), at x of \(x) y is \(y)")
        return y
    }
}
