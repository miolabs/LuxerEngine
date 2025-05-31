//
//  RenderEngine.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 31/5/25.
//

import Foundation
import simd

/// Supported rendering APIs
public enum RenderAPI {
    case metal
    case openGL
    case vulkan
    case directX
    case none // For headless operation (e.g., scripting, simulation)
    
    /// Returns the default API for the current platform
    public static var defaultForPlatform: RenderAPI {
        #if os(iOS) || os(macOS) || os(visionOS)
        return .metal
        #elseif os(Linux)
        return .vulkan
        #elseif os(Windows)
        return .directX
        #else
        return .openGL
        #endif
    }
}

/// Configuration options for the render engine
public struct RenderEngineConfiguration {
    /// The rendering API to use
    public var api: RenderAPI = .defaultForPlatform
    
    /// Whether to enable frustum culling
    public var enableFrustumCulling: Bool = true
    
    /// Whether to enable occlusion culling
    public var enableOcclusionCulling: Bool = false
    
    /// Whether to enable level of detail (LOD) system
    public var enableLOD: Bool = true
    
    /// Maximum render distance
    public var maxRenderDistance: Float = 500.0
    
    /// Target frames per second
    public var targetFPS: Int = 60
    
    /// Whether to enable debug visualization
    public var debugVisualization: Bool = false
    
    /// Whether to enable wireframe mode
    public var wireframeMode: Bool = false
    
    /// Background clear color
    public var clearColor: SIMD4<Float> = SIMD4<Float>(0.1, 0.1, 0.1, 1.0)
    
    /// Sample count for multisampling anti-aliasing (MSAA)
    public var sampleCount: Int = 1
    
    /// Custom shader path
    public var customShaderPath: String?
    
    /// Initialize with default values
    public init() {}
    
    /// Initialize with a specific API
    public init(api: RenderAPI = .defaultForPlatform) {
        self.api = api
    }
    
    /// Initialize with custom settings
    public init(
        api: RenderAPI = .defaultForPlatform,
        enableFrustumCulling: Bool = true,
        enableOcclusionCulling: Bool = false,
        enableLOD: Bool = true,
        maxRenderDistance: Float = 500.0,
        targetFPS: Int = 60,
        debugVisualization: Bool = false,
        wireframeMode: Bool = false,
        clearColor: SIMD4<Float> = SIMD4<Float>(0.1, 0.1, 0.1, 1.0),
        sampleCount: Int = 1,
        customShaderPath: String? = nil
    ) {
        self.api = api
        self.enableFrustumCulling = enableFrustumCulling
        self.enableOcclusionCulling = enableOcclusionCulling
        self.enableLOD = enableLOD
        self.maxRenderDistance = maxRenderDistance
        self.targetFPS = targetFPS
        self.debugVisualization = debugVisualization
        self.wireframeMode = wireframeMode
        self.clearColor = clearColor
        self.sampleCount = sampleCount
        self.customShaderPath = customShaderPath
    }
}

/// Statistics about the rendering process
public struct RenderStatistics {
    /// Total number of nodes in the scene
    public var totalNodes: Int = 0
    
    /// Number of nodes visible after culling
    public var visibleNodes: Int = 0
    
    /// Number of nodes culled (not visible)
    public var culledNodes: Int = 0
    
    /// Number of triangles rendered
    public var trianglesRendered: Int = 0
    
    /// Number of draw calls
    public var drawCalls: Int = 0
    
    /// Distribution of LOD levels
    public var currentLODDistribution: [LODLevel: Int] = [:]
    
    /// Time taken to render the frame
    public var frameTime: TimeInterval = 0
    
    /// Current frames per second
    public var fps: Double = 0
    
    /// GPU memory usage in bytes
    public var gpuMemoryUsage: Int = 0
    
    /// CPU memory usage in bytes
    public var cpuMemoryUsage: Int = 0
    
    /// Time spent in each render state
    public var stateTimings: [RenderState: TimeInterval] = [:]
}

/// Render states for the render state machine
public enum RenderState {
    case idle
    case preparing
    case culling
    case sorting
    case rendering
    case postProcessing
    case presenting
}

/// Protocol for objects that can be rendered
public protocol Renderable: AnyObject {
    /// Get the mesh for the given distance from camera
    func mesh(forDistance distance: Float) -> MeshProtocol?
    
    /// Get the material for rendering
    var material: Material { get }
    
    /// Get the transform for positioning
    var transform: Transform { get }
    
    /// Get the unique identifier
    var id: UUID { get }
}

/// Core protocol for render engines
public protocol RenderEngine: AnyObject {
    /// The render device used by this engine
    var device: RenderDevice? { get }
    
    /// The command queue used for rendering
    var commandQueue: CommandQueue? { get }
    
    /// The configuration for this render engine
    var configuration: RenderEngineConfiguration { get }
    
    /// Initialize the render engine with the given configuration
    init?(configuration: RenderEngineConfiguration)
    
    /// Add a node to the render engine
    func addNode(_ node: Renderable)
    
