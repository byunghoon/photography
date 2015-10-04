//
//  AttitudeCubicSpline.swift
//  Photography
//
//  Created by Byunghoon Yoon on 2015-10-04.
//  Copyright © 2015 Byunghoon. All rights reserved.
//

import CoreMotion
import SwiftCubicSpline

struct RotationMatrix {
    let m11: CGFloat
    let m12: CGFloat
    let m13: CGFloat
    let m21: CGFloat
    let m22: CGFloat
    let m23: CGFloat
    let m31: CGFloat
    let m32: CGFloat
    let m33: CGFloat
}

class TimeRotationPair: NSObject {
    let time: Double
    let rotationMatrix: RotationMatrix
    
    init(time: NSTimeInterval, rotationMatrix: CMRotationMatrix) {
        self.time = Double(time)
        self.rotationMatrix = RotationMatrix(m11: CGFloat(rotationMatrix.m11), m12: CGFloat(rotationMatrix.m12), m13: CGFloat(rotationMatrix.m13), m21: CGFloat(rotationMatrix.m21), m22: CGFloat(rotationMatrix.m22), m23: CGFloat(rotationMatrix.m23), m31: CGFloat(rotationMatrix.m31), m32: CGFloat(rotationMatrix.m32), m33: CGFloat(rotationMatrix.m33))
    }
}

struct TimeRotationCubicSpline {
    let m11Spline: CubicSpline
    let m12Spline: CubicSpline
    let m13Spline: CubicSpline
    let m21Spline: CubicSpline
    let m22Spline: CubicSpline
    let m23Spline: CubicSpline
    let m31Spline: CubicSpline
    let m32Spline: CubicSpline
    let m33Spline: CubicSpline
    
    let offset: CGFloat
    let diff: CGFloat
    
    init(points: [TimeRotationPair]) {
        var m11Points: [CGPoint] = []
        var m12Points: [CGPoint] = []
        var m13Points: [CGPoint] = []
        var m21Points: [CGPoint] = []
        var m22Points: [CGPoint] = []
        var m23Points: [CGPoint] = []
        var m31Points: [CGPoint] = []
        var m32Points: [CGPoint] = []
        var m33Points: [CGPoint] = []
        
        if let startTime = points.first?.time, endTime = points.last?.time where startTime < endTime {
            offset = CGFloat(startTime)
            diff = CGFloat(endTime - startTime)
            for point in points {
                let x = (CGFloat(point.time) - offset) / diff
                m11Points.append(CGPoint(x: x, y: point.rotationMatrix.m11))
                m12Points.append(CGPoint(x: x, y: point.rotationMatrix.m12))
                m13Points.append(CGPoint(x: x, y: point.rotationMatrix.m13))
                m21Points.append(CGPoint(x: x, y: point.rotationMatrix.m21))
                m22Points.append(CGPoint(x: x, y: point.rotationMatrix.m22))
                m23Points.append(CGPoint(x: x, y: point.rotationMatrix.m23))
                m31Points.append(CGPoint(x: x, y: point.rotationMatrix.m31))
                m32Points.append(CGPoint(x: x, y: point.rotationMatrix.m32))
                m33Points.append(CGPoint(x: x, y: point.rotationMatrix.m33))
                
                print("\(x):\t\(point.rotationMatrix.m13)")
            }
        } else {
            offset = 0
            diff = 1
        }

        m11Spline = CubicSpline(points: m11Points)
        m12Spline = CubicSpline(points: m12Points)
        m13Spline = CubicSpline(points: m13Points)
        m21Spline = CubicSpline(points: m21Points)
        m22Spline = CubicSpline(points: m22Points)
        m23Spline = CubicSpline(points: m23Points)
        m31Spline = CubicSpline(points: m31Points)
        m32Spline = CubicSpline(points: m32Points)
        m33Spline = CubicSpline(points: m33Points)
    }
    
    func interpolate(time: NSTimeInterval) -> RotationMatrix {
        let x = (CGFloat(time) - offset) / diff
        let rotationMatrix = RotationMatrix(m11: m11Spline.interpolate(x), m12: m12Spline.interpolate(x), m13: m13Spline.interpolate(x), m21: m21Spline.interpolate(x), m22: m22Spline.interpolate(x), m23: m22Spline.interpolate(x), m31: m31Spline.interpolate(x), m32: m32Spline.interpolate(x), m33: m33Spline.interpolate(x))
        
        print("\nAt \(x):\t\(rotationMatrix.m13)\n")
        return rotationMatrix
    }
}
