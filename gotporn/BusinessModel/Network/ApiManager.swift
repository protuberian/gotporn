//
//  ApiManager.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let authURL = "https://oauth.vk.com/token?grant_type=password&client_id=2274003&client_secret=hHbZxrka2uZ6jB1inYsH&username={USERNAME}&password={PASSWORD}&scope=video"

class ApiManager {
    
    var token: String? {
        get {
            Settings.value(.token)
        }
        set {
            Settings.set(value: newValue, for: .token)
        }
    }
    
    var authorized: Bool {
        return token != nil
    }
    
    let urlSession: URLSession
    
    private(set) var searchInProgress: Bool = false
    private var restricted: Int = 0
    
    init() {
        urlSession = URLSession(configuration: .default)
        URLCache.shared = URLCache(memoryCapacity: 512*1024*1024, diskCapacity: 512*1024*1024)
    }
    
    func signIn(login: String, password: String, completion: @escaping (Bool) -> Void) {
        let safeLogin = login.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let safePassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url: String = authURL
            .replacingOccurrences(of: "{USERNAME}", with: safeLogin!)
            .replacingOccurrences(of: "{PASSWORD}", with: safePassword!)
        
        let task = urlSession.dataTask(with: URL(string: url)!) { (data, response, error) in
            
            if let error = error {
                handleError(error)
            }
            
            guard let data = data else {
                completion(false)
                return
            }
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
            }
            #endif
            
            do {
                let dto = try JSONDecoder().decode(AuthResponse.self, from: data)
                self.token = dto.accessToken
                completion(true)
            } catch {
                handleError(error)
                completion(false)
            }
        }
        task.resume()
    }
    
    func search(parameters: SearchParameters, completion: ((Int?, Int?) -> Void)?) {
        guard !searchInProgress else {
            print("canceled, search in progress")
            return
        }
        searchInProgress = true
        
        db.save({ context in
            if parameters.offset == 0 {
                self.restricted = 0
                let request: NSFetchRequest<Video> = Video.fetchRequest()
                db.fetch(request, inContext: context).forEach {
                    context.delete($0)
                }
            }
        }, completion: { _ in
            self.performSearch(parameters: parameters) { count, total in
                completion?(count, total)
                self.searchInProgress = false
            }
        })
    }
    
    func performSearch(parameters: SearchParameters, completion: @escaping (Int?, Int?) -> Void) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.vk.com"
        components.path = "/method/video.search"
        components.queryItems = queryItems(parameters)

        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        print(request)

        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let result = SearchResult(response: data)
                else {
                    print("error mapping response")
                    completion(nil, nil)
                    return
            }

            
            print("total: \(result.total) (\(result.total/Int(parameters.count))) pages")
            print("offset: \(parameters.offset)")
            print("restricted before: \(self.restricted)")
            let startIndex = Int(parameters.offset) - self.restricted
            
            var validItems = 0
            db.save({ context in
                for (index, dto) in result.videos.enumerated() {
                    if dto.contentRestricted == 1 {
                        self.restricted += 1
                        continue
                    }
                    validItems += 1
                    let request: NSFetchRequest<Video> = Video.fetchRequest()
                    request.predicate = NSPredicate(format: "id = %@", NSNumber(value: dto.id))
                    let video = db.fetch(request, inContext: context).first ?? Video(context: context)
                    video.id = Int64(dto.id)
                    video.ownerId = Int64(dto.ownerId)
                    video.sortIndex = Int64(startIndex + index)
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
                
                print("restricted after: \(self.restricted)")
                
                let titles = result.videos.compactMap { $0.contentRestricted == 1 ? nil : $0.title}
                print(titles)
            }, completion: { success in
                completion(success ? validItems : nil, result.total)
            })
        }

        task.resume()
    }
    
    private func queryItems(_ parameters: SearchParameters) -> [URLQueryItem] {
        return [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.103"),
            URLQueryItem(name: "q", value: parameters.query),
            URLQueryItem(name: "sort", value: "0"),
//            URLQueryItem(name: "hd", value: "1"),
            URLQueryItem(name: "adult", value: "1"),
            URLQueryItem(name: "filters", value: "mp4"),
//            URLQueryItem(name: "search_own", value: "0"),
            URLQueryItem(name: "offset", value: String(parameters.offset)),
            URLQueryItem(name: "longer", value: "240"),
//            URLQueryItem(name: "shorter", value: "3600"),
            URLQueryItem(name: "count", value: String(min(200, parameters.count)))
//            URLQueryItem(name: "extended", value: "1")
        ]
    }
    
    @discardableResult
    func getImage(url: URL, completion: ((UIImage?) -> Void)? = nil) -> URLSessionDataTask {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 20)
        
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            
            var image: UIImage?
            if let data = data {
                image = UIImage(data: data)
            }
            DispatchQueue.main.async {
                completion?(image)
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
