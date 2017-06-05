//
//  HomeController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/23/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit

class HomeController: NSObject {
  
    let homeManager = HMHomeManager()
    var accessoryBrowser: HMAccessoryBrowser?
    let homeManagerDelegate = HomeManagerDelegate()

    var temperatureClosure = { (temp: Float) in
        print("The temperature is \(temp)")
    }
    
    @IBAction func addAccessory(_ sender: Any) {
        accessoryBrowser = HMAccessoryBrowser()
        accessoryBrowser?.delegate = self
        accessoryBrowser?.startSearchingForNewAccessories()
    }
    
    /*override*/ func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let homeKitViewController = segue.destination as? HomeKitViewController {
            // get the lock
            homeKitViewController.lockAccessory = homeManager.primaryHome?.accessories.first
        }
    }
    
    func homekitSetup() {
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
                    print("\n\n")
                    for service in accessory.services {
                        print("  this service \(service.name) has characteristics")
                        for characteristic in service.characteristics {
                            print("   characteristic \(characteristic.localizedDescription)")//\(characteristic.properties) \(characteristic.characteristicType)")
                            if characteristic.localizedDescription == "Current Temperature" {
                                print("     Let's query the Current temperature asyncronously")
                                // read the current temperature
                                characteristic.readValue(completionHandler: { (error) in
                                    if let error = error {
                                        print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
                                    } else {
                                        print("successfully read the temperature value \(String(describing: characteristic.value))")
                                        if let temperature =  characteristic.value as? Float {
                                            self.temperatureClosure(temperature)
                                        }
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

extension HomeController: HMAccessoryBrowserDelegate {
    func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
        print("found this one \(accessory)")
        homeManager.primaryHome?.addAccessory(accessory, completionHandler: { (error) in
            print("error adding accessory \(String(describing: error))")
        })
    }
}
