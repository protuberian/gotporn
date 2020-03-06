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
    
    private(set) var window: UIWindow
    private let auth = UIStoryboard(name: "Auth", bundle: nil)
    private let main = UIStoryboard(name: "Main", bundle: nil)
    
    init() {
        window = UIWindow(frame: UIScreen.main.bounds)
        _ = api
        requestAuthentication()
        return
        
        let vc = auth.instantiateInitialViewController { coder -> RestoreSessionViewController? in
            return RestoreSessionViewController(coder: coder) { [unowned self] authorized in
                if authorized {
                    self.presentMain()
                } else {
                    self.requestAuthentication()
                }
            }
        }
        window.rootViewController = vc
    }
    
    private func requestAuthentication() {
        let vc = auth.instantiateViewController(identifier: "AuthViewController") { coder -> AuthViewController? in
            return AuthViewController(coder: coder) { [unowned self] in
                self.presentMain()
            }
        }
        
        window.rootViewController = UINavigationController(rootViewController: vc)
    }
    
    private func presentMain() {
        let vc = main.instantiateInitialViewController()
        let currentView = window.rootViewController?.view
        window.rootViewController = vc
        
        if let source = currentView, let target = vc?.view {
            UIView.transition(from: source, to: target, duration: 0.25, options: [], completion: nil)
        }
    }
}
