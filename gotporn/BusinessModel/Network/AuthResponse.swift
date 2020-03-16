//
//  AuthResponse.swift
//  gotporn
//
//  Created by Denis G. Kim on 16.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}
