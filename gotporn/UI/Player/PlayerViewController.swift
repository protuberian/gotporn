//
//  PlayerViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import WebKit

class PlayerViewController: UIViewController, WKNavigationDelegate {
    
    let url: URL
    var webView: WKWebView!
    
    init?(coder: NSCoder, url: URL) {
        self.url = url
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: url:)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("didAppear")
        
        webView = WKWebView(frame: view.frame.inset(by: view.safeAreaInsets))
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        view.addSubview(webView)
    }
    
}
