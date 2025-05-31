//
//  EngineSystem.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 31/5/25.
//

import Foundation

/// Protocol that all engine systems must implement
public protocol EngineSystem: AnyObject {
    /// Unique identifier for the system
    var id: String { get }
    
    /// Priority of the system (higher priority systems are initialized first)
    var priority: Int { get }
    
    /// Dependencies on other systems
    var dependencies: [String] { get }
    
    /// Whether the system is enabled
    var isEnabled: Bool { get set }
    
    /// Initialize the system
    func initialize()
    
    /// Update the system with the given delta time
    func update(deltaTime: TimeInterval)
    
    /// Shutdown the system and release resources
    func shutdown()
}

/// Default implementations for EngineSystem
public extension EngineSystem {
    var priority: Int { return 0 }
    var dependencies: [String] { return [] }
}

/// Registry for managing engine systems
public class EngineSystemRegistry {
    /// Singleton instance
    public static let shared = EngineSystemRegistry()
    
    /// Registered systems
    private var systems: [String: EngineSystem] = [:]
    
    /// Initialized systems
    private var initializedSystems: [String] = []
    
    /// Private initializer for singleton
    private init() {}
    
    /// Register a system with the registry
    public func register<T: EngineSystem>(_ system: T) {
        systems[system.id] = system
    }
    
    /// Get a system by type
    public func getSystem<T: EngineSystem>(_ type: T.Type) -> T? {
        for system in systems.values {
            if let typedSystem = system as? T {
                return typedSystem
            }
        }
        return nil
    }
    
    /// Get a system by ID
    public func getSystem(id: String) -> EngineSystem? {
        return systems[id]
    }
    
    /// Initialize all registered systems in dependency order
    public func initializeAll() {
        // Sort systems by priority and dependencies
        let sortedSystems = sortSystemsByDependencies()
        
        // Initialize each system
        for system in sortedSystems {
            if system.isEnabled && !initializedSystems.contains(system.id) {
                system.initialize()
                initializedSystems.append(system.id)
            }
        }
    }
    
    /// Update all initialized systems
    public func updateAll(deltaTime: TimeInterval) {
        for systemId in initializedSystems {
            if let system = systems[systemId], system.isEnabled {
                system.update(deltaTime: deltaTime)
            }
        }
    }
    
    /// Shutdown all initialized systems in reverse order
    public func shutdownAll() {
        for systemId in initializedSystems.reversed() {
            if let system = systems[systemId] {
                system.shutdown()
            }
        }
        initializedSystems.removeAll()
    }
    
    /// Sort systems by dependencies and priority
    private func sortSystemsByDependencies() -> [EngineSystem] {
        var result: [EngineSystem] = []
        var visited: Set<String> = []
        
        // Helper function for topological sort
        func visit(_ systemId: String) {
            if visited.contains(systemId) { return }
            
            guard let system = systems[systemId] else { return }
            
            visited.insert(systemId)
            
            // Visit dependencies first
            for dependencyId in system.dependencies {
                visit(dependencyId)
            }
            
            result.append(system)
        }
        
        // Get all systems sorted by priority (higher priority first)
        let sortedIds = systems.keys.sorted { 
            (systems[$0]?.priority ?? 0) > (systems[$1]?.priority ?? 0)
        }
        
        // Visit each system
        for systemId in sortedIds {
            visit(systemId)
        }
        
        return result
    }
    
    /// Remove all systems
    public func clear() {
        shutdownAll()
        systems.removeAll()
    }
}

/// Base class for engine systems with common functionality
open class BaseEngineSystem: EngineSystem {
    public let id: String
    public var isEnabled: Bool = true
    
    public init(id: String) {
        self.id = id
    }
    
    open func initialize() {
        // Default implementation does nothing
    }
    
    open func update(deltaTime: TimeInterval) {
        // Default implementation does nothing
    }
    
    open func shutdown() {
        // Default implementation does nothing
    }
}
