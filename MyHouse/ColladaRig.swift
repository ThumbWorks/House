//
//  ColladaRig.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/11/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import SceneKit

class ColladaRig {
    let node: SCNNode
    var animations = [String: CAAnimation]()
    
    init(modelNamed: String, daeNamed: String){
        
        let sceneSource = ColladaRig.getSceneSource(daeNamed: daeNamed)
        node = sceneSource.entryWithIdentifier(modelNamed, withClass: SCNNode.self)!
        
        //Find and add the armature
        let armature = sceneSource.entryWithIdentifier("Armature", withClass: SCNNode.self)!
        //In some Blender output DAE, animation is child of armature, in others it has no child. Not sure what causes this. Hence:
        armature.removeAllAnimations()
        node.addChildNode(armature)
        
        //store and trigger the "rest" animation
        loadAnimation(withKey: "rest", daeNamed: daeNamed)
        playAnimation(named: "rest")
        
        //position node on ground
        var min = SCNVector3(0,0,0)
        var max = SCNVector3(0,0,0)
    
//        node.getBoundingBoxMin(&min, max: &max)
        node.position = SCNVector3(0, -min.y, 0)
    }
    
    static func getSceneSource(daeNamed: String) -> SCNSceneSource {
        let collada = Bundle.main.url(forResource: "art.scnassets/\(daeNamed)", withExtension: "dae")!
        return SCNSceneSource(url: collada, options: nil)!
    }
    
    func loadAnimation(withKey: String, daeNamed: String, fade: CGFloat = 0.3){
        let sceneSource = ColladaRig.getSceneSource(daeNamed: daeNamed)
        let animation = sceneSource.entryWithIdentifier("\(daeNamed)-1", withClass: CAAnimation.self)!
        
        // animation.speed = 1
        animation.fadeInDuration = fade
        animation.fadeOutDuration = fade
        // animation.beginTime = CFTimeInterval( fade!)
        animations[withKey] = animation
    }
    
    func playAnimation(named: String){ //also works for armature
        if let animation = animations[named] {
            node.addAnimation(animation, forKey: named)
        }
    }
    
    func walk() {
        node.pauseAnimation(forKey: "rest")
        //  node.removeAnimationForKey("rest", fadeOutDuration: 0.3)
        
        playAnimation(named: "walk")
        let run = SCNAction.repeatForever( SCNAction.moveBy(x: 0, y: 0, z: 12, duration: 1))
        run.timingMode = .easeInEaseOut //ease the action in to try to match the fade-in and fade-out of the animation
        node.runAction(run, forKey: "walk")
    }
    
    func stopWalking() {
        node.resumeAnimation(forKey: "rest")
        //   node.addAnimation(animations["rest"]!, forKey: "rest")
        node.removeAnimation(forKey: "walk", fadeOutDuration: 0.3)
        node.removeAnimation(forKey: "walk")
    }
}
