//
//  ApiManager.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import VK_ios_sdk

class ApiManager: NSObject {
    
    var authorized: Bool {
        return VKSdk.accessToken() != nil
    }
    
    private var signInCompletion: ((Bool) -> Void)?
    
    override init() {
        super.init()
        VKSdk.initialize(withAppId: "7348606")
        VKSdk.instance()?.register(self)
    }
    
    func signIn(completion: @escaping (Bool) -> Void) {
        
        signInCompletion = { result in
            completion(result)
            self.signInCompletion = nil
        }
        
        VKSdk.authorize(["video"])
    }
    
    func wakeUpSession(completion: @escaping (Bool) -> Void) {
        VKSdk.wakeUpSession(["video"]) { (state, error) in
            if case .authorized = state {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}

enum Result<T> {
    case success(T)
    case failure(Error)
}

extension ApiManager: VKSdkDelegate {
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult) {
        print(#function)
    }
    
    func vkSdkUserAuthorizationFailed() {
        print(#function)
        signInCompletion?(false)
    }
    
    func vkSdkTokenHasExpired(_ expiredToken: VKAccessToken) {
        print(#function)
    }
    
    func vkSdkAuthorizationStateUpdated(with result: VKAuthorizationResult) {
        signInCompletion?(result.state == .authorized)
        print(#function)
    }
    
    func vkSdkAccessTokenUpdated(_ newToken: VKAccessToken?, oldToken: VKAccessToken?) {
        print(#function)
        print(newToken?.accessToken)
        print(oldToken?.accessToken)
    }
}
