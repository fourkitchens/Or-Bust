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

class ViewController: UIViewController, ARSCNViewDelegate, PickerDelegate, ToolbarDelegate, SCNPhysicsContactDelegate {
  @IBOutlet var sceneView: ARSCNView!
  
  // Hide the status bar
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  // Keep track of the planes
  var planes: [UUID:Plane] = [:]
  
  // Add planes
  internal func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    if let planeAnchor = anchor as? ARPlaneAnchor {
      planes[planeAnchor.identifier] = Plane(with: planeAnchor)
      node.addChildNode(planes[planeAnchor.identifier]!)
      if ((self.bust) != nil) {
        planes[planeAnchor.identifier]?.hide()
      }
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
  
  var toolbar: Toolbar?
  var alert: UIAlertController?
  var picker: Picker?
  
  var objURL: URL?
  var mtlURL: URL?
  var jpgURL: URL?

  var busts: [Bust] = []
  var bust: Bust?
  var node: SCNNode?
  
  var isPhysicsEnabled: Bool = false
  
  var targetCoordinates: SCNVector3?

  override func viewDidLoad() {
    super.viewDidLoad()
  
    // Setup the scene
    sceneView.delegate = self
    sceneView.showsStatistics = false
    sceneView.autoenablesDefaultLighting = true
    sceneView.scene = SCNScene()
  
    // Make the world fancier
    sceneView.pointOfView?.camera?.wantsHDR = true
    
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
    presentWelcomeAlert()
  }
  
  // Fetch data from API
  func fetchData(_: UIAlertAction) -> Void {
    showLoadingIndicator(message: "Fetching data...")
    Alamofire.request("https://us-central1-buster-198623.cloudfunctions.net/getBusts").responseJSON { response in
      if let array = response.result.value as? NSArray {
        self.busts = array.map {
          return Bust(json: $0 as! [String : Any])!
        }
      }
      self.alert?.dismiss(animated: true, completion: nil)
    }
  }
  
  // Show welcome prompt
  func presentWelcomeAlert() {
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
        style: .default,
        handler: fetchData
      )
    )
    
    present(
      alert,
      animated: true,
      completion: nil
    )
  }
  
  func showLoadingIndicator(message: String) {
    alert = UIAlertController(
      title: nil,
      message: message,
      preferredStyle: .alert
    )

    let loadingIndicator = UIActivityIndicatorView(
      frame: CGRect(
        x: 10,
        y: 5,
        width: 50,
        height: 50
      )
    )
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
    loadingIndicator.startAnimating();
    alert?.view.addSubview(loadingIndicator)

    present(
      alert!,
      animated: true,
      completion: nil
    )
  }
  
  func showPicker() {
    picker = Picker(
      options: self.busts,
      viewFrame: view.frame,
      delegate: self
    )
    self.view.addSubview(picker!.pickerWrapper)
  }
  
  func dismissPicker() {
     picker!.pickerWrapper.resignFirstResponder()
  }
  
  func handlePicked() {
    dismissPicker()
    
    if((picker?.selectedOption) != nil) {
      self.bust = picker?.selectedOption
    } else {
      self.bust = self.busts[0]
    }
    
    addBust()
  }
  
  // Add a bust to the world
  func addBust() {
    showLoadingIndicator(message: "Loading bust...")
    
    let assetDownloadsGroup = DispatchGroup()
    
    assetDownloadsGroup.enter()
    Alamofire.download(URL(string: (bust?.model.url)!)!, to: getDestination(name: "model_mesh.obj")).response { response in
      self.objURL = response.destinationURL!
      assetDownloadsGroup.leave()
    }
    
    assetDownloadsGroup.enter()
    Alamofire.download(URL(string: (bust?.material.url)!)!, to: getDestination(name: "model_mesh.obj.mtl")).response { response in
      self.mtlURL = response.destinationURL!
      assetDownloadsGroup.leave()
    }
    
    assetDownloadsGroup.enter()
    Alamofire.download(URL(string: (bust?.texture.url)!)!, to: getDestination(name: "model_texture.jpg")).response { response in
      self.jpgURL = response.destinationURL!
      assetDownloadsGroup.leave()
    }
    
    assetDownloadsGroup.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
      DispatchQueue.global().async {
        let asset = MDLAsset(url: self.objURL!)
        DispatchQueue.main.async {
          asset.loadTextures()

          let scene = SCNScene(mdlAsset: asset)
          let mdlNode = scene.rootNode.childNodes.first
          
          self.node = SCNNode()
          self.node?.position = SCNVector3(
            x: self.targetCoordinates!.x,
            y: self.targetCoordinates!.y + 0.25,
            z: self.targetCoordinates!.z
          )
          self.node?.scale = SCNVector3(
            0.75,
            0.75,
            0.75
          )
          self.node?.eulerAngles = SCNVector3Make(
            0,
            (self.sceneView.session.currentFrame?.camera.eulerAngles.y)!,
            0
          )
          
          if (self.isPhysicsEnabled) {
            // Do physics to the bust
            self.node?.physicsBody = SCNPhysicsBody(
              type: .dynamic,
              shape: SCNPhysicsShape(
                geometry: (mdlNode!.geometry!),
                options: nil
              )
            )
            self.node?.physicsBody!.friction = 1.0
          }
          
          self.node?.addChildNode(mdlNode!)
          
          self.sceneView.scene.rootNode.addChildNode(self.node!)
          
          self.planes.forEach { $0.value.hide() }
          self.alert?.dismiss(animated: true, completion: nil)
          self.showToolbar()
        }
      }
    }))
  }
  
  func showToolbar() {
    toolbar = Toolbar(
      parentView: view,
      delegate: self
    )
    
    guard let toolbar = toolbar else {
      return
    }
    
    // This really should just be toolbar, but when adding the UIToolbar as a subview on Toolbar, constraints got wacky
    // I probably just don't understand constraints
    view.addSubview(toolbar.toolbar)
    toolbar.setConstraints(parentView: view)
  }
  
  @objc func reset() {
    bust = nil
    self.planes.forEach { $0.value.show() }
    toolbar!.toolbar.removeFromSuperview()
    node!.removeFromParentNode()
  }
  
  @objc
  func handleTap(_ gestureRecognize: UIGestureRecognizer) {
    let location = gestureRecognize.location(in: view)
    // Avoid trying to place a bust when the tap location hits the toolbar
    if location.y > view.frame.height - (view.safeAreaInsets.bottom + 44) {
      return
    }
    if let result = sceneView.hitTest(location, options: [:]).first {
      if (!(bust != nil)) {
        self.targetCoordinates = result.worldCoordinates
        showPicker()
      }
    }
  }
}
