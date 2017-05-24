//
//  ViewController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 4/25/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import UIKit
import SceneKit
import HomeKit

class ViewController: UIViewController {
    
    let homeManager = HMHomeManager()
    var accessoryBrowser: HMAccessoryBrowser?
    let homeManagerDelegate = HomeManagerDelegate()

    @IBOutlet weak var sceneView: SCNView!
    
    var originalXAngle: Float = 0.0
    var originalZHeight: Float = 0.0
    
    let kitchenFloorID = "ID3073"

    let cameraNode = SCNNode()
    
    // a proxy camera for testing guesture things
    let boxNode = SCNNode()

    var cameraSphereNode = SCNNode()
    let sphere = SCNSphere(radius: CGFloat(100))

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
        default:
            print("something else")
        }
    }
    
    @IBAction func addAccessory(_ sender: Any) {
        accessoryBrowser = HMAccessoryBrowser()
        accessoryBrowser?.delegate = self
        accessoryBrowser?.startSearchingForNewAccessories()
    }
    
    func delayAnimateCameraNode(cameraNode: SCNNode, position: SCNVector3, delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(delay)) {
            print("position is \(position). rotation \(cameraNode.rotation)")
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 2
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            cameraNode.position = position
            SCNTransaction.commit()
        }
    }
    
    func animatePOVToNode(node: SCNNode) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        sceneView.pointOfView = node
        SCNTransaction.commit()
    }
    
    func isFloor(node: SCNNode) {
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
        }
        
    }
    
    func isMaterialInSet(_ geometry: SCNGeometry, materialNames: [String]) -> Bool {
        for materialName in materialNames {
            if let _ = geometry.material(named: materialName) {
                return true
            }
        }
        return false
    }
    
    @IBAction func tappedScene(_ sender: UITapGestureRecognizer) {
        
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                let node = result.node

                //isFloor(node: node)
                
                if let geometry = node.geometry {
                    print(geometry.materials.map({ (material) -> String? in
                        return material.name
                    }))
                
                    if isMaterialInSet(geometry, materialNames: ["material_5", "Wood_Floor_Dark", "Pavers_Driveway_Brick", "_Wood_Floor_Dark__3", "_Wood_Floor_Dark__2", "Slate_Light_Tile", "Blacktop_Old_02"]) {
                        print("Found the door through it's material. It's bounding box is: \(node.boundingBox). How would I set a camera to look at that. ")
                        
                        
                        // now move our camerasphere to the door
                        
                        print("node is \(node.boundingSphere.center)")
                    
                        SCNTransaction.begin()
                        SCNTransaction.animationDuration = 1
                        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                        cameraSphereNode.position = node.boundingSphere.center
                        sphere.radius = CGFloat(node.boundingSphere.radius * 3)
                        boxNode.position.x = Float(sphere.radius)
                        SCNTransaction.commit()
                        
                        
                        break
                        var position = node.boundingBox.min
                        position.x = position.x + 100
                        position.y = position.y + 100
                        position.z = position.z + 100
                        
                        let camera = SCNCamera()
                        let node = SCNNode()
                        node.camera = camera
                        sceneView.scene?.rootNode.addChildNode(node)
                        node.position = cameraNode.position
                        sceneView.pointOfView = node
                        delayAnimateCameraNode(cameraNode: node, position: position, delay: 1)
                        
                        // now i need to make a camera that faces this object
                        //if let camera = sceneView.scene?.rootNode.childNode(withName: "skp_camera_FrontDoor", recursively: true) as SCNCamera {
                          //  animateToCamera(camera: camera)
                            //performSegue(withIdentifier: "homekitUISegueID", sender: nil)
                        //}
                    }
                }
            }
        }
        
    }

    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        
        // set up our camera mounting sphere
        boxNode.geometry = SCNBox(width: 60, height: 60, length: 60, chamferRadius: 4.0)

        
        let material = SCNMaterial()
        let samImageName = "/Users/roderic/Desktop/SamIcon/Icon-98.png"
        material.diffuse.contents = UIImage(contentsOfFile: samImageName)
        material.transparency = 0.5
        sphere.materials = [material]
        
        cameraSphereNode.geometry = sphere
        
        boxNode.position = SCNVector3Make(Float(sphere.radius), 0, 30)
        cameraSphereNode.addChildNode(boxNode)

        // set up the SCNCamera
        let camera = SCNCamera()
        camera.automaticallyAdjustsZRange = true
        //camera.zFar = 10000
        cameraNode.camera = camera
        
        // set the position of the node to 500 above the origin (z == 500)
        let position = SCNVector3(x: 0, y: -500, z: 1200)
        cameraNode.position = position
        
        cameraNode.rotation =
            SCNVector4Make(1, 0, 0, // rotate around X
                atan2f(10.0, 20.0)); // -atan(camY/camZ)
        
        sceneView.scene?.rootNode.addChildNode(cameraSphereNode)
        
        // add the node to the scene (may be redundant after multiple viewDidAppear calls)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode

    }
    
    func viewFromSource(source: String) {
        let sceneRoot = self.sceneView.scene?.rootNode

        if let cameraNode = sceneRoot?.childNode(withName: source, recursively: true), let kitchenFloor = sceneRoot?.childNode(withName: kitchenFloorID, recursively: true) {
            
            let newCameraNode = SCNNode()
            let camera = SCNCamera()
            newCameraNode.camera = camera
            camera.zFar = 10000
            camera.zNear = 1
            newCameraNode.position = cameraNode.boundingBox.max

            cameraNode.addChildNode(newCameraNode)
            let floorLookatConstraint = SCNLookAtConstraint(target: kitchenFloor)
            newCameraNode.constraints = [floorLookatConstraint]
            animatePOVToNode(node: newCameraNode)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let homeKitViewController = segue.destination as? HomeKitViewController {
            // get the lock
            homeKitViewController.lockAccessory = homeManager.primaryHome?.accessories.first
        }        
    }
    
    func homekitSetup() {
        // TODO: Currently this is not called
        homeManager.delegate = homeManagerDelegate
        
        if homeManager.homes.count == 0 {
            print("there are no homes")
            homeManager.addHome(withName: "arbutus", completionHandler: { (home, error) in
                print("the home is \(String(describing: home?.name)) error is \(String(describing: error))")
                if error == nil {
                    home?.addRoom(withName: "Main Room", completionHandler: { (room, error) in
                        if let error = error {
                            print("Error creating room \(error)")
                        }
                    })
                }
            })
        } else {
            print(" found some homes \(homeManager.homes)")
            if let home = homeManager.primaryHome {
                print("the accessories are \(home.accessories)")
                for accessory in home.accessories {
                    print(" services for  \(accessory.name)")
                    for service in accessory.services {
                        print("  service \(service.name)")
                    }
                    for service in accessory.services {
                        print("  this service \(service.name) has characteristics")
                        for characteristic in service.characteristics {
                            print("   characteristic \(characteristic.localizedDescription) \(characteristic.properties) \(characteristic.characteristicType)")
                            if characteristic.localizedDescription == "Current Temperature" {
                                // read the current temperature
                                characteristic.readValue(completionHandler: { (error) in
                                    if let error = error {
                                        print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
                                    } else {
                                        print("successfully read the temperature value \(String(describing: characteristic.value))")
                                    }
                                })
                                
                            }
                            
                            if characteristic.localizedDescription == "Lock Mechanism Current State" {
                                // read the lock state
                                characteristic.readValue(completionHandler: { (error) in
                                    if let error = error {
                                        print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
                                    } else {
                                        print("successfully read the lock value \(String(describing: characteristic.value))")
                                        
                                        let lockChar = service.characteristics.filter({ (filterCharactersitic) -> Bool in
                                            if (filterCharactersitic.localizedDescription == "Lock Mechanism Target State") {
                                                return true
                                            }
                                            return false
                                        }).first
                                        lockChar?.writeValue(1, completionHandler: { (error) in
                                            if let error = error {
                                                print("error \(error)")
                                            }
                                        })
                                    }
                                })
                                
                            }
                            
                        }
                    }
                }
            }
        }
    }
}



extension ViewController: HMAccessoryBrowserDelegate {
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        print("found this one \(accessory)")
        homeManager.primaryHome?.addAccessory(accessory, completionHandler: { (error) in
            print("error adding accessory \(String(describing: error))")
        })
    }
}

