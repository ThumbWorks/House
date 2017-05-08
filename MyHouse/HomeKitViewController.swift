//
//  HomeKitViewController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 4/28/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import HomeKit

class HomeKitViewController: UIViewController {
    var lockAccessory: HMAccessory?
    
    @IBAction func tappedButton(_ sender: Any) {
        print("dismiss")
        self.dismiss(animated: true)
    }
    
    @IBAction func toggleButton(_ sender: Any) {
        print("do the toggle. connect some homekit stuff")
        if let aLockAccessory = lockAccessory {
            print("lockAccessory is \(aLockAccessory)")
        }
    }
}
