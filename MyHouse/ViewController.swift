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
    
    // a proxy camera for testing guesture things
//    let boxNode = SCNNode()
    let cameraNode = SCNNode()
    
    var centerNode = SCNNode()
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
    var distance:CGFloat = 1000.0
    func moveSphereTo(_ node: SCNNode, shouldShowHomeButton: Bool) {
        print("Attempting to move the sphere the camera on the box is \(cameraNode.camera)")
            
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        self.distance = self.distance - 50
        let lookat = SCNLookAtConstraint(target: node)
        let distance = SCNDistanceConstraint(target: node)
        distance.maximumDistance = self.distance
        distance.minimumDistance = self.distance - 10.0
        cameraNode.constraints = [lookat, distance]
        SCNTransaction.completionBlock = {
            print("the move happened")
            self.backHomeButton.isHidden = !shouldShowHomeButton
        }
        SCNTransaction.commit()
    }

    // set up our SCNBox which will hold the camera
    func createBoxGeometry() -> SCNGeometry {
        
        // create the colors
        let green = SCNMaterial()
        green.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
        
        let red = SCNMaterial()
        red.diffuse.contents = UIColor.red.withAlphaComponent(0.5)
        
        let blue = SCNMaterial()
        blue.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
        
        let purple = SCNMaterial()
        purple.diffuse.contents = UIColor.purple.withAlphaComponent(0.5)
        
        let orange = SCNMaterial()
        orange.diffuse.contents = UIColor.orange.withAlphaComponent(0.5)
        
        let yellow = SCNMaterial()
        yellow.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
        
        // Now create the geometry and set the colors
        let geometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)
        geometry.materials = [green, orange, purple, blue, yellow, red]
        return geometry
    }
    
    func createCamera() -> SCNCamera {
        let camera = SCNCamera()
        // set up the SCNCamera
        camera.automaticallyAdjustsZRange = true
        camera.screenSpaceAmbientOcclusionIntensity = 1
        camera.zFar = 100000
        return camera
    }
    
    func addLight(_ position: SCNVector3, color: UIColor) {
        // lights
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 200
        ambient.color = color.withAlphaComponent(0.4)
        ambient.shadowColor = UIColor.gray.withAlphaComponent(0.5)
        
        let lightNode = SCNNode()
        lightNode.position = position
        lightNode.light = ambient
        
        let cameraColor = SCNMaterial()
        cameraColor.diffuse.contents = color
        
        // Now create the geometry and set the colors
        let geometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)
        lightNode.geometry = geometry
        
        geometry.materials = [cameraColor]
        
        sceneView.scene?.rootNode.addChildNode(lightNode)
    }
    override func viewDidAppear(_ animated: Bool) {
        addLight(SCNVector3(x: 2000, y: 0, z: 2000), color: .white)
        addLight(SCNVector3(x: -2000, y: -2000, z: 2000), color: .white)
        
        let camera = createCamera()
        
        guard let scene = sceneView.scene else {
            print("there is no scene")
            return
        }
//        cameraNode.geometry = createBoxGeometry()
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.pointOfView = cameraNode
        
        cameraNode.position = SCNVector3Make(Float(400), Float(-1000), Float(900))
        let node = scene.rootNode.childNode(withName: "ID2633", recursively: true)
        
        let lookat = SCNLookAtConstraint(target: node)
        cameraNode.constraints = [lookat]
    }
    
    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        //warning: We might be able to remove the boxNode object.
//        boxNode.eulerAngles = SCNVector3Make(Float.pi/2, 0, Float.pi)
        
//        let thermostat = sceneView.scene?.rootNode.childNode(withName: "ThermostatNode", recursively: true)
//        print("thermostat is \(String(describing: thermostat))")
//        thermostat?.constraints = [SCNBillboardConstraint()]
//        sceneView.scene?.rootNode.addChildNode(boxNode)
//        boxNode.camera = createCamera()
//        sceneView.pointOfView = createCamera()
                
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
        print("Don't actually do the show house thing. Just update the constraints")
        return
        backHomeButton.isHidden = true
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        
        moveSphereTo(centerNode, shouldShowHomeButton: false)
//        boxNode.position.y = Float(sphere.radius)
        SCNTransaction.completionBlock = {
            print("re-enable buttons after showing house")
        }
        SCNTransaction.commit()
    }
    
    @IBAction func doubleTappedScene(_ sender: UITapGestureRecognizer) {
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                let node = result.node
                
                if isFloor(node) {
                    // add the zombie node here
                    if let zombieScene = SCNScene(named: "walking3.dae") {
                        //        if let houseNode = SCNScene(named: "art.scnassets/RandomShape.dae") {
                        let zombie = zombieScene.rootNode
                        print("zombie dimensions \(result.worldCoordinates)")
                        zombie.position = result.worldCoordinates
                        sceneView.scene?.rootNode.addChildNode(zombie)
                    }

                    
                }
            }
        }
    }
        
    @IBAction func tappedScene(_ sender: UITapGestureRecognizer) {
        
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                let node = result.node
                
                if isFloor(node) {
                    // update constraint on the camera I guess
                    // Right, again here is where we update the constraints. Let's revisit this and not move the sphere
                    moveSphereTo(node, shouldShowHomeButton: true)
                    return
                }
                
                if let geometry = node.geometry {
                    print(geometry.materials.map({ (material) -> String? in
                        return material.name
                    }))
                    
                    if isMaterialInSet(geometry, materialNames: ["material_5"]) {
                        // now move our camerasphere to the door
                        print("Found the door through it's material")
                        moveSphereTo(node, shouldShowHomeButton: true)
                    }
                }
            }
        }
    }
}

