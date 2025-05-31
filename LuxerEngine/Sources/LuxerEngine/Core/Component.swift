//
//  Component.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 31/5/25.
//

import Foundation
import simd

/// Protocol that all components must implement
public protocol Component: AnyObject {
    /// The node that owns this component
    var owner: Node? { get set }
    
    /// Unique identifier for the component
    var id: UUID { get }
    
    /// Whether the component is enabled
    var isEnabled: Bool { get set }
    
    /// Called when the component is added to a node
    func onAttach()
    
    /// Called when the component is removed from a node
    func onDetach()
    
    /// Called once per frame to update the component
    func update(deltaTime: TimeInterval)
}

/// Default implementations for Component
public extension Component {
    var id: UUID { UUID() }
}

/// Base class for components with common functionality
open class BaseComponent: Component {
    public weak var owner: Node?
    public var isEnabled: Bool = true
    public let id: UUID = UUID()
    
    public init() {}
    
    open func onAttach() {
        // Default implementation does nothing
    }
    
    open func onDetach() {
        // Default implementation does nothing
    }
    
    open func update(deltaTime: TimeInterval) {
        // Default implementation does nothing
    }
}

/// Protocol extension for Node to support components
public extension Node {
    /// Add a component to the node
    @discardableResult
    func addComponent<T: Component>(_ component: T) -> T {
        guard component.owner == nil else {
            print("Warning: Component already has an owner")
            return component
        }
        
        // Set owner
        component.owner = self
        
        // Store by ID
        components[component.id] = component
        
        // Store by type for faster lookup
        let typeName = String(describing: type(of: component))
        var componentsOfType = componentsByType[typeName] ?? []
        componentsOfType.append(component)
        componentsByType[typeName] = componentsOfType
        
        // Notify component
        component.onAttach()
        
        return component
    }
    
    /// Get the first component of the specified type
    func getComponent<T: Component>(ofType type: T.Type) -> T? {
        let typeName = String(describing: type)
        return componentsByType[typeName]?.first as? T
    }
    
    /// Get all components of the specified type
    func getComponents<T: Component>(ofType type: T.Type) -> [T] {
        let typeName = String(describing: type)
        return (componentsByType[typeName] as? [T]) ?? []
    }
    
    /// Remove a component from the node by type
    @discardableResult
    func removeComponent<T: Component>(ofType type: T.Type) -> Bool {
        guard let component = getComponent(ofType: type) else {
            return false
        }
        
        return removeComponent(component)
    }
    
    /// Remove a specific component from the node
    @discardableResult
    func removeComponent(_ component: Component) -> Bool {
        guard let storedComponent = components[component.id], storedComponent === component else {
            return false
        }
        
        // Remove from ID map
        components.removeValue(forKey: component.id)
        
        // Remove from type map
        let typeName = String(describing: type(of: component))
        if var componentsOfType = componentsByType[typeName] {
            componentsOfType.removeAll { $0 === component }
            
            if componentsOfType.isEmpty {
                componentsByType.removeValue(forKey: typeName)
            } else {
                componentsByType[typeName] = componentsOfType
            }
        }
        
        // Notify component
        component.onDetach()
        component.owner = nil
        
        return true
    }
    
    /// Check if the node has a component of the specified type
    func hasComponent<T: Component>(ofType type: T.Type) -> Bool {
        let typeName = String(describing: type)
        return (componentsByType[typeName]?.isEmpty == false)
    }
    
    /// Update all components
    func updateComponents(deltaTime: TimeInterval) {
        for component in components.values {
            if component.isEnabled {
                component.update(deltaTime: deltaTime)
            }
        }
    }
}

/// Common component types that can be used with nodes
public enum ComponentType {
    case transform
    case renderer
    case physics
    case audio
    case animation
    case script
    case custom(String)
}

/// Transform component for handling position, rotation, and scale
public class TransformComponent: BaseComponent {
    public var localPosition: SIMD3<Float> = .zero
    public var localRotation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
    public var localScale: SIMD3<Float> = .one
    
    private var _worldTransform: Transform?
    
    /// The world transform, calculated based on parent transforms
    public var worldTransform: Transform {
        if let cached = _worldTransform {
            return cached
        }
        
        // Calculate world transform based on parent
        let transform = Transform(
            position: localPosition,
            rotation: localRotation,
            scale: localScale
        )
        
        // Cache the result
        _worldTransform = transform
        return transform
    }
    
    /// Invalidate the cached world transform
    public func invalidateTransform() {
        _worldTransform = nil
    }
    
    public override func update(deltaTime: TimeInterval) {
        // Update transform if needed
    }
}
