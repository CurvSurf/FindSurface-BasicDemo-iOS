//
//  ContentView.swift
//  FindSurface-BasicDemo-iOS
//
//  Created by CurvSurf-SGKim on 2/10/25.
//

import SwiftUI
import simd
import Foundation

import FindSurface_iOS

fileprivate let kSphereIndex = 7811
fileprivate let kCylinderIndex = 3437
fileprivate let kConeIndex = 6637
fileprivate let kTorusIndex = 7384

struct Preset {
    let featureType: FeatureType
    let seedIndex: Int
}

fileprivate let normalPresetList: [Preset] = [
    .init(featureType: .sphere, seedIndex: kSphereIndex),
    .init(featureType: .cylinder, seedIndex: kCylinderIndex),
    .init(featureType: .cone, seedIndex: kConeIndex),
    .init(featureType: .torus, seedIndex: kTorusIndex)
]

fileprivate let smartPresetList: [Preset] = [
    .init(featureType: .cone, seedIndex: kCylinderIndex),
    .init(featureType: .torus, seedIndex: kSphereIndex),
    .init(featureType: .torus, seedIndex: kCylinderIndex),
]

struct LabelParameter: Identifiable {
    var id: UUID = .init()
    
    var text: String
    var imageName: String
    
    var label: some View {
        Label(text, systemImage: imageName)
            .labelStyle(.titleAndIcon)
            .font(.caption)
    }
}

struct ContentView: View {
    
    @State private var isRunning: Bool = false
    @State private var resultLabelsForNormalPresets: [LabelParameter] = []
    @State private var resultLabelsForSmartPresets: [LabelParameter] = []
    
    private let points: [simd_float3]
    
    init() {
        FindSurface.instance.measurementAccuracy = 0.01
        FindSurface.instance.meanDistance = 0.05
        FindSurface.instance.seedRadius = 0.08
        FindSurface.instance.radialExpansion = .lv5
        FindSurface.instance.lateralExtension = .lv10
        
        self.points = (0..<kPoints.count / 3).map {
            let x = Float(kPoints[$0 * 3])
            let y = Float(kPoints[$0 * 3 + 1])
            let z = Float(kPoints[$0 * 3 + 2])
            return simd_float3(x, y, z)
        }
        
        FindSurface.instance.targetFeature = .plane
//        Task {
//            do {
//                let result = try await FindSurface.instance.perform {
//                    let points = (0...10000).map { _ in
//                        let radius = Float.random(in: 0...1)
//                        let error = Float.random(in: (-1)...1) * 0.01
//                        let theta = Float.random(in: 0...(2 * Float.pi))
//                        
//                        let cosTheta = cos(theta)
//                        let sinTheta = sin(theta)
//                        let x = radius * cosTheta
//                        let z = radius * sinTheta
//                        let y = error
//                        
//                        return simd_float3(x, y, z)
//                    }
//                    return (points, Int.random(in: points.indices))
//                }
//                guard let result else { return }
//                print(generateResultText(result, 0))
//            } catch {
//                print("error: \(error)")
//            }
//        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom) {
                Label {
                    Text("FindSurface Basic Demo")
                        .font(.title)
                } icon: {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 32,
                               height: 32)
                }.labelStyle(.titleAndIcon)
            }
            
            ScrollView {
                
                VStack(alignment: .leading) {
                    Text("The input point cloud (\(points.count) pts.) of this app looks like as follows: ")
                        .font(.subheadline)
                    
                    Image("sample_pc")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    Text("This app detects geometry surfaces at preset locations in the given point cloud.")
                        .font(.subheadline)
                        .padding(.bottom)
                    
                    Spacer()
                    
                    if resultLabelsForNormalPresets.isEmpty == false {
                        Text("Normal Presets: ")
                        ForEach(resultLabelsForNormalPresets) { resultLabel in
                            resultLabel.label
                        }
                    }
                    
                    if resultLabelsForSmartPresets.isEmpty == false {
                        Text("Smart Conversion Presets: ")
                        ForEach(resultLabelsForSmartPresets) { resultLabel in
                            resultLabel.label
                        }
                    }
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            resultLabelsForNormalPresets = []
                            resultLabelsForSmartPresets = []
                            Task {
                                await runPresets()
                            }
                        } label: {
                            Text(isRunning ? "Running..." : "Run FindSurface")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isRunning)
                        .padding(.top)
                        
                        Spacer()
                    }
                    
                    if resultLabelsForSmartPresets.isEmpty == false || resultLabelsForNormalPresets.isEmpty == false {
                        Text("Visit our web-demo for visualization of the results (recommend to open in a desktop). https://developers.curvsurf.com/WebDemo")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(16)
    }
    
    private func runPresets() async {
        isRunning = true
        FindSurface.instance.conversionOptions = []
        for preset in normalPresetList {
            let resultLabel = await run(preset)
            resultLabelsForNormalPresets.append(resultLabel)
        }
        
        FindSurface.instance.conversionOptions = [.coneToCylinder, .torusToCylinder, .torusToSphere]
        for preset in smartPresetList {
            let resultLabel = await run(preset)
            resultLabelsForSmartPresets.append(resultLabel)
        }
        isRunning = false
    }
    
    private func run(_ preset: Preset) async -> LabelParameter {
        
        let featureType = preset.featureType
        let seedIndex = preset.seedIndex
        
        FindSurface.instance.targetFeature = featureType
        
        do {
            let t0 = DispatchTime.now().uptimeNanoseconds
            let result = try await FindSurface.instance.perform {
                return (points, seedIndex)
            }
            let t1 = DispatchTime.now().uptimeNanoseconds
            guard let result else {
                fatalError("`result == nil` means somehow you invoked the `perform` method while it is working. FindSurface does not support concurrency currently.")
            }
            
            let dt = Double(t1 - t0) / 1_000_000
            return generateResultText(result, dt)
            
        } catch {
            guard let error = error as? FindSurface.Failure else { return .init(text: "unknown error", imageName: "exclamationmark.triangle") }
            switch error {
            case .memoryAllocationFailure:
                return .init(text: "memory allocation failed", imageName: "exclamationmark.triangle")
            case .invalidArgument(let reason):
                return .init(text: "invalid argument: \(reason)", imageName: "exclamationmark.triangle")
            case .invalidOperation(let reason):
                return .init(text: "invalid operation: \(reason)", imageName: "exclamationmark.triangle")
            }
        }
    }
}

