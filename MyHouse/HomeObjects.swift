//
//  HomeObjects.swift
//  MyHouse
//
//  Created by Roderic Campbell on 6/23/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit

class Home {
    var thermostat: Thermostat?
    var lock: DoorLock?
    var light: Light?
}

enum LockState {
    case Locked
    case Unlocked
    case Jammed
    case Unknown
}

class DoorLock {
    
    let accessory: HMAccessory
    let readLockCharacteristic: HMCharacteristic
    let setLockCharacteristic: HMCharacteristic
    init(lock: HMAccessory, readLockedCharacteristic: HMCharacteristic, setLockedCharacteristic: HMCharacteristic) {
        accessory = lock
        readLockCharacteristic = readLockedCharacteristic
        setLockCharacteristic = setLockedCharacteristic
    }
    
    func isLocked(lockCheckHandler: @escaping (LockState) -> ()) {
        // read the lock state
        readLockCharacteristic.readValue(completionHandler: { (error) in
            if let error = error {
                print("There was an error reading the value of the charactersitic \(error.localizedDescription)")
            } else {
                print("successfully read the lock value \(String(describing: self.readLockCharacteristic.value))")
                
                guard let state = self.readLockCharacteristic.value as? Int else {
                    print("unclear what we got for lock value")
                    return
                }
                switch state {
                case HMCharacteristicValueLockMechanismState.jammed.rawValue:
                    lockCheckHandler(LockState.Jammed)
                case HMCharacteristicValueLockMechanismState.secured.rawValue:
                    lockCheckHandler(LockState.Locked)
                case HMCharacteristicValueLockMechanismState.unknown.rawValue:
                    lockCheckHandler(LockState.Unknown)
                case HMCharacteristicValueLockMechanismState.unsecured.rawValue:
                    lockCheckHandler(LockState.Unlocked)
                default:
                    print("unknown state for the Lock characteristic")
                }
            }
        })
    }
    
    func unlockDoor() {
        setLockCharacteristic.writeValue(0, completionHandler: { (error) in
            if let error = error {
                print("error locking the door \(error)")
            } else {
                print("The door is now unlocked")
            }
        })
    }
    
    func lockDoor() {
        setLockCharacteristic.writeValue(1, completionHandler: { (error) in
            if let error = error {
                print("error unlocking door \(error)")
            } else {
                print("The door is now locked")
            }
        })
    }
}

class Light {
    let characteristic: HMCharacteristic
    
    init(powerCharacteristic: HMCharacteristic) {
        characteristic = powerCharacteristic
    }
    
    func turnOnLight() {
        characteristic.writeValue(1) { (error) in
            if let error = error {
                print("error \(error)")
            }
        }
    }
    
    func turnOffLight() {
        characteristic.writeValue(0) { (error) in
            if let error = error {
                print("error \(error)")
            }
        }
    }
}
