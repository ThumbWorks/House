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
    
    var patioLights = [SCNNode]()
    let homeController = HomeController()
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var sceneView: SCNView!
    
    @IBOutlet weak var backHomeButton: UIButton!
    
    // a proxy camera for testing guesture things
//    let boxNode = SCNNode()
    let cameraNode = SCNNode()
    
    var centerNode = SCNNode()
    let sphere = SCNSphere()
    
    var text = SCNText(string: "", extrusionDepth: 10)
    
    var textNode = SCNNode()
    
    func isFloor(_ node: SCNNode) -> Bool {
        /// for finding floors so we can zoom in on them perhaps
        print("the bounding box is \(node.boundingBox)")
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
        return
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
    
    func createPatioLighting() {
        
        // Find all of the lightbulbs from the string light model
        if let lightNodes = sceneView.scene?.rootNode.childNodes(passingTest: { (node, theBool) -> Bool in
            node.name == "V-Ray_Omni_Light"
        }) {
            
            // for each one
            for lightNode in lightNodes {
                // add a yellow light intensity 20,
                let light = SCNLight()
                light.type = .omni
                light.color = UIColor.yellow
                light.intensity = 0
                lightNode.light = light
                
                // add it to the patioLights array for later manipulation
                patioLights.append(lightNode)
            }
            homeController.home?.light?.isOn(lightCheckHandler: { (lightState) in
                self.updateLights(toState: lightState)
            })
        }
    }
    
    func addLight(_ position: SCNVector3, color: UIColor) {
        // lights
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 200
        ambient.color = color.withAlphaComponent(0.4)
        ambient.shadowColor = UIColor.gray.withAlphaComponent(0.5)
        ambient.castsShadow = true
        
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
        
        let camera = SCNCamera.longZFar()
        
        guard let scene = sceneView.scene else {
            print("there is no scene")
            return
        }
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.pointOfView = cameraNode
        
        cameraNode.position = SCNVector3Make(Float(400), Float(-1000), Float(900))
        let node = scene.rootNode.childNode(withName: "ID3685", recursively: true)
        
        let lookat = SCNLookAtConstraint(target: node)
        cameraNode.constraints = [lookat]
        
        let cameraSpot = SCNLight()
        cameraSpot.type = .spot
        cameraSpot.intensity = 1000
        
        let cameraController = sceneView.defaultCameraController
        cameraController.interactionMode = .orbitTurntable
    }
    
    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        homeController.homekitSetup()
        homeController.lockUpdate = { (lockState) in
            print("view controller sees the door was \(lockState)")
            self.text.string = "\(lockState)"
        }
        homeController.home?.light?.enableNotifications()
        homeController.lightUpdate = { (on) in
            print("view controller sees light on or not \(on)")
            self.updateLights(toState: on)
        }
        homeController.temperatureUpdate = { (temp) in
            self.temperatureLabel.text = "Internal Temperature (updated): \(temp)"
        }
        if let home = homeController.home {
            home.thermostat?.currentTemperature(fetchedTemperatureHandler: { (temp) in
                self.temperatureLabel.text = "Internal Temperature (original): \(temp)"
                self.temperatureLabel.isHidden = false
            })
            home.lock?.isLocked(lockCheckHandler: { (lockState) in
                print("the lock is \(lockState)")
            })
        }
        createPatioLighting()
    }
}

// IBActions
extension ViewController {
    func updateLights(toState : Bool) {
        patioLights.forEach { (node) in
            node.light?.intensity = toState ? 20 : 0
            if let materials = node.geometry?.materials {
                for material in materials {
                    material.emission.contents = toState ? UIColor.yellow : UIColor.black
                }
            }
        }
    }
    
    @IBAction func lightOn(_ sender: UIButton) {
        homeController.turnOnLight()
    }
    
    @IBAction func lightOff(_ sender: UIButton) {
        homeController.turnOffLight()
    }
    
    @IBAction func lock(_ sender: UIButton) {
        homeController.lockDoor()
    }
    
    @IBAction func unlock(_ sender: UIButton) {
        homeController.unlockDoor()
    }
    
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
                        return
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
                    return
                }
                
                if let geometry = node.geometry {
                    print(geometry.materials.map({ (material) -> String? in
                        return "name: \(String(describing: material.name))"
                    }))
                    
                    if isMaterialInSet(geometry, materialNames: ["material_5"]) {
                        
                        if textNode.parent == nil {
                            print("Found the door through it's material")
                            
                            homeController.home?.lock?.isLocked(lockCheckHandler: { (lockState) in
                                switch lockState {
                                case .Locked:
                                    self.text.string = "Locked"
                                    
                                case .Unlocked:
                                    self.text.string = "Unlocked"
                                    
                                case .Jammed:
                                    self.text.string = "Jammed"
                                    
                                case .Unknown:
                                    self.text.string = "Unknown"
                                }
                            })
                            // now add the lock node
                            textNode.geometry = text
                            text.font = UIFont(name: "Helvetica", size: 30)
                            
                            var position = node.boundingBox.max
                            position.z = position.z + 40
                            print("position is \(String(describing: position))")
                            
                            textNode.position = position
                            
                            textNode.constraints = [SCNBillboardConstraint()]
                            node.addChildNode(textNode)
                        } else {
                            textNode.removeFromParentNode()
                        }
                    }
                }
            }
        }
    }
}

extension SCNGeometry {
    // set up our SCNBox which we can use for debugging
    class func createBoxGeometry() -> SCNGeometry {
        
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
        let geometry = SCNBox(width: 5, height: 5, length: 5, chamferRadius: 5.0)
        geometry.materials = [green, orange, purple, blue, yellow, red]
        return geometry
    }
    
    class func createGlobeLightGeometry() -> SCNGeometry {
        let yellow = SCNMaterial()
        yellow.diffuse.contents = UIColor.yellow
        yellow.emission.contents = UIColor.yellow
        
        // Now create the geometry and set the color
        let geometry = SCNSphere(radius: 5)
        geometry.materials = [yellow]
        return geometry
    }
}

extension SCNCamera {
    class func longZFar() -> SCNCamera {
        let camera = SCNCamera()
        // set up the SCNCamera
        camera.automaticallyAdjustsZRange = true
        camera.screenSpaceAmbientOcclusionIntensity = 1
        camera.zFar = 100000
        return camera
    }
}
