//
//  ViewController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 4/25/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import UIKit
import SceneKit

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: SCNView!
    
    var originalXAngle: Float = 0.0
    var originalZHeight: Float = 0.0
    
    let kitchenFloorID = "ID3073"

    let cameraNode = SCNNode()
    
    // a proxy camera for testing guesture things
    let boxNode = SCNNode()

    var cameraSphereNode = SCNNode()
    let sphere = SCNSphere(radius: CGFloat(100))
    
    func isFloor(_ node: SCNNode) -> Bool {
        /// for finding floors so we can zoom in on them perhaps
        print(node.name)
        print(node.boundingBox)
        let maxZ = node.boundingBox.max.z
        let minZ = node.boundingBox.min.z
        
        if maxZ == minZ {
            print("this is likely a floor we can lookat")
            if let name = node.name {
                // move the center of the cameraSphereNode to that thing
            }
            return true
        }
        return false
    }
    
    func isMaterialInSet(_ geometry: SCNGeometry, materialNames: [String]) -> Bool {
        for materialName in materialNames {
            if let _ = geometry.material(named: materialName) {
                return true
            }
        }
        return false
    }
    
    func moveSphereTo(_ node: SCNNode, radius: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        cameraSphereNode.position = node.boundingSphere.center
        sphere.radius = CGFloat(radius)
        boxNode.position.y = radius
        SCNTransaction.commit()
    }

    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        // set up our camera mounting sphere
        boxNode.geometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)
        let green = SCNMaterial()
        green.diffuse.contents = UIColor.green
        let red = SCNMaterial()
        red.diffuse.contents = UIColor.red
        boxNode.geometry?.materials = [green, green, green, green, green, red]
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue
        material.transparency = 0.3
        sphere.materials = [material]
        
        cameraSphereNode.geometry = sphere
        boxNode.position = SCNVector3Make(0, Float(sphere.radius), 30)
        cameraSphereNode.addChildNode(boxNode)

        // set up the SCNCamera
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        cameraNode.camera = camera
        
        // set the position of the node to 500 above the origin (z == 500)
        let position = SCNVector3(x: 0, y: -500, z: 1200)
        cameraNode.position = position
        
        cameraNode.rotation =
            SCNVector4Make(1, 0, 0, // rotate around X
                -atan2f(-500, 1200)); // -atan(camY/camZ)
        
        sceneView.scene?.rootNode.addChildNode(cameraSphereNode)
        
        // add the node to the scene (may be redundant after multiple viewDidAppear calls)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
    }
}

extension ViewController {
    @IBAction func pan(_ pan: UIPanGestureRecognizer) {
        
        let translation = pan.translation(in: self.view)
        
        // left to right pan values
        var newAngleX = (Float)(translation.x)*(Float)(Double.pi)/180.0
        newAngleX += originalXAngle
        
        // vertical pan values
        let newAngleY = -(Float)(translation.y)*(Float)(Double.pi)/180.0 * 20 // Multiply by 20 just to speed it up
        
        switch pan.state {
        case .began:
            originalXAngle = cameraSphereNode.eulerAngles.z
            originalZHeight = boxNode.position.z
        case .changed:
            cameraSphereNode.eulerAngles.z = newAngleX
            boxNode.position.z = originalZHeight + newAngleY
            boxNode.rotation =
                SCNVector4Make(1, 0, 0, // rotate around X
                    atan2f(boxNode.position.z, boxNode.position.y)); // -atan(camY/camZ)

        default:
            print("something else")
        }
    }
    
    @IBAction func tappedScene(_ sender: UITapGestureRecognizer) {
        
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                let node = result.node
                
                if isFloor(node) {
                    moveSphereTo(node, radius:10)
                    return
                }
                
                if let geometry = node.geometry {
                    print(geometry.materials.map({ (material) -> String? in
                        return material.name
                    }))
                    
                    if isMaterialInSet(geometry, materialNames: ["material_5"]) {
                        // now move our camerasphere to the door
                        print("Found the door through it's material")
                        moveSphereTo(node, radius:node.boundingSphere.radius * 2)
                    }
                }
            }
        }
    }
}