fileprivate func generateResultText(_ result: FindSurface.Result, _ timeElapsedMS: Double) -> LabelParameter {
    let dt = String(format: "%.2f ms", timeElapsedMS)
    switch result {
    case let .foundPlane(plane, _, rms):
        let width = String(format: "%.2f cm", plane.width * 100)
        let height = String(format: "%.2f cm", plane.height * 100)
        let rms = String(format: "%.2f cm", rms * 100)
        return .init(text: "Plane(w: \(width), h: \(height), rms: \(rms), \(dt))", imageName: "square")
        
    case let .foundSphere(sphere, _, rms):
        let radius = String(format: "%.2f cm", sphere.radius * 100)
        let rms = String(format: "%.2f cm", rms * 100)
        return .init(text: "Sphere(r: \(radius), rms: \(rms), \(dt))", imageName: "basketball")
        
    case let .foundCylinder(cylinder, _, rms):
        let radius = String(format: "%.2f cm", cylinder.radius * 100)
        let height = String(format: "%.2f cm", cylinder.height * 100)
        let rms = String(format: "%.2f cm", rms * 100)
        return .init(text: "Cylinder(r: \(radius), h: \(height), rms: \(rms), \(dt))", imageName: "cylinder")
        
    case let .foundCone(cone, _, rms):
        let topRadius = String(format: "%.2f cm", cone.topRadius * 100)
        let bottomRadius = String(format: "%.2f cm", cone.bottomRadius * 100)
        let height = String(format: "%.2f cm", cone.height * 100)
        let rms = String(format: "%.2f cm", rms * 100)
        return .init(text: "Cone(tr: \(topRadius), br: \(bottomRadius), h: \(height), rms: \(rms), \(dt))", imageName: "cone")
        
    case let .foundTorus(torus, _, rms):
        let radius1 = String(format: "%.2f cm", torus.meanRadius * 100)
        let radius2 = String(format: "%.2f cm", torus.tubeRadius * 100)
        let rms = String(format: "%.2f cm", rms * 100)
        return .init(text: "Torus(r1: \(radius1), r2: \(radius2), rms: \(rms), \(dt))", imageName: "torus")
        
    case .none(_):
        return .init(text: "None", imageName: "xmark")
    }
}

#Preview {
    ContentView()
}
