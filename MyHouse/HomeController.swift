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
    var home: Home?
    
    let homeManager = HMHomeManager()
    var accessoryBrowser: HMAccessoryBrowser?
    let homeManagerDelegate = HomeManagerDelegate()
    
    func lockDoor() {
        home?.lock?.lockDoor()
    }
    
    func unlockDoor() {
        home?.lock?.unlockDoor()
    }
    
    // Setup goes through all available devices to determine services and characteristics
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
                        print("  this service \(service.name) has characteristics")
                        for characteristic in service.characteristics {
                            print("   characteristic \(characteristic.localizedDescription)")//\(characteristic.properties) ")
                            
                            if service.name == "Light" && characteristic.localizedDescription == "Power State" {
                                home?.light = Light(powerCharacteristic: characteristic)
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
                            }
                        }
                    }
                }
            }
        }
    }
}

class Thermostat {
    let accessory: HMAccessory
    let currentTempCharacteristic: HMCharacteristic
    init(thermostat: HMAccessory, currentTemp: HMCharacteristic) {
        accessory = thermostat
        currentTempCharacteristic = currentTemp
    }
    
    func currentTemperature(fetchedTemperatureHandler: @escaping (Float) -> ()) {
        print("hi")
        currentTempCharacteristic.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
            } else {
                print("successfully read the temperature value \(String(describing: self.currentTempCharacteristic.value))")
                if let temperature =  self.currentTempCharacteristic.value as? NSNumber {
                    let fahrenheit = temperature.floatValue * 1.8 + 32
                    fetchedTemperatureHandler(fahrenheit)
                }
            }
        })
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
