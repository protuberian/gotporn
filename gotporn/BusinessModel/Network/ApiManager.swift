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
        VKSdk.initialize(withAppId: "7348606", apiVersion: "5.103")
//        VKSdk.initialize(withAppId: "3140623")
        VKSdk.instance()?.register(self)

//        URLCache.shared = URLCache(memoryCapacity: 512*1024*1024, diskCapacity: 512*1024*1024)
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
    
//    func search(parameters: SearchParameters) {
//        db.save({ context in
//            let request: NSFetchRequest<Video> = Video.fetchRequest()
//            db.fetch(request, inContext: context).forEach { context.delete($0) }
//        }, completion: { _ in
//
//            var components = URLComponents()
//            components.scheme = "https"
//            components.host = "api.vk.com"
//            components.path = "/method/video.search"
//            components.queryItems = self.mapSearchParameters(parameters)
//
//            let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
//            print(request)
//
//
//            let task = self.urlSession.dataTask(with: request) { (data, response, error) in
//                guard
//                    let data = data,
//                    let result = SearchResult(response: data)
//                    else {
//                        print("error mapping response")
//                        return
//                }
//
//                let titles = result.videos.map {$0.title}
//                print(titles)
//
//
//                db.save { context in
//
//                    for (index, dto) in result.videos.enumerated() {
//                        let request: NSFetchRequest<Video> = Video.fetchRequest()
//                        request.predicate = NSPredicate(format: "id = %@", NSNumber(value: dto.id))
//                        let video = db.fetch(request, inContext: context).first ?? Video(context: context)
//                        video.id = Int64(dto.id)
//                        video.sortIndex = Int64(index + 0*0)
//                        video.title = dto.title
//                        video.duration = Int64(dto.duration)
//                        video.accessKey = dto.accessKey
//                        video.photo320 = dto.thumb
//                    }
//                }
//
//            }
//
//            task.resume()
//        })
//    }
    
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
                        if dto.contentRestricted == 1 {
                            continue
                        }
                        let request: NSFetchRequest<Video> = Video.fetchRequest()
                        request.predicate = NSPredicate(format: "id = %@", NSNumber(value: dto.id))
                        let video = db.fetch(request, inContext: context).first ?? Video(context: context)
                        video.id = Int64(dto.id)
                        video.ownerId = Int64(dto.ownerId)
                        video.sortIndex = Int64(index + Int(parameters.offset))
                        video.title = dto.title
                        video.duration = Int64(dto.duration)
                        video.accessKey = dto.accessKey
                        video.photo320 = dto.thumb
                        video.player = dto.player
                    }
                }
                
            }, errorBlock: { error in
                print(error)
            })
        })
    }
    
    private func mapSearchParameters(_ parameters: SearchParameters) -> [AnyHashable: Any] {
        return [
            "q": parameters.query,
            "adult": "1"
        ]
    }
    
//    private func mapSearchParameters(_ parameters: SearchParameters) -> [URLQueryItem] {
//        return [
//            URLQueryItem(name: "v", value: "5.103"),
//            URLQueryItem(name: "q", value: parameters.query),
//            URLQueryItem(name: "sort", value: "2"),
//            URLQueryItem(name: "hd", value: "1"),
//            URLQueryItem(name: "adult", value: "1"),
//            URLQueryItem(name: "filters", value: "mp4,long"),
//            URLQueryItem(name: "search_own", value: "0"),
//            URLQueryItem(name: "offset", value: String(parameters.offset)),
//            URLQueryItem(name: "longer", value: "30"),
//            URLQueryItem(name: "shorter", value: "3600"),
//            URLQueryItem(name: "count", value: String(min(200, parameters.count))),
//            URLQueryItem(name: "extended", value: "1")
//        ]
//    }
    
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
