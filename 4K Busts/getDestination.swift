//
//  getDestination.swift
//  4K Busts
//
//  Created by Flip on 3/19/18.
//  Copyright © 2018 Four Kitchens. All rights reserved.
//

import Foundation
import Alamofire

func getDestination(name: String) -> DownloadRequest.DownloadFileDestination {
  return { _, _ in
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsURL.appendingPathComponent(name)
    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
  }
}
