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
    
    var cameras = [HouseView]()
    @IBOutlet weak var sceneView: SCNView!
    
    @IBAction func addCamera(_ sender: Any) {
        if let pov = sceneView.pointOfView, let camera = pov.camera {
            print("add camera \(camera) \(pov.rotation) \(pov.position)")
            let alert = UIAlertController(title: "Choose a name for this view", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                if let name = alert.textFields?.first?.text {
                    let cam = HouseView(name: name, node: pov)
                    self.cameras.append(cam)
                }
            }))
            alert.addTextField(configurationHandler: { (textField) in
                print("do I need to do somethiung here?")
            })
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func addAccessory(_ sender: Any) {
        accessoryBrowser = HMAccessoryBrowser()
        accessoryBrowser?.delegate = self
        accessoryBrowser?.startSearchingForNewAccessories()
    }
    
    func animateToCamera(pov: SCNNode) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        sceneView.pointOfView = pov
        SCNTransaction.commit()
    }
    
    @IBAction func tappedScene(_ sender: UITapGestureRecognizer) {
        
        if (sender.state == .ended) {
            let location = sender.location(in: view)
            let hittestResults = sceneView.hitTest(location, options: nil)
            for result in hittestResults {
                
                if let geometry = result.node.geometry {
                    if geometry.material(named: "material_5") != nil {
                        print("Found the door through it's material")
//                        if let camera = sceneView.scene?.rootNode.childNode(withName: "skp_camera_FrontDoor", recursively: true) as SCNCamera {
//                            animateToCamera(camera: camera)
//                            performSegue(withIdentifier: "homekitUISegueID", sender: nil)
//                        }
                    }
                }
            }
        }
        
    }
 
    func homekitSetup() {
        
        // TODO: Currently this is not called
        
        
        homeManager.delegate = self
        
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
        
    override func viewDidLoad() {
        // setup hit test
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
//        sceneView.scene.camera.zfar = 2000
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let homeKitViewController = segue.destination as? HomeKitViewController {            
            // get the lock
            homeKitViewController.lockAccessory = homeManager.primaryHome?.accessories.first
        }
        
        if let sceneCollection = segue.destination as? SceneCollectionViewController {
            sceneCollection.cameras = cameras
            sceneCollection.completion = { (indexPath) in
                print("indexPath \(indexPath)")
                let pov = self.cameras[indexPath.row].savedNode
                self.animateToCamera(pov: pov)
                self.dismiss(animated: true)
            }
        }
    }

}
extension ViewController: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        print("updated homes")
    }
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        print("updated primary")
    }
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        print("did add a home \(home)")
    }
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        print("did remove \(home)")
    }
}
extension ViewController: HMHomeDelegate {
    func homeDidUpdateName(_ home: HMHome) {
        print("new name for home \(home)")
    }
    func home(_ home: HMHome, didAdd room: HMRoom) {
        print("added a room \(room)")
    }
    func home(_ home: HMHome, didAdd user: HMUser) {
        print("added a iuser \(user)")
    }
    func home(_ home: HMHome, didAdd zone: HMZone) {
        print("added a zone \(zone)")
    }
    func home(_ home: HMHome, didRemove room: HMRoom) {
        print("remove a room \(room)")
    }
    func home(_ home: HMHome, didRemove user: HMUser) {
        print("removed a user \(user)")
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

extension ViewController {
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("end 2")
        
        sceneView.pointOfView?.camera
    }
}

