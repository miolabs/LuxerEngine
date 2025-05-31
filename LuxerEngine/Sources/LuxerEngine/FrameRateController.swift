//
//  FrameRateController.swift
//  LuxerEngine
//
//  Created by Javier Segura Perez on 28/5/25.
//

import Foundation


class FrameRateController
{
    private var targetFPS: Int = 60
    private var lastFrameTime: TimeInterval = 0
    private var deltaTime: TimeInterval = 0
    private var frameCounter: Int = 0
    private var fpsUpdateTime: TimeInterval = 0
    private var currentFPS: Double = 0
    
    var targetFrameDuration: TimeInterval {
        return 1.0 / Double(targetFPS)
    }
    
    func setTargetFPS(_ fps: Int) {
        targetFPS = max(1, min(120, fps))
    }
    
    func shouldRenderFrame(currentTime: TimeInterval) -> Bool {
        let elapsed = currentTime - lastFrameTime
        return elapsed >= targetFrameDuration
    }
    
    func updateFrameTiming(currentTime: TimeInterval) {
        deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime
        
        frameCounter += 1
        if currentTime - fpsUpdateTime >= 1.0 {
            currentFPS = Double(frameCounter) / (currentTime - fpsUpdateTime)
            frameCounter = 0
            fpsUpdateTime = currentTime
        }
    }
    
    var fps: Double { currentFPS }
    var delta: TimeInterval { deltaTime }
}
