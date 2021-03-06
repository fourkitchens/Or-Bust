//
//  Plane.swift
//  4K Busts
//
//  Created by Flip on 7/19/17.
//  Copyright © 2017 Flip. All rights reserved.
//

import ARKit
import Foundation

class Plane: SCNNode {
  // The anchor of the detected plane
  var anchor: ARPlaneAnchor!
  
  // The geometry of rendered to represent the plane as a physical object
  var planeGeometry: SCNPlane!
  
  var planePhysicsBody: SCNPhysicsBody!
  
  var material: SCNMaterial!
  var defaultColorBufferWriteMask: SCNColorMask!
  
  init(with anchor: ARPlaneAnchor) {
    super.init()
  
    self.anchor = anchor
  
    // Create the plane
    let plane = SCNNode(
      geometry: SCNPlane(
        width: CGFloat(anchor.extent.x),
        height: CGFloat(anchor.extent.z)
      )
    )
    plane.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
    plane.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
  
    // Decorate the plane
    material = SCNMaterial()
    material.lightingModel = .blinn
    material.locksAmbientWithDiffuse = true
    plane.geometry!.firstMaterial = material
    
    defaultColorBufferWriteMask = material.colorBufferWriteMask
    planeGeometry = plane.geometry as? SCNPlane
    
    // Do physics to the plane
    plane.physicsBody = SCNPhysicsBody(
      type: .kinematic,
      shape: SCNPhysicsShape(
        geometry: plane.geometry!,
        options: nil
      )
    )
    plane.physicsBody!.friction = 1.0
    
    planePhysicsBody = plane.physicsBody
    
    self.show()
  
    addChildNode(plane)
  }
  
  func hide() {
    material.diffuse.contents = UIColor.white
    material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
  }
  
  func show() {
    material.diffuse.contents = UIColor(hue: 0.58, saturation: 0.52, brightness: 0.86, alpha: 0.75)
    material.colorBufferWriteMask = defaultColorBufferWriteMask
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // Adjust the dimensions of the representation of the plane based on new information
  func update(anchor: ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x)
    planeGeometry.height = CGFloat(anchor.extent.z)
    
    planePhysicsBody = SCNPhysicsBody(
      type: .kinematic,
      shape: SCNPhysicsShape(
        geometry: planeGeometry,
        options: nil
      )
    )
  
    position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
  }
}



