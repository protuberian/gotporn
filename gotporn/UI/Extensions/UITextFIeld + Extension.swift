//
//  UITextFIeld + Extension.swift
//  gotporn
//
//  Created by Руслан Садыков on 20.08.2021.
//  Copyright © 2021 kimdenis. All rights reserved.
//

import UIKit

extension UITextField {
    fileprivate func setPasswordToggleImage(_ button: UIButton) {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 12)
        if isSecureTextEntry {
            button.setImage(UIImage(systemName: "eye", withConfiguration: iconConfig), for: UIControl.State())
        }else{
            button.setImage(UIImage(systemName: "eye.slash", withConfiguration: iconConfig), for: UIControl.State())
        }
    }
    
    func enablePasswordToggle() {
        let button = UIButton(type: .custom)
        setPasswordToggleImage(button)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
        button.frame = CGRect(x: CGFloat(self.frame.size.width - 25), y: CGFloat(5), width: CGFloat(25), height: CGFloat(25))
        button.addTarget(self, action: #selector(self.togglePasswordView), for: .touchUpInside)
        self.rightView = button
        self.rightViewMode = .always
    }
    
    @IBAction func togglePasswordView(_ sender: Any) {
        self.isSecureTextEntry = !self.isSecureTextEntry
        setPasswordToggleImage(sender as! UIButton)
    }
}
