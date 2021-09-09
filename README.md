# FindSurface-BasicDemo-iOS (Swift)
**Curv*Surf* FindSurface™** BasicDemo for iOS (Swift)

## Overview
This sample source code demonstrates the basic usage of FindSurface for a simple task, which attempts to search for specific geometry shapes in point cloud data. 

[FindSurfaceFramework](https://github.com/CurvSurf/FindSurface-iOS) is required to build the source code into a program. Download the framework [here](https://github.com/CurvSurf/FindSurface-iOS/releases) and refer to [here](https://github.com/CurvSurf/FindSurface-iOS/blob/master/How-to-import-FindSurface-Framework-to-your-project.md) for an instruction about how to setup your project to build it with the framework.



## Using FindSurface APIs

Look at  `runFindSurfaceDemo` function of [FindSurfaceDemo.swift](src/FindSurfaceDemo.swift) file first, where FindSurface APIs are called. The source code in the function describes the following 4 steps:

### Obtaining FindSurface Context
````swift
let fsCtx = FindSurface.sharedInstance()
````
First of all, obtain the FindSurface context, which is a singleton instance, to call FindSurface APIs using this instance.

You can either use it once and then dump it as a single-use object because a static variable holds its strong reference inside of FindSurface class, or keep the reference in a static variable of your class for your convenience. Ever since the context is created once, it will not be released until the application is terminated (the internal storage for input point clouds can be released by explicitly calling `cleanUp` function if the input points are not used anymore).

### Setting Input point cloud and parameters
````swift
fsCtx.measurementAccuracy = measurementAccuracy
fsCtx.meanDistance = meanDistance
fsCtx.setPointCloudData(points,
												pointCount: points.count / 3,
                        pointStride: MemoryLayout<Float32>.stride * 3,
                        useDoublePrecision: false)
````
When an application is ready for an input point cloud, pass it to FindSurface along with parameters related to the points. Refer to [here](https://github.com/CurvSurf/FindSurface#how-does-it-work) for the meanings of the parameters.

### Invoking FindSurface algorithm
````swift
fileprivate func runTest(fsCtx: FindSurface, _ preset: Preset, seedRadius: Float) throws -> FindSurfaceResult? {
    
    do {
        guard let result = try fsCtx.findSurface(featureType: preset.featureType,
                                                 seedIndex: preset.seedIndex,
                                                 seedRadius: seedRadius) else {
            
            print("Not found.")
            return nil
        }
        
        return result
        
    } catch {
        print("Error: \(error)")
        return nil
    }
}

... 

// unwrap the result before using it.
guard let result = try? runTest(fsCtx: fsCtx, preset, seedRadius: seedRadius) else {
  continue
}
````

The parameters of  `findSurface` method are composed of `featureType`, `seedIndex`, and `seedRadius`. The `featureType` is an enum value of `FindSurface.FeatureType`, which can be one of the five geometric shapes (i.e., `plane`, `sphere`, `cylinder`, `cone`, `torus`) and `any`, which means "try finding one of the five". Refer to [here](https://github.com/CurvSurf/FindSurface#how-does-it-work) for the detailed descriptions of the parameters.

This method returns a result as an optional form of abstract type, such as Objective-C's `@interface`, which is also named `FindSurfaceResult` that every geometric surface types inherits. If the method fails to detect any geometric shape, the method returns `nil`.

FindSurface throws an `Error` if it fails to execute its algorithm for any reason (e.g., an invalid parameter value, lack of memory). `Error` is enumeration that describe a cause of the error. It is recommended to design your application defensively so that your application does not have to catch any error other than the "out of memory" case in run-time. Refer to [here](TBD) for the cases of when FindSurface throws an `Error`.

### Fetching the Result

````swift
// the `result` is the unwrapped instance of the `FindSurfaceResult`
let rms = result.rmsError
````

The `rmsError` property describes the root-mean-squared value of errors in orthogonal distance, which means distances in normal direction between inlier points and the surface model that FindSurface detects. The value describes how much the points fits the geometric model well and it is not related to the algorithm's accuracy. This value will get greater as the points have greater errors in measurement, which means the result also be affected by the errors.

````swift
// the `result` is the unwrapped instance of the `FindSurfaceResult`
switch result.type {
case .plane:
    let plane = result.getAsPlaneResult()!
        
case .sphere:
    let sphere = result.getAsSphereResult()!

case .cylinder:
    let cylinder = result.getAsCylinderResult()!
        
case .cone:
    let cone = result.getAsConeResult()!
        
case .torus:
    let torus = result.getAsTorusResult()!
        
default:
  	// should have not reached here. 
}    
````

The `type` property has a value of `FindSurface.FeatureType` and can be one of the five types. The type will be the same as the input parameter, except for several special cases (refer to [Auto Detection](https://github.com/CurvSurf/FindSurface#auto-detection) and [Smart Conversion](https://github.com/CurvSurf/FindSurface#smart-conversion)). Since the result type cannot be set to `any`, the `default` section will never be executed. 

> Note that the `result` was **unwrapped** in the code above. Otherwise, the `default` can be executed when it fails to detect, letting it fall through by the optional-chained  `nil`. 

The actual data can be accessed by either unwrapping the type as above or downcast the type with `if` statements as follows:

````swift
if let plane = result as? FindPlaneResult {
  	// do something with a plane
} 
else if let sphere = result as? FindSphereResult {
   	// do something with a sphere
}
...
````



## About point cloud

The point cloud in this demo is the same as the sample used in FindSurface WebDemo. Please refer to the [WebDemo](https://developers.curvsurf.com/WebDemo/) for a visual representation of FindSurface's results. 

