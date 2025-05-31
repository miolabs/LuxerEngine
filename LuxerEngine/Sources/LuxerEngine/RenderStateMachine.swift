//
//  RenderStateMachine.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Foundation


enum RenderState
{
    case idle
    case preparing
    case culling
    case sorting
    case rendering
    case presenting
}

class RenderStateMachine
{
    private(set) var currentState: RenderState = .idle
    private var stateTimings: [RenderState: TimeInterval] = [:]
    private var stateStartTime: TimeInterval = 0
    
    func transition(to newState: RenderState, at time: TimeInterval) {
        if currentState != .idle {
            let duration = time - stateStartTime
            stateTimings[currentState] = duration
        }
        currentState = newState
        stateStartTime = time
    }
    
    func getStateTimings() -> [RenderState: TimeInterval] {
        return stateTimings
    }
    
    func resetTimings() {
        stateTimings.removeAll()
    }
}
