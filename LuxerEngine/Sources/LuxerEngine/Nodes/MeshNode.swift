//
//  MeshNode.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Metal
import simd


public protocol MeshProtocol
{
    var vertexBuffer: MTLBuffer { get }
    var indexBuffer: MTLBuffer { get }
    var indexCount: Int { get }
    var vertexDescriptor: MTLVertexDescriptor { get }
}


open class MeshObject: RenderNode
{
    let mesh: MeshProtocol
    
    init( transform: Transform, mesh: MeshProtocol, material: Material ) {
        self.mesh = mesh
        super .init( transform: transform, material: material )
    }
    
    public override func mesh( forDistance distance:Float ) -> MeshProtocol? {
        return mesh
    }
}
