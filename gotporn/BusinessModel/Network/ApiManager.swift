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
        
        VKSdk.wakeUpSession(["video"]) { (state, error) in
            switch state {
                
            case .authorized:
                self.signInCompletion?(true)
                
            case .initialized:
                VKSdk.authorize(["video"])
                
            default:
                fatalError("unhandled VKSdk session state: \(state)")
            }
        }
    }
}

enum Result<T> {
    case success(T)
    case failure(Error)
}

extension ApiManager: VKSdkDelegate {
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        print(#function)
    }
    
    func vkSdkUserAuthorizationFailed() {
        print(#function)
    }
    
    func vkSdkTokenHasExpired(_ expiredToken: VKAccessToken!) {
        print(#function)
    }
    
    func vkSdkAuthorizationStateUpdated(with result: VKAuthorizationResult!) {
        print(#function)
    }
    
    func vkSdkAccessTokenUpdated(_ newToken: VKAccessToken?, oldToken: VKAccessToken?) {
        print(#function)
        print(newToken?.accessToken)
        print(oldToken?.accessToken)
    }
}
