//
//  MetalRender.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Foundation
import Metal
import simd
import MetalKit

// MARK: - Render Engine
class MetalRender
{
    // Metal Core
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var library: MTLLibrary?
    
    // Render Components
    private var renderNodes: [UUID: RenderNode] = [:]
    private var visibleNodes: [RenderNode] = []
    private let camera = CameraNode()
    private let frameRateController = FrameRateController()
    private let stateMachine = RenderStateMachine()
    
    // Render Settings
    var enableFrustumCulling = true
    var enableOcclusionCulling = false
    var enableLOD = true
    var maxRenderDistance: Float = 500.0
    
    // Statistics
    private(set) var statistics = RenderStatistics()
    
    struct RenderStatistics
    {
        var totalNodes: Int = 0
        var visibleNodes: Int = 0
        var culledNodes: Int = 0
        var trianglesRendered: Int = 0
        var drawCalls: Int = 0
        var currentLODDistribution: [LODLevel: Int] = [:]
    }
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
//        super.init()
        
        setupMetal()
    }
    
    private func setupMetal() {
        // Load default shaders
        let source = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct VertexIn {
            float3 position [[attribute(0)]];
            float3 normal [[attribute(1)]];
            float2 texCoord [[attribute(2)]];
        };
        
        struct VertexOut {
            float4 position [[position]];
            float3 worldNormal;
            float3 worldPosition;
            float2 texCoord;
        };
        
        struct Uniforms {
            float4x4 modelMatrix;
            float4x4 viewProjectionMatrix;
            float4x4 normalMatrix;
        };
        
        vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                                     constant Uniforms &uniforms [[buffer(1)]]) {
            VertexOut out;
            float4 worldPosition = uniforms.modelMatrix * float4(in.position, 1.0);
            out.position = uniforms.viewProjectionMatrix * worldPosition;
            out.worldPosition = worldPosition.xyz;
            out.worldNormal = (uniforms.normalMatrix * float4(in.normal, 0.0)).xyz;
            out.texCoord = in.texCoord;
            return out;
        }
        
        fragment float4 fragment_main(VertexOut in [[stage_in]],
                                     constant Material &material [[buffer(0)]]) {
            float3 normal = normalize(in.worldNormal);
            float3 lightDir = normalize(float3(1, 1, 1));
            float NdotL = max(dot(normal, lightDir), 0.0);
            float3 diffuse = material.baseColor.rgb * NdotL;
            return float4(diffuse, material.baseColor.a);
        }
        """
        
        do {
            library = try device.makeLibrary(source: source, options: nil)
        } catch {
            print("Failed to create shader library: \(error)")
        }
    }
    
    // MARK: - Object Management
    func addNode(_ node: RenderNode) {
        renderNodes[node.id] = node
        statistics.totalNodes = renderNodes.count
    }
    
    func removeNode(id: UUID) {
        renderNodes.removeValue(forKey: id)
        statistics.totalNodes = renderNodes.count
    }
    
    func updateCamera(position: SIMD3<Float>, target: SIMD3<Float>) {
        camera.position = position
        camera.target = target
    }
    
    // MARK: - Culling
    private func performFrustumCulling() {
        // Simplified frustum culling using bounding spheres
        let frustum = extractFrustumPlanes(from: camera.viewProjectionMatrix)
        
        visibleNodes = renderNodes.values.filter { object in
            guard object.isVisible else { return false }
            
            // Distance culling
            let distance = object.distanceToCamera(camera.position)
            if distance > maxRenderDistance { return false }
            
            // Frustum culling
            if enableFrustumCulling {
                return isSphereInFrustum(center: object.transform.position,
                                       radius: object.boundingSphere,
                                       frustum: frustum)
            }
            
            return true
        }
        
        statistics.visibleNodes = visibleNodes.count
        statistics.culledNodes = statistics.totalNodes - statistics.visibleNodes
    }
    
    private func extractFrustumPlanes(from matrix: float4x4) -> [SIMD4<Float>] {
        // Extract 6 frustum planes from view-projection matrix
        var planes: [SIMD4<Float>] = []
        
        // Left, Right, Bottom, Top, Near, Far
        planes.append(matrix[3] + matrix[0])
        planes.append(matrix[3] - matrix[0])
        planes.append(matrix[3] + matrix[1])
        planes.append(matrix[3] - matrix[1])
        planes.append(matrix[3] + matrix[2])
        planes.append(matrix[3] - matrix[2])
        
        return planes.map { normalize($0) }
    }
    
    private func isSphereInFrustum(center: SIMD3<Float>, radius: Float, frustum: [SIMD4<Float>]) -> Bool {
        for plane in frustum {
            let distance = dot(SIMD4<Float>(center, 1.0), plane)
            if distance < -radius {
                return false
            }
        }
        return true
    }
    
    private func normalize(_ plane: SIMD4<Float>) -> SIMD4<Float> {
        let length = sqrt(plane.x * plane.x + plane.y * plane.y + plane.z * plane.z)
        return plane / length
    }
    
    // MARK: - Sorting
    private func sortVisibleObjects() {
        // Sort by material/pipeline state to reduce state changes
        // Then by distance for transparent objects
        visibleNodes.sort { a, b in
            if a.material.pipelineState === b.material.pipelineState {
                return a.distanceToCamera(camera.position) < b.distanceToCamera(camera.position)
            }
            return false
        }
    }
    
    // MARK: - Main Render Loop
    @MainActor
    func render(in view: MTKView, currentTime: TimeInterval) {
        guard frameRateController.shouldRenderFrame(currentTime: currentTime) else { return }
        
        stateMachine.transition(to: .preparing, at: currentTime)
        
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        camera.aspectRatio = Float(view.bounds.width / view.bounds.height)
        
        // Culling Phase
        stateMachine.transition(to: .culling, at: CACurrentMediaTime())
        performFrustumCulling()
        
        // Sorting Phase
        stateMachine.transition(to: .sorting, at: CACurrentMediaTime())
        sortVisibleObjects()
        
        // Rendering Phase
        stateMachine.transition(to: .rendering, at: CACurrentMediaTime())
        
        statistics.trianglesRendered = 0
        statistics.drawCalls = 0
        statistics.currentLODDistribution.removeAll()
        
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderVisibleObjects(using: renderEncoder)
            renderEncoder.endEncoding()
        }
        
        // Present Phase
        stateMachine.transition(to: .presenting, at: CACurrentMediaTime())
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        frameRateController.updateFrameTiming(currentTime: currentTime)
        stateMachine.transition(to: .idle, at: CACurrentMediaTime())
    }
    
    private func renderVisibleObjects(using encoder: MTLRenderCommandEncoder) {
        var currentPipeline: MTLRenderPipelineState?
        
        for node in visibleNodes {
            // LOD Selection
            let distance = node.distanceToCamera(camera.position)
            guard let mesh = node.mesh(forDistance: distance) else { continue }
            
//            statistics.currentLODDistribution[lodLevel, default: 0] += 1
            
            // Pipeline State Change
            if let pipeline = node.material.pipelineState, pipeline !== currentPipeline {
                encoder.setRenderPipelineState(pipeline)
                currentPipeline = pipeline
            }
            
            // Set Uniforms
            var uniforms = Uniforms(
                modelMatrix: node.transform.modelMatrix,
                viewProjectionMatrix: camera.viewProjectionMatrix,
                normalMatrix: node.transform.modelMatrix.inverse.transpose
            )
            
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)

            // Set Material Data (convert to shader-compatible format)
            var materialData = node.material.shaderData
            encoder.setFragmentBytes(&materialData, length: MemoryLayout<MaterialShaderData>.size, index: 0)
            
            // Set Textures if available
            if let baseColorTexture = node.material.baseColorTexture {
                encoder.setFragmentTexture(baseColorTexture, index: 0)
            }
            if let normalTexture = node.material.normalTexture {
                encoder.setFragmentTexture(normalTexture, index: 1)
            }
            if let metallicRoughnessTexture = node.material.metallicRoughnessTexture {
                encoder.setFragmentTexture(metallicRoughnessTexture, index: 2)
            }
            
            // Draw
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: mesh.indexCount,
                indexType: .uint32,
                indexBuffer: mesh.indexBuffer,
                indexBufferOffset: 0
            )
            
            statistics.drawCalls += 1
            statistics.trianglesRendered += mesh.indexCount / 3
        }
    }
    
    // MARK: - Public API
    func setTargetFPS(_ fps: Int) {
        frameRateController.setTargetFPS(fps)
    }
    
    func getCurrentFPS() -> Double {
        return frameRateController.fps
    }
    
    func getRenderStatistics() -> RenderStatistics {
        return statistics
    }
    
    func getStateTimings() -> [RenderState: TimeInterval] {
        return stateMachine.getStateTimings()
    }
}
