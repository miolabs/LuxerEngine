//
//  Camera.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import simd

// MARK: - Camera
open class CameraNode : Node
{    
    var target: SIMD3<Float> = .zero
    var up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    var fov: Float = 60.0
    var near: Float = 0.1
    var far: Float = 1000.0
    var aspectRatio: Float = 1.0
    
    var viewMatrix: float4x4 {
        return float4x4(lookAt: position, target: target, up: up)
    }
    
    var projectionMatrix: float4x4 {
        return float4x4(perspectiveProjectionFov: fov.degreesToRadians,
                       aspectRatio: aspectRatio,
                       nearZ: near,
                       farZ: far)
    }
    
    var viewProjectionMatrix: float4x4 {
        return projectionMatrix * viewMatrix
    }
}
