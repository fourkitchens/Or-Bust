//
//  Bust.swift
//  4K Busts
//
//  Created by Flip on 3/23/18.
//  Copyright © 2018 Four Kitchens. All rights reserved.
//

import Foundation

struct FileReference {
  let filename: String
  let url: String
}

struct Bust {
  let name: String
  let flavor: String
  let model: FileReference
  let material: FileReference
  let texture: FileReference
}

extension Bust {
  init?(json: [String: Any]) {
    guard let name = json["name"] as? String,
      let flavor = json["flavor"] as? String,
      let model = json["model"] as? [String: String],
      let material = json["material"] as? [String: String],
      let texture = json["texture"] as? [String: String]
    else {
      return nil
    }
    
    self.name = name
    self.flavor = flavor
    self.model = FileReference(filename: model["filename"]!, url: model["url"]!)
    self.material = FileReference(filename: material["filename"]!, url: material["url"]!)
    self.texture = FileReference(filename: texture["filename"]!, url: texture["url"]!)
  }
}
