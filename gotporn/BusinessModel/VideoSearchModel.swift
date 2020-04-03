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
            didChangeQuery()
        }
    }
    
    //MARK: - Private properties
    private let fetchedResultsController: NSFetchedResultsController<Video>
    private var parameters: SearchParameters
    private var ignoredErrors = 0
    
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
        
        api.search(parameters: parameters, completion: { [weak self] count, total in
            guard let self = self else { return }
            self.parameters.offset += self.parameters.count
            
            var loadNext = false
            if count == nil && self.ignoredErrors < 3 {
                self.ignoredErrors += 1
                loadNext = true
            }
            if count == 0 {
                loadNext = true
            }
            if let total = total, self.parameters.offset > total {
                loadNext = false
            }
            
            if loadNext {
                DispatchQueue.main.async {
                    self.loadMore()
                }
            }
        })
    }
    
    //MARK: - Private functions
    func didChangeQuery() {
        print("query updated: \(query)")
        ignoredErrors = 0
        parameters.offset = 0
        parameters.query = query
        loadMore()
    }
}
