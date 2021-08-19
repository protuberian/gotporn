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

struct AuthResponseCaptchaNeeded: Codable {
    enum Error: String, Codable {
        case needCaptcha = "need_captcha"
    }
    
    let error: Error
    let captchaSid: String
    let captchaImage: URL
    
    enum CodingKeys: String, CodingKey {
        case error
        case captchaSid = "captcha_sid"
        case captchaImage = "captcha_img"
    }
}
enum AuthError: Error {
    case captchaNeeded(sid: String, img: URL)
    case needValidation(sid: String, redirectUrl: URL, phoneMask: String, validationType: String)
}

struct AuthResponse2FAAuthNeeded: Codable {
    enum Error: String, Codable {
        case needValidation = "need_validation"
    }
    
    let error: Error
    let validationSid: String
    let phoneMask: String
    let redirectUri: URL
    let validationType: String
    
    enum CodingKeys: String, CodingKey {
        case error
        case validationSid = "validation_sid"
        case phoneMask = "phone_mask"
        case redirectUri = "redirect_uri"
        case validationType = "validation_type"
    }
}
