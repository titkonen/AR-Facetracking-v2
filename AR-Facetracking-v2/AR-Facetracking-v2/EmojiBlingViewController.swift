//
//  ViewController.swift
//  AR-Facetracking-v2
//
//  Created by Toni Itkonen on 08/04/2019.
//  Copyright © 2019 Toni Itkonen. All rights reserved.
//

import UIKit
import ARKit

class EmojiBlingViewController: UIViewController {
    
    // LET
    let noseOptions = ["👃", "🐽", "💧", " "]
    let eyeOptions = ["👁", "🌕", "🌟", "🔥", "⚽️", "🔎", " "]
    let mouthOptions = ["👄", "👅", "❤️", " "]
    let hatOptions = ["🎓", "🎩", "🧢", "⛑", "👒", " "]
    let features = ["nose", "leftEye", "rightEye", "mouth", "hat"] // is an array of the node names you gave to each feature and
    let featureIndices = [[9], [1064], [42], [24, 25], [20]] // are the vertex indexes in the ARFaceGeometry that correspond to those features (remember the magic numbers?).
    
    
    // IBOutlet
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Face tracking is not supported on this device")
        }
        sceneView.delegate = self
        
    }
    
    // IBAction
    // Pystyt vaihtamaan kosketuksella toiseen assettiin nenässä
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        // 1
        let location = sender.location(in: sceneView)
        
        // 2
        let results = sceneView.hitTest(location, options: nil)
        
        // 3
        if let result = results.first,
            let node = result.node as? EmojiNode {
            
            // 4
            node.next()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1
        let configuration = ARFaceTrackingConfiguration()
        
        // 2
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 1
        sceneView.session.pause()
    }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        // 1
        for (feature, indices) in zip(features, featureIndices)  {
            // 2
            let child = node.childNode(withName: feature, recursively: false) as? EmojiNode
            
            // 3
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            
            // 4
            child?.updatePosition(for: vertices)
            
            switch feature {
            case "leftEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            case "rightEye":
                let scaleX = child?.scale.x ?? 1.0
                let eyeBlinkValue = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
                child?.scale = SCNVector3(scaleX, 1.0 - eyeBlinkValue, 1.0)
            case "mouth":
                let jawOpenValue = anchor.blendShapes[.jawOpen]?.floatValue ?? 0.2
                child?.scale = SCNVector3(1.0, 0.8 + jawOpenValue, 1.0)
            default:
                break
            }
        }
    }


}

// 1
extension EmojiBlingViewController: ARSCNViewDelegate {
    // 2
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        // 3
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let device = sceneView.device else {
                return nil
        }
        
        // 4
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        // 5
        let node = SCNNode(geometry: faceGeometry)
        
        // 6
        node.geometry?.firstMaterial?.fillMode = .lines
        
        // 1
        node.geometry?.firstMaterial?.transparency = 0.0
        
        // 2
        let noseNode = EmojiNode(with: noseOptions)
        
        // 3
        noseNode.name = "nose"
        
        // 4
        node.addChildNode(noseNode)
        
        // Child node options added
        let leftEyeNode = EmojiNode(with: eyeOptions)
        leftEyeNode.name = "leftEye"
        leftEyeNode.rotation = SCNVector4(0, 1, 0, GLKMathDegreesToRadians(180.0))
        node.addChildNode(leftEyeNode)
        
        let rightEyeNode = EmojiNode(with: eyeOptions)
        rightEyeNode.name = "rightEye"
        node.addChildNode(rightEyeNode)
        
        let mouthNode = EmojiNode(with: mouthOptions)
        mouthNode.name = "mouth"
        node.addChildNode(mouthNode)
        
        let hatNode = EmojiNode(with: hatOptions)
        hatNode.name = "hat"
        node.addChildNode(hatNode)
        
        updateFeatures(for: node, using: faceAnchor)
        return node
    }
    
    // 1
    func renderer(
        _ renderer: SCNSceneRenderer,
        didUpdate node: SCNNode,
        for anchor: ARAnchor) {
        
        // 2
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        // 3
        faceGeometry.update(from: faceAnchor.geometry)
        
        updateFeatures(for: node, using: faceAnchor)        
    }
}
