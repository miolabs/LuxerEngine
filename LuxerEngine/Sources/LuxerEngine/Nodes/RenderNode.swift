//
//  Node.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Foundation
import simd

open class RenderNode: Node
{
    var material: Material
    var isVisible: Bool = true
    var boundingSphere: Float = 1.0
    
    init(transform: Transform, material: Material) {
        self.material = material
        super .init(transform: transform)
    }
    
    func distanceToCamera(_ cameraPosition: SIMD3<Float>) -> Float {
        return simd_distance(transform.position, cameraPosition)
    }
    
    func mesh( forDistance distance:Float ) -> MeshProtocol? {
        return nil
    }
}
