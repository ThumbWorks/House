//
//  SceneCollectionViewController.swift
//  MyHouse
//
//  Created by Roderic Campbell on 5/5/17.
//  Copyright © 2017 Roderic Campbell. All rights reserved.
//

import UIKit

class SceneCollectionViewController: UIViewController {
    var cameras: [HouseView]?
    var completion: ((IndexPath) -> ())?
}

extension SceneCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? CameraPreviewCell {
            cell.name.text = cameras?[indexPath.row].savedName
//            cell.camera = cameras?[indexPath.row].savedCamera
            cell.sceneView.pointOfView = cameras?[indexPath.row].savedNode
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let cameras = cameras {
            return cameras.count
        }
        return 0
    }
}

extension SceneCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let completion = completion {
            completion(indexPath)
        }
    }
}
