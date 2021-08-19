//
//  ErrorHandling.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import UIKit

func location(file: String = #file, function: String = #function, line: Int = #line) -> String {
    let path = file.components(separatedBy: "/")
    guard path.count > 2 else {
        return "\(file):\(line) \(function)"
    }
    
    let croppedPath = path[(path.count-2)...].joined(separator: "/")
    return "\(croppedPath):\(line) \(function)"
}

func handleError(file: String = #file, function: String = #function, line: Int = #line, _ errorText: String) {
    handleError(CustomError(location: location(file: file, function: function, line: line), body: errorText))
}

func handleError(_ error: Error) {
    print(error.localizedDescription)
    
    DispatchQueue.main.async {
        let vc = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        let viewController = UIApplication.shared.windows.first?.rootViewController
        viewController?.present(vc, animated: true, completion: nil)
    }
}

struct CustomError: LocalizedError {
    
    let errorDescription: String?
    
    init(location: String, body: String) {
        errorDescription = location + " -> " + body
    }
}
