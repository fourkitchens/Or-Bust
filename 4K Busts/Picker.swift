//
//  Picker.swift
//  4K Busts
//
//  Created by Flip on 4/2/18.
//  Copyright © 2018 Four Kitchens. All rights reserved.
//

import Foundation
import UIKit

protocol PickerDelegate {
  func handlePicked()
  func dismissPicker()
}

class Picker: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
  var delegate: PickerDelegate!
  
  var pickerWrapper: UITextField!
  var picker: UIPickerView!
  
  var options: [Bust]!
  var selectedOption: Bust!
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1;
  }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return options.count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return options[row].name
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    selectedOption = options[row]
  }
  
  init(options: [Bust], viewFrame: CGRect, delegate: PickerDelegate) {
    super.init(frame: viewFrame)
    
    // Store options
    self.options = options
    
    // Save delegate
    self.delegate = delegate

    // Create wrapper which will contain the picker and the picker toolbar
    pickerWrapper = UITextField(
      frame: CGRect(
        x: 0,
        y: 0,
        width: 0,
        height: 0
      )
    )
    
    // Create the picker
    picker = UIPickerView(
      frame: CGRect(
        x: 0,
        y: 0,
        width: viewFrame.width,
        height: viewFrame.height / 3
      )
    )
    picker.delegate = self
    picker.autoresizingMask = .flexibleHeight
    picker.showsSelectionIndicator = true
    picker.dataSource = self as UIPickerViewDataSource
    
    // Create the toolbar
    let toolBar = UIToolbar(
      frame: CGRect(
        x: 0,
        y: 0,
        width: viewFrame.width,
        height: 500
      )
    )
    toolBar.barStyle = UIBarStyle.default
    toolBar.isTranslucent = true
    toolBar.sizeToFit()
    
    // Add button to toolbar
    let doneButton = UIBarButtonItem(
      title: "Okay!",
      style: UIBarButtonItemStyle.plain,
      target: self,
      action: #selector(self.handlePicked)
    )
    let spaceButton = UIBarButtonItem(
      barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
      target: nil,
      action: nil
    )
    let cancelButton = UIBarButtonItem(
      title: "Oops...",
      style: UIBarButtonItemStyle.plain,
      target: self,
      action: #selector(self.dismissPicker)
    )
    
    toolBar.setItems(
      [cancelButton, spaceButton, doneButton],
      animated: false
    )
    toolBar.isUserInteractionEnabled = true
    
    pickerWrapper.inputView = picker
    pickerWrapper.inputAccessoryView = toolBar
    pickerWrapper.becomeFirstResponder()
    
    picker.backgroundColor = .clear
    let blurEffect = UIBlurEffect(style: .light)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.translatesAutoresizingMaskIntoConstraints = false
    picker.insertSubview(blurView, at: 0)
  }
  
  @objc func handlePicked() {
    delegate.handlePicked()
  }
  
  @objc func dismissPicker() {
    delegate.dismissPicker()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
