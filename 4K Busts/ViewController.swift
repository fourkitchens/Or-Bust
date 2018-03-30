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

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
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
  
  var toolBar: UIToolbar?
  var alert: UIAlertController?
  var pickerWrapper: UITextField!
  var picker: UIPickerView!
  
  var objURL: URL?
  var mtlURL: URL?
  var jpgURL: URL?
  
  var busts: [Bust] = []
  var bust: Bust?
  var node: SCNNode?
  var textNode: SCNNode?
  
  var targetCoordinates: SCNVector3?
  var worldTransform: SCNMatrix4?
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    // Setup the scene
    sceneView.delegate = self
    sceneView.showsStatistics = false
    sceneView.autoenablesDefaultLighting = true
    sceneView.scene = SCNScene()
  
    // Make the world fancier
    sceneView.scene.lightingEnvironment.contents = SCNMaterial.LightingModel.physicallyBased
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
  
  // fetch data from API
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

    present(alert!, animated: true, completion: nil)
  }
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1;
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return busts.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return busts[row].name
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    bust = busts[row]
  }
  
  func showPicker() {
    pickerWrapper = UITextField(
      frame: CGRect(
        x: 0,
        y: 0,
        width: 0,
        height: 0
      )
    )
    
    picker = UIPickerView(
      frame: CGRect(
        x: 0,
        y: 0,
        width: view.frame.width,
        height: view.frame.height / 3
      )
    )
    picker.autoresizingMask = .flexibleHeight
    picker.showsSelectionIndicator = true
    picker.delegate = self as UIPickerViewDelegate
    picker.dataSource = self as UIPickerViewDataSource
    
    let toolBar = UIToolbar(
      frame: CGRect(
        x: 0,
        y: 0,
        width: view.frame.width,
        height: 500
      )
    )
    toolBar.barStyle = UIBarStyle.default
    toolBar.isTranslucent = true
    toolBar.sizeToFit()
    
    let doneButton = UIBarButtonItem(title: "Okay!", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.handlePicked))
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
    let cancelButton = UIBarButtonItem(title: "Oops...", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.dismissPicker))
    
    toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
    toolBar.isUserInteractionEnabled = true
    
    pickerWrapper.inputView = picker
    pickerWrapper.inputAccessoryView = toolBar
    pickerWrapper.becomeFirstResponder()
    
    picker.backgroundColor = .clear
    let blurEffect = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    picker.insertSubview(blurView, at: 0)
    
    self.view.addSubview(pickerWrapper)
  }
  
  @objc func dismissPicker() {
    pickerWrapper.resignFirstResponder()
  }
  
  @objc func handlePicked() {
    dismissPicker()
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
          let nodeArray = scene.rootNode.childNodes
          
          self.node = SCNNode()
          self.node?.position = SCNVector3(
            x: self.targetCoordinates!.x,
            y: self.targetCoordinates!.y + 0.25,
            z: self.targetCoordinates!.z
          )
          
          let constraint = SCNLookAtConstraint(target: self.sceneView.pointOfView)
          constraint.localFront = SCNVector3(0, 0, 1)
          constraint.isGimbalLockEnabled = true
          
          // Keep bust facing camera
          self.node?.constraints = [constraint]
          
          for childNode in nodeArray {
            self.node?.addChildNode(childNode as SCNNode)
          }
          
          let text = SCNText(string: "Hello, world!", extrusionDepth: 0)
          text.font = UIFont(name: "Helvetica", size: 32)
          let material = SCNMaterial()
          material.diffuse.contents = UIColor(
            hue: 0.36,
            saturation: 0.63,
            brightness: 0.82,
            alpha: 0.9
          )
          material.locksAmbientWithDiffuse = true
          text.firstMaterial = material
          text.flatness = 1

          self.textNode = SCNNode(geometry: text)
          self.textNode?.position = SCNVector3(
            x: self.targetCoordinates!.x - 0.2,
            y: self.targetCoordinates!.y + 0.65,
            z: self.targetCoordinates!.z + 0.25
          )
          self.textNode?.scale = SCNVector3(0.0025, 0.0025, 0.0025)
          // Keep text facing camera
          self.textNode?.constraints = [constraint]
          
          self.sceneView.scene.rootNode.addChildNode(self.node!)
          self.sceneView.scene.rootNode.addChildNode(self.textNode!)
          
          self.planes.forEach { $0.value.hide() }
          self.alert?.dismiss(animated: true, completion: nil)
          self.showToolbar()
        }
      }
    }))
  }
  
  func showToolbar() {
    toolBar = UIToolbar(
      frame: CGRect(
        origin: CGPoint(
          x: 0,
          y: view.frame.height - view.safeAreaInsets.bottom - 44
        ),
        size: CGSize(
          width: view.frame.width,
          height: view.safeAreaInsets.bottom + 44
        )
      )
    )
    toolBar?.barStyle = UIBarStyle.default
    toolBar?.isTranslucent = true
    toolBar?.sizeToFit()
    
    let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
    let resetButton = UIBarButtonItem(title: "Reset!", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.reset))
    
    toolBar?.setItems([spaceButton, resetButton, spaceButton], animated: false)
    toolBar?.isUserInteractionEnabled = true
    view.addSubview(toolBar!)
  }
  
  @objc func reset() {
    bust = nil
    self.planes.forEach { $0.value.show() }
    toolBar!.removeFromSuperview()
    node!.removeFromParentNode()
    textNode!.removeFromParentNode()
  }
  
  @objc
  func handleTap(_ gestureRecognize: UIGestureRecognizer) {
    let location = gestureRecognize.location(in: view)
    if location.y > view.frame.height - 50 {
      return
    }
    if let result = sceneView.hitTest(location, options: [:]).first {
      if (!(bust != nil)) {
        self.worldTransform = result.modelTransform
        self.targetCoordinates = result.worldCoordinates
        self.bust = busts[0]
        showPicker()
      }
    }
  }
}
