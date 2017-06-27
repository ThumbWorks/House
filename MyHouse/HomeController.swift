//
//  HomeController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/23/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit
extension HomeController: HMAccessoryDelegate {
    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        print("an accessory updated")
        let lock = home?.lock
        let light = home?.light
        let thermostat = home?.thermostat
        if characteristic == lock?.setLockCharacteristic {
            print("the door lock changed")
            guard let closure = lockUpdate else {
                print("no lock closure defined")
                return
            }
            lock?.isLocked(lockCheckHandler: { (lockState) in
                closure(lockState)
            })
        }
        else if characteristic == light?.characteristic {
            guard let closure = lightUpdate else {
                print("no light closure defined")
                return
            }
            light?.isOn(lightCheckHandler: { (isOn) in
                closure(isOn)
            })
        }
        else if characteristic == thermostat?.currentTempCharacteristic {
            if let temperature = thermostat?.temperature(), let closure = temperatureUpdate {
                print("Thermostat changed \(temperature)")
                closure(temperature.celsiusToFarenheit())
            }
        }
        else {
            print("An untracked accessory changed state: Accessory: \(accessory). Service: \(service). Characteristic: \(characteristic), \(characteristic.localizedDescription)")
        }
    }
}

class HomeController: NSObject {
    var home: Home?
    
    let homeManager = HMHomeManager()
    let homeManagerDelegate = HomeManagerDelegate()
    
    // closures
    var temperatureUpdate: ((Float) -> Void)?
    var lockUpdate: ((LockState) -> Void)?
    var lightUpdate: ((Bool) -> Void)?
    
    // Setup goes through all available devices to determine services and characteristics then stores references
    // in this HomeController instance
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
            if let homeObject = homeManager.primaryHome {
                home = Home()
                print("the accessories are \(homeObject.accessories)")
                for accessory in homeObject.accessories {
                    print(" services for  \(accessory.name)")
                    for service in accessory.services {
                        print("  service \(service.name)")
                    }
                    print("\n\n")
                    for service in accessory.services {
                        // blindly set all accessory delegates to self, we can filter when we get the notifications
                        accessory.delegate = self
                        
                        print("  this service \(service.name) has characteristics")
                        for characteristic in service.characteristics {
                            print("   characteristic \(characteristic.localizedDescription)")//\(characteristic.properties) ")
                            
                            if service.name == "Patio Light" && characteristic.localizedDescription == "Power State" {
                                home?.light =  Light(lightCharacteristic: characteristic)
                            }
                            if characteristic.localizedDescription == "Current Temperature" {
                                print("      Current temperature type is \(characteristic.characteristicType)")
                                home?.thermostat = Thermostat(thermostat: accessory, currentTemp: characteristic)
                            }
                            if characteristic.localizedDescription == "Lock Mechanism Current State" {
                                print("      Current lock state mechanism type is \(characteristic.characteristicType)")
                                
                                // We now know that this is a lock, it has a characteristicType for modifying, let's find it
                                let lockCharArray = service.characteristics.filter({ (filterCharactersitic) -> Bool in
                                    if (filterCharactersitic.localizedDescription == "Lock Mechanism Target State") {
                                        return true
                                    }
                                    return false
                                })
                                
                                guard let lockChar = lockCharArray.first else {
                                    print("We did not get a set lock characteristic")
                                    return
                                }
                                print("      Lock mechanism type is \(lockChar.characteristicType)")
                                home?.lock = DoorLock(lock: accessory, readLockedCharacteristic: characteristic, setLockedCharacteristic: lockChar)
                                home?.lock?.enableNotifications()
                            }
                        }
                    }
                }
            }
        }
    }
}

extension HomeController {
    func turnOnLight() {
        home?.light?.turnOnLight(lightHandler: { (success) in
            if let lightUpdate = self.lightUpdate {
                lightUpdate(success)
            }
        })
    }
    
    func turnOffLight() {
        home?.light?.turnOffLight(lightHandler: { (success) in
            if let lightUpdate = self.lightUpdate {
                // If this fails, send back a YES because we want to keep the lights on
                lightUpdate(!success)
            }
        })
    }
    
    func lockDoor() {
        home?.lock?.lockDoor()
    }
    
    func unlockDoor() {
        home?.lock?.unlockDoor()
    }
}
