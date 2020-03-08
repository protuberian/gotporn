//
//  ApiManager.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import VK_ios_sdk
import CoreData
import UIKit

class ApiManager: NSObject {
    
    var authorized: Bool {
        return VKSdk.accessToken() != nil
    }
    
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    
    private var signInCompletion: ((Bool) -> Void)?
    
    override init() {
        super.init()
        VKSdk.initialize(withAppId: "7348606")
        VKSdk.instance()?.register(self)
        
        URLCache.shared = URLCache(memoryCapacity: 512*1024*1024, diskCapacity: 512*1024*1024)
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
    
    func search(parameters: SearchParameters) {
        db.save({ context in
            let request: NSFetchRequest<Video> = Video.fetchRequest()
            db.fetch(request, inContext: context).forEach { context.delete($0) }
            
        }, completion: { _ in
            let request = VKRequest(method: "video.search", parameters: self.mapSearchParameters(parameters))
            request?.execute(resultBlock: { response in
                guard
                    let data = response?.responseString.data(using: .utf8),
                    let result = SearchResult(response: data)
                else {
                    print("error mapping response")
                    return
                }
                
                let titles = result.videos.map {$0.title}
                print(titles)
                
                
                db.save { context in
                    
                    for (index, dto) in result.videos.enumerated() {
                        let request: NSFetchRequest<Video> = Video.fetchRequest()
                        request.predicate = NSPredicate(format: "id = %@", NSNumber(value: dto.id))
                        let video = db.fetch(request, inContext: context).first ?? Video(context: context)
                        video.id = Int64(dto.id)
                        video.sortIndex = Int64(index + 0*0)
                        video.title = dto.title
                        video.duration = Int64(dto.duration)
                        video.accessKey = dto.accessKey
                        video.photo320 = dto.photo320
                    }
                }
                
            }, errorBlock: { error in
                print(error)
            })
        })
    }
    
    private func mapSearchParameters(_ parameters: SearchParameters) -> [AnyHashable: Any] {
        return ["q": parameters.query]
    }
    
    func getImage(url: URL, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            
            var image: UIImage?
            if let data = data {
                image = UIImage(data: data)
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.resume()
        return task
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
