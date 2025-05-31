//
//  Transform.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Metal
import MetalKit
import simd

// MARK: - Core Types
struct Transform {
    var position: SIMD3<Float> = .zero
    var rotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    var scale: SIMD3<Float> = .one
    
    var modelMatrix: float4x4 {
        let T = float4x4(translation: position)
        let R = float4x4(rotation: rotation)
        let S = float4x4(scale: scale)
        return T * R * S
    }
}
