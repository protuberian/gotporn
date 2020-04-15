//
//  AuthViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import Combine

class AuthViewController: UIViewController {
    
    @IBOutlet var login: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var button: UIButton!
    
    @IBOutlet var captchaView: UIView!
    @IBOutlet var captchaImageView: UIImageView!
    @IBOutlet var captchaField: UITextField!
    
    private let completion: () -> Void
    
    private var bag: [AnyCancellable] = []
    private var captchaSid: String?
    
    init?(coder: NSCoder, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: completion:)")
    }
    
    deinit {
        print("deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.isEnabled = false
        captchaView.translatesAutoresizingMaskIntoConstraints = false
        
        let hasLogin = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: login)
            .map { ($0.object as? UITextField)?.text?.count ?? 0 > 0 }
        
        let hasPassword = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: password)
            .map { ($0.object as? UITextField)?.text?.count ?? 0 > 0 }
        
        hasLogin.combineLatest(hasPassword)
            .map { $0 && $1 }
            .assign(to: \.isEnabled, on: button)
            .store(in: &bag)
    }
    
    func didReceiveError(_ error: Error) {
        guard case AuthError.captchaNeeded(let sid, let img) = error else {
            handleError(error)
            return
        }
        
        captchaSid = sid
        
        view.addSubview(captchaView)
        captchaView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        captchaView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        captchaView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        captchaView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        captchaImageView.image = nil
        captchaField.text = nil
        
        api.getImage(url: img) { [weak self] image in
            self?.captchaImageView.image = image
        }
    }
    
    private func signIn(captcha: (String, String)? = nil) {
        view.isUserInteractionEnabled = false
        api.signIn(login: login.text!, password: password.text!) { [weak self] result in
            DispatchQueue.main.async {
                self?.view.isUserInteractionEnabled = true
                switch result {
                case .failure(let error):
                    self?.didReceiveError(error)
                case .success:
                    self?.completion()
                }
            }
        }
    }
    
    @IBAction func signInButtonTap(_ sender: Any) -> Void {
        view.endEditing(false)
        signIn()
    }
    
    @IBAction func confirmCaptchaTap(_ sender: Any) {
        captchaView.removeFromSuperview()
        guard let text = captchaField.text, let sid = captchaSid else {
            handleError("impossibru")
            return
        }
        signIn(captcha: (sid, text))
    }
    
    @IBAction func cancelCaptcha(_ sender: Any) {
        captchaView.removeFromSuperview()
    }
}
