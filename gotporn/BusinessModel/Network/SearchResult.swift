//
//  SearchResult.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation

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
            handleError(error)
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
            let id: Int
            let ownerId: Int
            let title: String
            let duration: Int
            let accessKey: String?
            let image: [Image]?
            let firstFrame: [Image]?
            let player: URL?
            let contentRestricted: Int?
            let files: Files?
            
            enum CodingKeys: String, CodingKey {
                case id = "id"
                case ownerId = "owner_id"
                case title = "title"
                case duration = "duration"
                case accessKey = "accessKey"
                case image = "image"
                case firstFrame = "first_frame"
                case player = "player"
                case contentRestricted = "content_restricted"
                case files = "files"
            }
            
            var thumb: URL {
                let bigImages = (image ?? firstFrame ?? []).filter({$0.width >= 320})
                return bigImages.first?.url ?? image?.first?.url ?? firstFrame?.first?.url ?? URL(string: "https://static.thenounproject.com/png/20804-200.png")!
            }
            
            var uid: String {
                return "\(ownerId)_\(id)"
            }
        }
        
        struct Files: Codable {
            let q240: URL?
            let q360: URL?
            let q480: URL?
            let q720: URL?
            let q1080: URL?
            let qhls: URL?
            let external: URL?
            
            enum CodingKeys: String, CodingKey {
                case q240 = "mp4_240"
                case q360 = "mp4_360"
                case q480 = "mp4_480"
                case q720 = "mp4_720"
                case q1080 = "mp4_1080"
                case qhls = "hls"
                case external
            }
        }
        
        struct Image: Codable {
            let url: URL
            let width: Int
        }
    }
}
