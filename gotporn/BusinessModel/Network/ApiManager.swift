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
    
    
    var authorized: Bool {
        return Settings.token != nil
    }
    
    let urlSession: URLSession
    
    private(set) var searchInProgress: Bool = false
    private var restricted: Int = 0
    
    init() {
        urlSession = URLSession(configuration: .default)
        URLCache.shared = URLCache(memoryCapacity: 512*1024*1024, diskCapacity: 512*1024*1024)
    }
    
    func signIn(login: String, password: String, captcha: (String, String)? = nil, completion: @escaping (Result<Void>) -> Void) {
        let safeLogin = login.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let safePassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var url: String = authURL
            .replacingOccurrences(of: "{USERNAME}", with: safeLogin!)
            .replacingOccurrences(of: "{PASSWORD}", with: safePassword!)
        
        if let (sid, key) = captcha {
            url.append("&captcha_sid=\(sid)&captcha_key=\(key)")
        }
        
        let task = urlSession.dataTask(with: URL(string: url)!) { (data, response, error) in
            guard let data = data else {
                completion(.failure(CustomError(location: location(), body: "no response data")))
                return
            }
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print(responseString)
            }
            #endif
            
            if let dto = try? JSONDecoder().decode(AuthResponseCaptchaNeeded.self, from: data) {
                completion(.failure(AuthError.captchaNeeded(sid: dto.captchaSid, img: dto.captchaImage)))
                return
            }
            
            do {
                let dto = try JSONDecoder().decode(AuthResponse.self, from: data)
                Settings.token = dto.accessToken
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    @discardableResult
    func search(parameters: SearchParameters, completion: @escaping (Result<SearchResult>) -> Void) -> URLSessionDataTask {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.vk.com"
        components.path = "/method/video.search"
        components.queryItems = searchQueryItems(parameters)

        let request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30)
        
        print("----------")
        print("search: \(parameters.query), offset: \(parameters.offset)")
        print(request)

        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            if let data = data, let result = SearchResult(response: data) {
                completion(.success(result))
            } else {
                completion(.failure(error ?? CustomError(location: location(), body: "Unhandled error")))
            }
        }
        task.resume()
        return task
    }
    
    private func searchQueryItems(_ parameters: SearchParameters) -> [URLQueryItem] {
        func asString(_ value: Bool) -> String {
            return value ? "1" : "0"
        }
        
        var items = [
            URLQueryItem(name: "access_token", value: Settings.token),
            URLQueryItem(name: "v", value: "5.103"),
            URLQueryItem(name: "filters", value: "mp4"),
            
            URLQueryItem(name: "sort", value: Settings.searchSort.rawValue),
            URLQueryItem(name: "hd", value: asString(Settings.searchHD)),
            URLQueryItem(name: "adult", value: asString(Settings.searchAdult)),
            
            URLQueryItem(name: "q", value: parameters.query),
            URLQueryItem(name: "offset", value: String(parameters.offset)),
            URLQueryItem(name: "count", value: String(min(200, parameters.count)))
            
            //not used
            //URLQueryItem(name: "search_own", value: "0"),
            //URLQueryItem(name: "extended", value: "1")
        ]
        
        if let min = Settings.searchMinimumDuration {
            items.append(URLQueryItem(name: "longer", value: "\(min)"))
        }
        if let max = Settings.searchMaximumDuration {
            items.append(URLQueryItem(name: "shorter", value: "\(max)"))
        }
        
        return items
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
