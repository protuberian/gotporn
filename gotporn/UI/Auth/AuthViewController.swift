//
//  AuthViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController {

    @IBOutlet var login: UITextField!
    @IBOutlet var password: UITextField!
    
    private let completion: () -> Void
    
    init?(coder: NSCoder, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: completion:)")
    }
    
    @IBAction func signInButtonTap(_ sender: Any) {
        api.signIn(login: login.text!, password: password.text!) { [weak self] success in
            if success {
                self?.completion()
            } else {
                print("authentication failed")
            }
        }
    }
}
