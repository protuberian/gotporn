//
//  SettingsViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import VK_ios_sdk

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func buttonLogoutTap(_ sender: Any) {
        VKSdk.forceLogout()
    }
}
