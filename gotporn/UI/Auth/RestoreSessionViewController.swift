//
//  RestoreSessionViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

class RestoreSessionViewController: UIViewController {
    
    private let completion: (Bool) -> Void
    
    init?(coder: NSCoder, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init(coder: completion:)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        completion(api.authorized)
//        completion(false)
    }
}
