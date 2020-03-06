//
//  AppCoordinator.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import UIKit
import VK_ios_sdk

class AppCoordinator {
    
    private(set) var root: UIViewController
    
    init() {
        let vc: UIViewController
        
        if api.authorized {
            fatalError("not implemented")
        } else {
            vc = UIStoryboard(name: "Auth", bundle: nil).instantiateInitialViewController()!
        }
        
        root = vc
    }
}
