//
//  LODMesh.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

class LODMesh
{
    let lodMeshes: [LODLevel: MeshProtocol]
    private let baseDistance: Float = 10.0
    private let lodDistances: [Float] = [0, 20, 50, 100]
    
    init(lodMeshes: [LODLevel: MeshProtocol]) {
        self.lodMeshes = lodMeshes
    }
    
    func selectLOD( distance: Float ) -> MeshProtocol? {
        for (index, threshold) in lodDistances.enumerated().reversed() {
            if distance >= threshold {
                let level = LODLevel(rawValue: index) ?? .lod3
                if let mesh = lodMeshes[level] {
                    return mesh
                }
            }
        }
        return nil
    }
}
