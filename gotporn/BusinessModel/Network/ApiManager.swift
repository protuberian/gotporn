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

let token = "token"

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
    
    private var searchInProgress: Bool = false
    private var restricted: Int = 0
    
    func search(parameters: SearchParameters) {
        guard !searchInProgress else { return }
        searchInProgress = true
        
        db.save({ context in
            if parameters.offset == 0 {
                self.restricted = 0
                let request: NSFetchRequest<Video> = Video.fetchRequest()
                db.fetch(request, inContext: context).forEach { context.delete($0) }
            }
        }, completion: { _ in
            self.performSearch(parameters: parameters) {
                self.searchInProgress = false
            }
        })
    
    }
    
    func performSearch(parameters: SearchParameters, completion: @escaping () -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.vk.com"
        components.path = "/method/video.search"
        components.queryItems = queryItems(parameters)

        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        print(request)

        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            completion()
            guard
                let data = data,
                let result = SearchResult(response: data)
                else {
                    print("error mapping response")
                    return
            }

            let titles = result.videos.map {$0.title}
            print("offset: \(parameters.offset)")
            print("restricted: \(self.restricted)")
            print("total: \(result.total)")
            print(titles)

            db.save { context in

                for (index, dto) in result.videos.enumerated() {
                    print(dto.contentRestricted)
                    if dto.contentRestricted == 1 {
                        self.restricted += 1
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
                    video.q240 = dto.files?.q240
                    video.q360 = dto.files?.q360
                    video.q480 = dto.files?.q480
                    video.q720 = dto.files?.q720
                    video.q1080 = dto.files?.q1080
                    video.qhls = dto.files?.qhls
                }
            }

        }

        task.resume()
    }
    
    private func queryItems(_ parameters: SearchParameters) -> [URLQueryItem] {
        return [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.103"),
            URLQueryItem(name: "q", value: parameters.query),
            URLQueryItem(name: "sort", value: "0"),
            URLQueryItem(name: "hd", value: "1"),
            URLQueryItem(name: "adult", value: "1"),
            URLQueryItem(name: "filters", value: "mp4,long"),
            URLQueryItem(name: "search_own", value: "0"),
            URLQueryItem(name: "offset", value: String(parameters.offset)),
            URLQueryItem(name: "longer", value: "30"),
            URLQueryItem(name: "shorter", value: "3600"),
            URLQueryItem(name: "count", value: String(min(200, parameters.count))),
            URLQueryItem(name: "extended", value: "1")
        ]
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
