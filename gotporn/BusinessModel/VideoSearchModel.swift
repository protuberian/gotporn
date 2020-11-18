//
//  VideoSearchModel.swift
//  gotporn
//
//  Created by Denis G. Kim on 03.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import CoreData

protocol VideoSearchModelDelegate: NSFetchedResultsControllerDelegate {
    func videoSearchModelDidLoadAllResults(_ model: VideoSearchModel)
}

extension VideoSearchModelDelegate {
    func videoSearchModelDidLoadAllResults(_ model: VideoSearchModel) {}
}

class VideoSearchModel {
    
    struct Constants {
        static let pageSize: UInt = 20
    }
    
    //MARK: - Public properties
    weak var delegate: VideoSearchModelDelegate? {
        didSet {
            fetchedResultsController.delegate = delegate
        }
    }
    
    var sectionsCount: Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    var query: String {
        didSet {
            print("query updated: \(query)")
            currentSearchTask?.cancel()
            currentSearchTask = nil
            reload()
        }
    }
    
    private(set) var readyToLoadMore: Bool = false
    private(set) var allResultsLoaded: Bool = false {
        didSet {
            if allResultsLoaded, let delegate = delegate {
                DispatchQueue.main.async {
                    delegate.videoSearchModelDidLoadAllResults(self)
                }
            }
        }
    }
    var queryValid: Bool {
        return query.count > 0
    }
    
    //MARK: - Private properties
    private let fetchedResultsController: NSFetchedResultsController<Video>
    private var parameters: SearchParameters
    private var ignoredErrors = 0
    private var currentSearchTask: URLSessionDataTask?
    
    //MARK: - Public functions
    init() {
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: db.container.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            handleError(error)
        }
        
        query = ""
        parameters = SearchParameters(query: query, offset: 0, count: Constants.pageSize)
    }
    
    func videosCount(in section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func video(at indexPath: IndexPath) -> Video {
        return fetchedResultsController.object(at: indexPath)
    }
    
    func loadMore() {
        guard !allResultsLoaded && readyToLoadMore else {
            print("requested to load more, but all results loaded")
            return
        }
        
        assert(currentSearchTask == nil, "search in progress")
        currentSearchTask?.cancel()
        willBeginSearch(text: parameters.query)
        currentSearchTask = api.search(parameters: parameters, completion: { [weak self] result in
            guard let self = self else { return }
            self.currentSearchTask = nil
            
            switch result {
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    break
                }

                self.ignoredErrors += 1
                if self.ignoredErrors < 3 {
                    DispatchQueue.main.async { self.loadMore() }
                }
            case .success(let dto):
                self.didLoadResults(dto)
            }
        })
    }
    
    //MARK: - Private functions
    func willBeginSearch(text: String) {
        db.save { moc in
            
            let request: NSFetchRequest<SearchQuery> = SearchQuery.fetchRequest()
            request.predicate = NSPredicate(format: "text = %@", text)
            
            let query: SearchQuery
            if let savedQuery = db.fetch(request, inContext: moc).first {
                query = savedQuery
            } else {
                query = SearchQuery(context: moc)
                query.text = text
            }
            query.lastUsed = Date()
        }
    }
    
    func didLoadResults(_ dto: SearchResult) {
        parameters.offset += parameters.count
        let lastPageLoaded = parameters.offset > dto.total
        
        guard dto.videos.count > 0 else {
            DispatchQueue.main.async {
                self.allResultsLoaded = lastPageLoaded
                self.loadMore()
            }
            return
        }
        
        let pages = Double(dto.total)/Double(parameters.count)
        
        let validVideos = dto.videos.filter({$0.contentRestricted != 1})
        print("total: \(dto.total) (\(Int(ceil(pages))) pages), on this page: \(validVideos.count)")
        
        db.save({ context in
            
            let startIndex = db.count(Video.fetchRequest()) + 1
            
            for (index, dto) in validVideos.enumerated() {
                
                let request: NSFetchRequest<Video> = Video.fetchRequest()
                request.predicate = NSPredicate(format: "uid = %@", dto.uid)
                let video = db.fetch(request, inContext: context).first ?? Video(context: context)
                
                video.uid = dto.uid
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
                video.external = dto.files?.external
                
//                print("\(video.sortIndex): \(dto.uid) - \(dto.title)")
            }
        }, completion: { success in
            self.allResultsLoaded = lastPageLoaded
        })
    }
    
    func reload() {
        let query = self.query
        
        db.save({ context in
            let request: NSFetchRequest<Video> = Video.fetchRequest()
            db.fetch(request, inContext: context).forEach { context.delete($0) }
        }, completion: { _ in
            guard self.query == query else { return } //changed async
            self.parameters.offset = 0
            self.parameters.query = query
            
            self.allResultsLoaded = false
            self.ignoredErrors = 0
            
            self.readyToLoadMore = self.queryValid
            
            self.loadMore()
        })
    }
}
