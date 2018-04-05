//
//  Toolbar.swift
//  Or Bust
//
//  Created by Flip on 4/3/18.
//  Copyright © 2018 Four Kitchens. All rights reserved.
//

import Foundation
import UIKit

protocol ToolbarDelegate {
  func reset()
}

class Toolbar: UIView {
  var delegate: ToolbarDelegate!

  var toolbar: UIToolbar!

  init(parentView: UIView, delegate: ToolbarDelegate) {
    super.init(frame: parentView.frame);

    // Save delegate
    self.delegate = delegate

    self.autoresizesSubviews = true
    self.translatesAutoresizingMaskIntoConstraints = false

    toolbar = UIToolbar(
      frame: CGRect(
        origin: CGPoint(
          x: 0,
          y: 0
        ),
        size: CGSize(
          width: 0,
          height: 0
        )
      )
    )
    toolbar.barStyle = .default
    toolbar.isTranslucent = true
    toolbar.translatesAutoresizingMaskIntoConstraints = false

    let spaceButton = UIBarButtonItem(
      barButtonSystemItem: .flexibleSpace,
      target: nil,
      action: nil
    )
    let resetButton = UIBarButtonItem(
      title: "Reset!",
      style: .plain,
      target: self,
      action: #selector(self.reset)
    )

    toolbar.setItems(
      [spaceButton, resetButton, spaceButton],
      animated: false
    )
    toolbar.isUserInteractionEnabled = true
  }

  func setConstraints(parentView: UIView) {
    NSLayoutConstraint.activate([
      (toolbar.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)),
      (toolbar.leadingAnchor.constraint(equalTo: parentView.leadingAnchor)),
      (toolbar.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)),
      (toolbar.heightAnchor.constraint(equalToConstant: 44))
    ])
  }

  @objc func reset() {
    delegate.reset()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
