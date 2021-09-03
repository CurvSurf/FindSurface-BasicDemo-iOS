//
//  FindSurfaceDemo.swift
//  FindSurfaceiOS
//
//  Created by CurvSurf MacBook Pro on 2021/08/18.
//

import Combine
#if !targetEnvironment(simulator)
import FindSurfaceFramework

protocol Preset {
    var featureType: FindSurface.FeatureType { get }
    var seedIndex: Int { get }
}

var trial: Int = 0

// run FindSurface API to search geometry information from the point cloud
// and print the result in the console window.
func runFindSurfaceDemo(_ normalPresets: [Preset], _ smartPresets: [Preset], _ points: [Float32]) {
    
    let measurementAccuracy: Float = 0.01
    let meanDistance: Float = 0.01
    let seedRadius: Float = 0.025
    
    let fsCtx = FindSurface.sharedInstance()
    
    fsCtx.measurementAccuracy = measurementAccuracy
    fsCtx.meanDistance = meanDistance
    fsCtx.setPointCloudData(points,
                            pointCount: points.count / 3,
                            pointStride: MemoryLayout<Float32>.stride * 3,
                            useDoublePrecision: false)
    
    print("Normal cases: ")
    trial = 1
    
    for preset in normalPresets {
        runTest(fsCtx, preset.featureType, preset.seedIndex, seedRadius)
    }
     
    print("Smart cases: ")
    trial = 1
    
    fsCtx.smartConversionOptions = [
        .torus2Sphere,
        .torus2Cylinder,
        .cone2Cylinder
    ]
    
    for preset in smartPresets {
        runTest(fsCtx, preset.featureType, preset.seedIndex, seedRadius)
    }
}

fileprivate func runTest(_ fsCtx: FindSurface,
                         _ featureType: FindSurface.FeatureType,
                         _ seedIndex: Int,
                         _ seedRadius: Float) {
    
    defer { trial += 1 }
    
    print("\(trial). FindSurface searched for a \(featureType)")
    print("around the point of which index is \(seedIndex).")
    
    do {
        guard let result = try fsCtx.findSurface(featureType: featureType,
                                                 seedIndex: seedIndex,
                                                 seedRadius: seedRadius) else {
            print("Not found.")
            return
        }
        
        print("Found a \(result.type) as a result:")
        print("\(result)")
        
    } catch {
        print("Couldn't run FindSurface due to the following error:")
        print(error)
    }
    
    print(" ")
}


extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: vector_float3) {
        let x: Float = value.x
        let y: Float = value.y
        let z: Float = value.z
        appendLiteral("[\(x), \(y), \(z)]")
    }
    
    mutating func appendInterpolation(_ value: Float) {
        appendLiteral(String(format: "%3f", value))
    }
    
    mutating func appendInterpolation(_ value: FindSurface.FeatureType) {
        switch value {
        case .any: appendLiteral("any")
        case .plane: appendLiteral("plane")
        case .sphere: appendLiteral("sphere")
        case .cylinder: appendLiteral("cylinder")
        case .cone: appendLiteral("cone")
        case .torus: appendLiteral("torus")
        @unknown default:
            fatalError()
        }
    }
    
    mutating func appendInterpolation(_ value: FindSurfaceResult) {
        switch value.type {
        case .plane: appendInterpolation(value.getAsPlaneResult()!.literal)
        case .sphere: appendInterpolation(value.getAsSphereResult()!.literal)
        case .cylinder: appendInterpolation(value.getAsCylinderResult()!.literal)
        case .cone: appendInterpolation(value.getAsConeResult()!.literal)
        case .torus: appendInterpolation(value.getAsTorusResult()!.literal)
        case .any: fallthrough
        @unknown default: break
        }
    }
    
}

protocol Stringifiable {
    var literal: String { get }
}

extension FindPlaneResult: Stringifiable {
    var literal: String {
        #"""
Plane (rms error: \#(rmsError))
    Lower Left: \#(lowerLeft)
    Lower Right: \#(lowerRight)
    Upper Right: \#(upperRight)
    Upper Left: \#(upperLeft)
"""#
    }
}

extension FindSphereResult: Stringifiable {
    var literal: String {
        #"""
Sphere (rms error: \#(rmsError))
    Center: \#(center)
    Radius: \#(radius)
"""#
    }
}

extension FindCylinderResult: Stringifiable {
    var literal: String {
        #"""
Cylinder (rms error: \#(rmsError))
    Bottom Center: \#(bottom)
    Top Center: \#(top)
    Radius: \#(radius)
"""#
    }
}

extension FindConeResult: Stringifiable {
    var literal: String {
        #"""
Cone (rms error: \#(rmsError))
    Bottom Center: \#(bottom)
    Top Center: \#(top)
    Bottom Radius: \#(bottomRadius)
    Top Center: \#(topRadius)
"""#
    }
}

extension FindTorusResult: Stringifiable {
    var literal: String {
        #"""
Torus (rms error: \#(rmsError))
    Center: \#(center)
    Axis: \#(normal)
    Mean Radius: \#(meanRadius)
    Tube Radius: \#(tubeRadius)
"""#
    }
}


#endif
