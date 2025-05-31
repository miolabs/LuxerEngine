//
//  Node.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 31/5/25.
//

import Foundation
import simd

/// Base class for all nodes in the scene graph
open class Node {
    // MARK: - Properties
    
    /// Unique identifier for the node
    public let id: UUID = UUID()
    
    /// Name of the node (for debugging and scene management)
    public var name: String
    
    /// Whether the node is active in the scene
    public var isActive: Bool = true
    
    /// Components attached to this node
    internal var components: [UUID: Component] = [:]
    
    /// Component lookup by type for faster access
    internal var componentsByType: [String: [Component]] = [:]
    
    /// Parent node (nil if this is a root node)
    public private(set) weak var parent: Node?
    
    /// Child nodes
    public private(set) var children: [Node] = []
    
    /// Transform component for this node
    public private(set) lazy var transformComponent: TransformComponent = {
        let component = TransformComponent()
        addComponent(component)
        return component
    }()
    
    /// Shorthand for position
    public var position: SIMD3<Float> {
        get { transformComponent.localPosition }
        set { transformComponent.localPosition = newValue }
    }
    
    /// Shorthand for rotation
    public var rotation: simd_quatf {
        get { transformComponent.localRotation }
        set { transformComponent.localRotation = newValue }
    }
    
    /// Shorthand for scale
    public var scale: SIMD3<Float> {
        get { transformComponent.localScale }
        set { transformComponent.localScale = newValue }
    }
    
    /// The world transform of this node
    public var transform: Transform {
        return transformComponent.worldTransform
    }
    
    // MARK: - Initialization
    
    /// Initialize a node with an optional name and transform
    public init(name: String = "Node", transform: Transform = Transform()) {
        self.name = name
        
        // Set initial transform values
        transformComponent.localPosition = transform.position
        transformComponent.localRotation = transform.rotation
        transformComponent.localScale = transform.scale
    }
    
    // MARK: - Lifecycle
    
    /// Called when the node is added to the scene
    open func onAddedToScene() {
        // Override in subclasses
    }
    
    /// Called when the node is removed from the scene
    open func onRemovedFromScene() {
        // Override in subclasses
    }
    
    /// Update this node and all its components and children
    open func update(deltaTime: TimeInterval) {
        guard isActive else { return }
        
        // Update components
        updateComponents(deltaTime: deltaTime)
        
        // Update children
        for child in children {
            child.update(deltaTime: deltaTime)
        }
    }
    
    // MARK: - Component Management
    
    /// Add a component to the node
    @discardableResult
    public func addComponent<T: Component>(_ component: T) -> T {
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
    public func getComponent<T: Component>(ofType type: T.Type) -> T? {
        let typeName = String(describing: type)
        return componentsByType[typeName]?.first as? T
    }
    
    /// Get all components of the specified type
    public func getComponents<T: Component>(ofType type: T.Type) -> [T] {
        let typeName = String(describing: type)
        return (componentsByType[typeName] as? [T]) ?? []
    }
    
    /// Remove a component from the node by type
    @discardableResult
    public func removeComponent<T: Component>(ofType type: T.Type) -> Bool {
        guard let component = getComponent(ofType: type) else {
            return false
        }
        
        return removeComponent(component)
    }
    
    /// Remove a specific component from the node
    @discardableResult
    public func removeComponent(_ component: Component) -> Bool {
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
    public func hasComponent<T: Component>(ofType type: T.Type) -> Bool {
        let typeName = String(describing: type)
        return (componentsByType[typeName]?.isEmpty == false)
    }
    
    /// Update all components
    public func updateComponents(deltaTime: TimeInterval) {
        for component in components.values {
            if component.isEnabled {
                component.update(deltaTime: deltaTime)
            }
        }
    }
    
    // MARK: - Hierarchy Management
    
    /// Add a child node
    public func addChild(_ child: Node) {
        guard child !== self else {
            print("Error: Cannot add a node to itself as a child")
            return
        }
        
        if child.parent != nil {
            child.removeFromParent()
        }
        
        children.append(child)
        child.parent = self
        
        // Invalidate child transform
        child.transformComponent.invalidateTransform()
    }
    
    /// Remove a child node
    @discardableResult
    public func removeChild(_ child: Node) -> Bool {
        guard child.parent === self else {
            return false
        }
        
        if let index = children.firstIndex(where: { $0 === child }) {
            children.remove(at: index)
            child.parent = nil
            
            // Invalidate child transform
            child.transformComponent.invalidateTransform()
            return true
        }
        
        return false
    }
    
    /// Remove this node from its parent
    public func removeFromParent() {
        parent?.removeChild(self)
    }
    
    /// Find a child node by name
    public func findChild(named name: String, recursive: Bool = false) -> Node? {
        // Direct children first
        if let child = children.first(where: { $0.name == name }) {
            return child
        }
        
        // Recursive search if requested
        if recursive {
            for child in children {
                if let found = child.findChild(named: name, recursive: true) {
                    return found
                }
            }
        }
        
        return nil
    }
    
    /// Find a child node by ID
    public func findChild(withID id: UUID, recursive: Bool = false) -> Node? {
        // Direct children first
        if let child = children.first(where: { $0.id == id }) {
            return child
        }
        
        // Recursive search if requested
        if recursive {
            for child in children {
                if let found = child.findChild(withID: id, recursive: true) {
                    return found
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Transform Utilities
    
    /// Convert a point from local space to world space
    public func localToWorld(_ localPoint: SIMD3<Float>) -> SIMD3<Float> {
        let worldPoint = transform.modelMatrix * SIMD4<Float>(localPoint.x, localPoint.y, localPoint.z, 1.0)
        return SIMD3<Float>(worldPoint.x, worldPoint.y, worldPoint.z)
    }
    
    /// Convert a point from world space to local space
    public func worldToLocal(_ worldPoint: SIMD3<Float>) -> SIMD3<Float> {
        let inverseMatrix = transform.modelMatrix.inverse
        let localPoint = inverseMatrix * SIMD4<Float>(worldPoint.x, worldPoint.y, worldPoint.z, 1.0)
        return SIMD3<Float>(localPoint.x, localPoint.y, localPoint.z)
    }
    
    /// Look at a target point
    public func lookAt(target: SIMD3<Float>, up: SIMD3<Float> = SIMD3<Float>(0, 1, 0)) {
        let direction = normalize(target - position)
        let right = normalize(cross(up, direction))
        let newUp = cross(direction, right)
        
        // Create rotation matrix
        let rotMatrix = float3x3(
            right,
            newUp,
            direction
        )
        
        // Convert to quaternion
        transformComponent.localRotation = simd_quatf(rotMatrix)
        transformComponent.invalidateTransform()
    }
}
