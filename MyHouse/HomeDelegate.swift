//
//  HomeDelegate.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/18/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import HomeKit

class HomeDelegate: NSObject, HMHomeDelegate {
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
