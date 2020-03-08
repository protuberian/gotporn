//
//  SearchResult.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import VK_ios_sdk

struct SearchResult {
    
    let videos: [VideoSearchResultDTO.Response.Video]
    let total: Int
    
    init?(response: Data) {
        let decoder = JSONDecoder()
        
        do {
            let dto = try decoder.decode(VideoSearchResultDTO.self, from: response)
            total = dto.response.count
            videos = dto.response.items
            return
        } catch {
            print(error)
        }
        return nil
    }
}

struct VideoSearchResultDTO: Codable {
    let response: Response
    
    struct Response: Codable {
        let count: Int
        let items: [Video]
        
        struct Video: Codable {
            let title: String
        }
    }
}
