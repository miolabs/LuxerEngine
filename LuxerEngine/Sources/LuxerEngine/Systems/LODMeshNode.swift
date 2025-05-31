//
//  LODMeshNode.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

class LODMeshNode: RenderNode
{
    var lodMesh: LODMesh

    init(transform: Transform, lodMesh: LODMesh, material: Material) {
        self.lodMesh = lodMesh
        super .init(transform: transform, material: material)
    }
    
    public override func mesh( forDistance distance:Float) -> MeshProtocol? {
        return lodMesh.selectLOD(distance: distance)
    }

}
