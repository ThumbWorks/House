//
//  HouseView.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/5/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import SceneKit

class HouseView {
    let savedName: String
    let savedNode: SCNNode
    init(name: String, node: SCNNode) {
        savedName = name
        savedNode = node
    }
}
