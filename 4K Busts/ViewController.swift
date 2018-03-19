//
//  ViewController.swift
//  4K Busts
//
//  Created by Flip on 7/19/17.
//  Copyright © 2017 Flip. All rights reserved.
//

import ARKit
import UIKit
import SceneKit
import SceneKit.ModelIO
import Foundation
import Alamofire

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
  
  @IBOutlet var sceneView: ARSCNView!
  
  // Keep track of the planes
  var planes: [UUID:Plane] = [:]
  
  // Keep track of which type of block is selected
  var selectedBlockType: Int = 0
  
  // Hide the status bar
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  // Add planes
  internal func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    if let planeAnchor = anchor as? ARPlaneAnchor {
      planes[planeAnchor.identifier] = Plane(with: planeAnchor)
      node.addChildNode(planes[planeAnchor.identifier]!)
    }
  }
  
  // Update planes
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    planes[anchor.identifier]!.update(anchor: anchor as! ARPlaneAnchor)
  }
  
  // Remove planes
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    planes.removeValue(forKey: anchor.identifier)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    // Setup the scene
    sceneView.delegate = self
    sceneView.showsStatistics = false
    sceneView.autoenablesDefaultLighting = true
    sceneView.scene = SCNScene()
  
    // Add physics
    sceneView.scene.physicsWorld.gravity = SCNVector3Make(0.0, -1.225, 0.0)
    sceneView.scene.physicsWorld.speed = 0.5
    sceneView.scene.physicsWorld.contactDelegate = self
  
    // Attach tap recognition
    sceneView.addGestureRecognizer(
      UITapGestureRecognizer(
        target: self,
        action: #selector(handleTap(_:))
      )
    )
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  
    // Detect planes
    let configuration = ARWorldTrackingConfiguration()
    configuration.planeDetection = .horizontal
  
    sceneView.session.run(configuration)
  }
  
  override func viewDidAppear(_ animated: Bool) {
    // Show welcome prompt
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .left
  
    let messageText = NSMutableAttributedString(
      string: "\n🤳 Move around and you'll see planes indicated by translucent platforms\n\n👉 Tap the platforms to place busts onto them!\n",
      attributes: [
        NSAttributedStringKey.paragraphStyle: paragraphStyle,
        NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: .callout),
        NSAttributedStringKey.foregroundColor : UIColor.black
      ]
    )
  
    let alert = UIAlertController(
      title: "Four Kitchens + ARKit",
      message: "",
      preferredStyle: .alert
    )
    alert.setValue(
      messageText,
      forKey: "attributedMessage"
    )
    alert.addAction(
      UIAlertAction(
        title: "Neato! 👌",
        style: .default
      )
    )
  
    present(
      alert,
      animated: true,
      completion: nil
    )
  }
  
  // Add a bust to the world
  func addBust(_ coordinates: SCNVector3) {
    let node = SCNNode()
    node.position = SCNVector3(
      x: coordinates.x,
      y: coordinates.y + 0.25,
      z: coordinates.z
    )
    let constraint = SCNLookAtConstraint(target: sceneView.pointOfView)
    constraint.localFront = SCNVector3(0, 0, 1)
    constraint.isGimbalLockEnabled = true
    node.constraints = [constraint]
    
    DispatchQueue.global().async {
      let destination: DownloadRequest.DownloadFileDestination = { _, _ in
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("myVase.obj")
        return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
      }
      
      Alamofire.download(URL(string: "https://flipactual.github.io/web-obj/model_mesh.obj")!, to: destination).response { response in
        if response.error == nil, let filePath = response.destinationURL?.path {
          let myUrl = "file://" + filePath
          
          let asset = MDLAsset(url: URL(string: myUrl)!)
          DispatchQueue.main.async {
            asset.loadTextures()
            let scene = SCNScene(mdlAsset: asset)
            let nodeArray = scene.rootNode.childNodes
            
            for childNode in nodeArray {
              node.addChildNode(childNode as SCNNode)
            }
            
            self.sceneView.scene.rootNode.addChildNode(node)
          }
        }
      }
    }
  }
  
  @objc
  func handleTap(_ gestureRecognize: UIGestureRecognizer) {
    let location = gestureRecognize.location(in: view)
    if location.y > view.frame.height - 50 {
      return
    }
    if let result = sceneView.hitTest(location, options: [:]).first {
      addBust(result.worldCoordinates)
    }
  }
}
