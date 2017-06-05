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
    
    let homeController = HomeController()
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var sceneView: SCNView!
    
    @IBOutlet weak var backHomeButton: UIButton!
    
    var originalXAngle: Float = 0.0
    var originalZHeight: Float = 0.0
    
    let kitchenFloorID = "ID3073"

    let cameraNode = SCNNode()

    // a proxy camera for testing guesture things
    let boxNode = SCNNode()

    var centerNode = SCNNode()
    var cameraSphereNode = SCNNode()
    let sphere = SCNSphere()
    
    func isFloor(_ node: SCNNode) -> Bool {
        /// for finding floors so we can zoom in on them perhaps
        print(node.boundingBox)
        let maxZ = node.boundingBox.max.z
        let minZ = node.boundingBox.min.z
        
        if maxZ == minZ {
            print("this is a floor we can lookat")
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
    
    func moveSphereTo(_ node: SCNNode, radius: Float, height: Float, shouldShowHomeButton: Bool) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        cameraSphereNode.position = node.boundingSphere.center
        cameraSphereNode.position.z = height
        sphere.radius = CGFloat(radius)
        boxNode.position.y = radius
        SCNTransaction.completionBlock = {
            self.backHomeButton.isHidden = !shouldShowHomeButton
        }
        SCNTransaction.commit()
    }

    // set up our SCNBox which will hold the camera
    func createBoxGeometry(box: SCNNode) {
        
        // create the colors
        let green = SCNMaterial()
        green.diffuse.contents = UIColor.green
        
        let red = SCNMaterial()
        red.diffuse.contents = UIColor.red
        
        let blue = SCNMaterial()
        blue.diffuse.contents = UIColor.blue
        
        let purple = SCNMaterial()
        purple.diffuse.contents = UIColor.purple
        
        let orange = SCNMaterial()
        orange.diffuse.contents = UIColor.orange
        
        let yellow = SCNMaterial()
        yellow.diffuse.contents = UIColor.yellow
        
        // Now create the geometry and set the colors
        let geometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)
        boxNode.geometry = geometry
        
        geometry.materials = [green, orange, purple, blue, yellow, red]
    }
    
    func createCamera() -> SCNCamera {
        let camera = SCNCamera()
        // set up the SCNCamera
        camera.automaticallyAdjustsZRange = true
        camera.zFar = 10000
        camera.yFov = 105
        camera.xFov = 105
        return camera
    }
    
    func setupCameraSphere(_ sphere: SCNSphere, sphereNode: SCNNode, box: SCNNode) {
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.clear
        sphere.materials = [material]
        
        let radius: CGFloat = 200
        sphere.radius = radius
        box.position = SCNVector3Make(0, Float(radius), 0)
        sphereNode.position = SCNVector3Make(50, 50, 100)
        sphereNode.geometry = sphere
        sphereNode.addChildNode(box)
    }
    
    func addLights() {
        // lights
        let position = SCNVector3(x: 0, y: -200, z: 300)
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor.gray
        ambient.shadowColor = UIColor.black
        
        let lightNode = SCNNode()
        lightNode.position = position
        lightNode.light = ambient
        sceneView.scene?.rootNode.addChildNode(lightNode)
    }
    
    func createGreenBoxForReference() {
        let greenBoxGeometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)
        let greenNode = SCNNode(geometry: greenBoxGeometry)
        
        let greenMaterial = SCNMaterial()
        greenMaterial.diffuse.contents = UIColor.green
        greenBoxGeometry.materials = [greenMaterial]
        cameraSphereNode.addChildNode(greenNode)
    }
    
    func setupGodCamera() {
        // set the god camera
        let position = SCNVector3(x: 100, y: -400, z: 350)
        // set the position of the node to 500 above the origin (z == 500)
        cameraNode.position = position
        cameraNode.rotation =
            SCNVector4Make(1, 0, 0, // rotate around X
                -atan2f(-250, 600)); // -atan(camY/camZ)
        cameraNode.camera = createCamera()
    }
    
    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        createBoxGeometry(box: boxNode)
        setupCameraSphere(sphere, sphereNode: cameraSphereNode, box: boxNode)
        boxNode.eulerAngles = SCNVector3Make(Float.pi/2, 0, Float.pi)
    
        sceneView.scene?.rootNode.addChildNode(cameraSphereNode)
        
        // add the cameraNode to the scene (may be redundant after multiple viewDidAppear calls)
        sceneView.scene?.rootNode.addChildNode(cameraNode)

        boxNode.camera = createCamera()
        setupGodCamera()
        
        addLights()
        sceneView.pointOfView = boxNode
        
        moveSphereTo(centerNode, radius: 500, height: 300, shouldShowHomeButton: false)
        
        homeController.temperatureClosure = { (temp: Float) in
            print("Got the temp at the view controller \(temp)")
            self.temperatureLabel.text = "Internal Temperature: \(temp)"
            self.temperatureLabel.isHidden = false
        }
        homeController.homekitSetup()
    }
}

extension ViewController {
    
    @IBAction func showHouse(_ sender: UIButton) {
        backHomeButton.isHidden = true
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        moveSphereTo(centerNode, radius: 500, height: 300, shouldShowHomeButton: false)
        boxNode.position.y = Float(sphere.radius)
        SCNTransaction.completionBlock = {
            print("re-enable buttons after showing house")
        }
        SCNTransaction.commit()
    }

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
            print("boxNode after rotation \(boxNode.position) \(boxNode.rotation)")

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
                    moveSphereTo(node, radius:10, height: node.position.z + 100, shouldShowHomeButton: true)
                    return
                }
                
                if let geometry = node.geometry {
                    print(geometry.materials.map({ (material) -> String? in
                        return material.name
                    }))
                    
                    if isMaterialInSet(geometry, materialNames: ["material_5"]) {
                        // now move our camerasphere to the door
                        print("Found the door through it's material")
                        moveSphereTo(node, radius:node.boundingSphere.radius * 2, height: node.position.z + 10, shouldShowHomeButton: true)
                    }
                }
            }
        }
    }
}

