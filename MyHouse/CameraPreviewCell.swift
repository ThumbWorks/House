//
//  CameraPreviewCell.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/5/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class CameraPreviewCell: UICollectionViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var sceneView: SCNView!
    var camera: SCNCamera?
}
