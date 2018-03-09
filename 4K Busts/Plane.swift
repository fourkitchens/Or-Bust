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
  var planeGeometry: SCNBox!
  
  init(with anchor: ARPlaneAnchor) {
    super.init()
  
    self.anchor = anchor
    let planeHeight = CGFloat(0.01)
  
    // Create the plane
    let plane = SCNNode(geometry: SCNBox(width: CGFloat(anchor.extent.x), height: planeHeight, length: CGFloat(anchor.extent.z), chamferRadius: 0))
    plane.position = SCNVector3Make(0, 0, 0)
  
    // Decorate the plane
    plane.geometry!.firstMaterial!.diffuse.contents = UIColor(
      hue: 0.31,
      saturation: 0.57,
      brightness: 1.00,
      alpha: 0.75
    )
  
    // Do physics to the plane
    plane.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: plane.geometry!, options: nil))
    plane.physicsBody!.friction = 1.0
  
    planeGeometry = plane.geometry as! SCNBox
  
    addChildNode(plane)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // Adjust the dimensions of the representation of the plane based on new information
  func update(anchor: ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x)
    planeGeometry.length = CGFloat(anchor.extent.z)
  
    position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
  
    let node = childNodes.first!
    node.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
  }
}



