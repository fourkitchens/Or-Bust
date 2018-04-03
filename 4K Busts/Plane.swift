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
  
  var material: SCNMaterial!
  
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
    material.locksAmbientWithDiffuse = true
    plane.geometry!.firstMaterial = material
    planeGeometry = plane.geometry as? SCNPlane
    
    self.show()
  
    addChildNode(plane)
  }
  
  func hide() {
    material.diffuse.contents = UIColor.clear
  }
  
  func show() {
    material.diffuse.contents = UIColor(hue: 0.58, saturation: 0.52, brightness: 0.86, alpha: 0.9)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  // Adjust the dimensions of the representation of the plane based on new information
  func update(anchor: ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x)
    planeGeometry.height = CGFloat(anchor.extent.z)
  
    position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
  }
}



