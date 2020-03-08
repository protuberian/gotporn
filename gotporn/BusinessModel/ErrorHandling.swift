//
//  ErrorHandling.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation

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
}

struct CustomError: LocalizedError {
    
    let errorDescription: String?
    
    init(location: String, body: String) {
        errorDescription = location + " -> " + body
    }
}