    /// Remove a node from the render engine
    func removeNode(id: UUID)
    
    /// Update the camera position and target
    func updateCamera(position: SIMD3<Float>, target: SIMD3<Float>)
    
    /// Render the current scene to the provided view
    func render(in view: RenderView, currentTime: TimeInterval)
    
    /// Set the target frames per second
    func setTargetFPS(_ fps: Int)
    
    /// Get the current frames per second
    func getCurrentFPS() -> Double
    
    /// Get the current render statistics
    func getRenderStatistics() -> RenderStatistics
    
    /// Get the timings for each render state
    func getStateTimings() -> [RenderState: TimeInterval]
    
    /// Create a texture from image data
    func createTexture(width: Int, height: Int, pixelFormat: Graphics.PixelFormat, data: UnsafeRawPointer?) -> RenderTexture?
    
    /// Create a mesh from vertex and index data
    func createMesh(vertices: UnsafeRawPointer, vertexCount: Int, vertexStride: Int, 
                    indices: UnsafeRawPointer, indexCount: Int, 
                    vertexDescriptor: VertexDescriptor) -> MeshProtocol?
    
    /// Create a material with the given properties
    func createMaterial(baseColor: SIMD4<Float>, metallic: Float, roughness: Float) -> Material
    
    /// Create a render pipeline state
    func createRenderPipeline(descriptor: RenderPipelineDescriptor) -> RenderPipelineState?
    
    /// Take a screenshot of the current frame
    func captureScreenshot() -> Data?
    
    /// Resize the rendering surface
    func resize(width: Int, height: Int)
    
    /// Clean up resources
    func cleanup()
}

/// Default implementations for RenderEngine
public extension RenderEngine {
    func setTargetFPS(_ fps: Int) {
        // Default implementation does nothing
    }
    
    func captureScreenshot() -> Data? {
        // Default implementation returns nil
        return nil
    }
    
    func resize(width: Int, height: Int) {
        // Default implementation does nothing
    }
    
    func cleanup() {
        // Default implementation does nothing
    }
}

/// Factory for creating render engines
public class RenderEngineFactory {
    /// Registry of render engine creators
    private static var engineCreators: [RenderAPI: (RenderEngineConfiguration) -> RenderEngine?] = [:]
    
    /// Register a render engine creator for a specific API
    public static func registerEngineCreator(for api: RenderAPI, creator: @escaping (RenderEngineConfiguration) -> RenderEngine?) {
        engineCreators[api] = creator
    }
    
    /// Create a render engine with the specified configuration
    public static func createEngine(configuration: RenderEngineConfiguration = RenderEngineConfiguration()) -> RenderEngine? {
        // Check if we have a registered creator for this API
        if let creator = engineCreators[configuration.api] {
            return creator(configuration)
        }
        
        // No creator registered for this API
        print("No render engine registered for API: \(configuration.api)")
        
        // If headless mode is requested, return a headless engine
        if configuration.api == .none {
            return HeadlessRenderEngine(configuration: configuration)
        }
        
        return nil
    }
}

/// A headless render engine that performs no actual rendering
/// Useful for scripting, testing, or server-side applications
private class HeadlessRenderEngine: RenderEngine {
    var device: RenderDevice? = nil
    var commandQueue: CommandQueue? = nil
    let configuration: RenderEngineConfiguration
    private var statistics = RenderStatistics()
    private var nodes: [UUID: Renderable] = [:]
    
    required init?(configuration: RenderEngineConfiguration) {
        self.configuration = configuration
    }
    
    func addNode(_ node: Renderable) {
        nodes[node.id] = node
        statistics.totalNodes = nodes.count
    }
    
    func removeNode(id: UUID) {
        nodes.removeValue(forKey: id)
        statistics.totalNodes = nodes.count
    }
    
    func updateCamera(position: SIMD3<Float>, target: SIMD3<Float>) {
        // No-op in headless mode
    }
    
    func render(in view: RenderView, currentTime: TimeInterval) {
        // No-op in headless mode
    }
    
    func getCurrentFPS() -> Double {
        return 0
    }
    
    func getRenderStatistics() -> RenderStatistics {
        return statistics
    }
    
    func getStateTimings() -> [RenderState: TimeInterval] {
        return [:]
    }
    
    func createTexture(width: Int, height: Int, pixelFormat: Graphics.PixelFormat, data: UnsafeRawPointer?) -> RenderTexture? {
        return nil
    }
    
    func createMesh(vertices: UnsafeRawPointer, vertexCount: Int, vertexStride: Int, 
                    indices: UnsafeRawPointer, indexCount: Int, 
                    vertexDescriptor: VertexDescriptor) -> MeshProtocol? {
        return nil
    }
    
    func createMaterial(baseColor: SIMD4<Float>, metallic: Float, roughness: Float) -> Material {
        return Material(baseColor: baseColor, metallic: metallic, roughness: roughness)
    }
    
    func createRenderPipeline(descriptor: RenderPipelineDescriptor) -> RenderPipelineState? {
        return nil
    }
}
