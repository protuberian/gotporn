//
//  AuthViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import VK_ios_sdk

class AuthViewController: UIViewController {

    private let completion: () -> Void
    
    init?(coder: NSCoder, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: completion:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VKSdk.instance()?.uiDelegate = self
    }
    
    @IBAction func signInButtonTap(_ sender: Any) {
        api.signIn { [weak self] success in
            if success {
                self?.completion()
            } else {
                print("authentication failed")
            }
        }
    }
    
}

extension AuthViewController: VKSdkUIDelegate {
    func vkSdkShouldPresent(_ controller: UIViewController) {
        present(controller, animated: true, completion: nil)
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError) {
        print(#function)
    }
}
