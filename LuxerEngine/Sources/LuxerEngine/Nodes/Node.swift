//
//  Node.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Foundation

/// Basic node. Not visible

open class Node
{
    let id: UUID = UUID()
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var transform: Transform
    
    init(transform: Transform = Transform( ) ) {
        self.transform = transform
    }
}
