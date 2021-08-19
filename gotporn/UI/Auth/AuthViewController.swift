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
    
    // MARK: - UI Elements
    @IBOutlet var loginField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var button: UIButton!
    
    @IBOutlet var captchaView: UIView!
    @IBOutlet var captchaImageView: UIImageView!
    @IBOutlet var captchaField: UITextField!
    
    // MARK: - Properties
    private let completion: () -> Void
    private var bag: [AnyCancellable] = []
    
    @Published private var login: String = ""
    @Published private var password: String = ""
    private var captchaSid: String?
    
    // MARK: - Init
    init?(coder: NSCoder, completion: @escaping () -> Void) {
        self.completion = completion
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: completion:)")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        captchaView.translatesAutoresizingMaskIntoConstraints = false
        addSecurePasswordTFToggle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindUI()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bag.removeAll()
    }
    
    // MARK: - Add secure password TF toggle
    private func addSecurePasswordTFToggle() {
        passwordField.enablePasswordToggle()
    }
    
    // MARK: - Bind UI
    private func bindUI() {
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: loginField).map {
            ($0.object as? UITextField)?.text ?? ""
        }
        .assign(to: \.login, on: self)
        .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: passwordField).map {
            ($0.object as? UITextField)?.text ?? ""
        }
        .assign(to: \.password, on: self)
        .store(in: &bag)
        
        Publishers.CombineLatest($login, $password).map {
            return $0.0.count > 0 && $0.1.count > 0
        }
        .assign(to: \.isEnabled, on: button)
        .store(in: &bag)
        
        NotificationCenter.default.publisher(for: UIControl.keyboardWillChangeFrameNotification).compactMap {
            $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        }
        .sink { [unowned self] rect in
            let kbFrame = self.view.convert(rect, from: UIScreen.main.coordinateSpace)
            let overlap = self.view.frame.inset(by: self.view.safeAreaInsets).maxY + self.additionalSafeAreaInsets.bottom - kbFrame.minY
            
            self.additionalSafeAreaInsets.bottom = max(0, overlap)
            self.view.layoutIfNeeded()
        }
        .store(in: &bag)
    }
    
    // MARK: - Error handlers
    func didReceiveError(_ error: Error) {
        
        if case AuthError.needValidation( _, _, _, let validationType) = error {
            
            var messageString = ""
            let commonMessageString = NSLocalizedString(". Enter it in the field below", comment: "common message confirmation alert")
            if validationType.contains("2fa_app") {
                messageString = NSLocalizedString("You have been sent a confirmation code in the VK app", comment: "2fa app message confirmation alert")
            } else if validationType.contains("2fa_sms") {
                messageString = NSLocalizedString("An SMS was sent to you with a confirmation code", comment: "2fa sms message confirmation alert")
            } else {
                messageString = NSLocalizedString("A confirmation code has been sent to you", comment: "2fa message confirmation alert")
            }
            
            let alertController = UIAlertController(title: NSLocalizedString("Two-factor authentification", comment: "two-auth confirmation title alert"), message: messageString + commonMessageString, preferredStyle: .alert)
            alertController.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("Validation code", comment: "2fa confirmation alert text field placeholder")
                textField.textContentType = .oneTimeCode
                textField.keyboardType = .numberPad
            }
            let cancelButton = UIAlertAction(title: NSLocalizedString("Cancel", comment: "2fa confirmation alert action cancel"), style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: NSLocalizedString("Done", comment: "2fa confirmation alert action done"), style: .default) { [weak self] _ in
                let codeTextField = alertController.textFields![0] as UITextField
                self?.signIn(validationCode: codeTextField.text)
            }
            
            alertController.addAction(cancelButton)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
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
    
    // MARK: - Auth logic
    private func signIn(captcha: (String, String)? = nil, validationCode: String? = nil) {
        view.isUserInteractionEnabled = false
        api.signIn(login: login, password: password, captcha: captcha, validationCode: validationCode) { [weak self] result in
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
        captchaSid = nil
    }
}
