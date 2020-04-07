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
        let hd: Bool = Settings.value(.searchHD) ?? false
        
        return [
            URLQueryItem(name: "access_token", value: token),
            URLQueryItem(name: "v", value: "5.103"),
            URLQueryItem(name: "q", value: parameters.query),
            URLQueryItem(name: "sort", value: Settings.value(.searchSort)),
            URLQueryItem(name: "hd", value: hd ? "1" : "0"),
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
