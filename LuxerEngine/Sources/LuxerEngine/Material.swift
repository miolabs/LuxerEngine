//
//  Material.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Metal

// This is the CPU-side material that can contain references
struct Material
{
    var baseColor: SIMD4<Float> = SIMD4<Float>(1, 1, 1, 1)
    var metallic: Float = 0.0
    var roughness: Float = 0.5
    var emissive: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var emissiveIntensity: Float = 0.0
    
    // Reference types - NOT sent to GPU
    var pipelineState: MTLRenderPipelineState?
    var baseColorTexture: MTLTexture?
    var normalTexture: MTLTexture?
    var metallicRoughnessTexture: MTLTexture?
    
    // Convert to shader-compatible data
    var shaderData: MaterialShaderData {
        return MaterialShaderData(
            baseColor: baseColor,
            metallic: metallic,
            roughness: roughness,
            emissive: SIMD4<Float>(emissive.x, emissive.y, emissive.z, emissiveIntensity)
        )
    }
}

// This struct contains only data that can be sent to the GPU
// Must match the Metal shader struct exactly
struct MaterialShaderData
{
    let baseColor: SIMD4<Float>      // 16 bytes
    let metallic: Float              // 4 bytes
    let roughness: Float             // 4 bytes
    let emissive: SIMD4<Float>       // 16 bytes (xyz = color, w = intensity)
    // Total: 40 bytes (will be padded to 48 bytes by Metal)
}

// If you have many materials, consider using a buffer instead
class MaterialBuffer {
    private let device: MTLDevice
    private var buffer: MTLBuffer?
    private var materials: [MaterialShaderData] = []
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func updateMaterials(_ materials: [Material]) {
        self.materials = materials.map { $0.shaderData }
        
        let bufferSize = materials.count * MemoryLayout<MaterialShaderData>.stride
        buffer = device.makeBuffer(bytes: self.materials, length: bufferSize, options: .storageModeShared)
    }
    
    func bindMaterial(at index: Int, to encoder: MTLRenderCommandEncoder) {
        guard let buffer = buffer else { return }
        let offset = index * MemoryLayout<MaterialShaderData>.stride
        encoder.setFragmentBuffer(buffer, offset: offset, index: 0)
    }
}

// MARK: - Material Creation Helper

extension Material {
    // Convenience initializers
    static func pbr(baseColor: SIMD4<Float>, metallic: Float = 0.0, roughness: Float = 0.5) -> Material {
        return Material(
            baseColor: baseColor,
            metallic: metallic,
            roughness: roughness,
            emissive: .zero,
            emissiveIntensity: 0.0
        )
    }
    
    static func emissive(color: SIMD3<Float>, intensity: Float = 1.0) -> Material {
        return Material(
            baseColor: SIMD4<Float>(0.1, 0.1, 0.1, 1.0),
            metallic: 0.0,
            roughness: 1.0,
            emissive: color,
            emissiveIntensity: intensity
        )
    }
}
