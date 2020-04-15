//
//  Database.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation
import CoreData

class Database {
    
    let container: NSPersistentContainer
    
    init() {
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        let mom = NSManagedObjectModel(contentsOf: modelURL)!
        
        var candidate = NSPersistentContainer(name: "Model", managedObjectModel: mom)
        
        candidate.loadPersistentStores { description, error in
            guard error != nil else {
                print("Database store of type \(description.type) initialized at \(description.url!.path)")
                return
            }
            //has error, drop database
            guard let path = description.url?.path else {
                handleError(error ?? CustomError(location: location(), body: "database error"))
                return
            }
            
            print("Removing database at \(path)")
            try? FileManager.default.removeItem(atPath: path)
            candidate = NSPersistentContainer(name: "Model", managedObjectModel: mom)
            candidate.loadPersistentStores(completionHandler: { description, error in
                if let error = error {
                    handleError(error)
                } else {
                    print("Database store of type \(description.type) initialized at \(description.url!.path)")
                }
            })
        }
        
        container = candidate
        
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: nil, queue: OperationQueue.main) { notification in
            self.container.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    func save(_ block: @escaping ((NSManagedObjectContext) -> Void)) {
        save(block, completion: nil)
    }
    
    func save(_ block: @escaping ((NSManagedObjectContext) -> Void), completion: ((Bool) -> Void)? = nil) {
        container.performBackgroundTask { moc in
            block(moc)
            do {
                try moc.save()
            } catch let error {
                handleError(error)
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            DispatchQueue.main.async { completion?(true) }
        }
    }
    
    func fetch<T>(_ request: NSFetchRequest<T>, inContext: NSManagedObjectContext? = nil) -> [T] {
        do {
            let context = inContext ?? container.viewContext
            return try context.fetch(request)
        } catch let error {
            handleError(error)
            return []
        }
    }
    
    func count<T>(_ request: NSFetchRequest<T>, inContext: NSManagedObjectContext? = nil) -> Int {
        do {
            let context = inContext ?? container.viewContext
            return try context.count(for: request)
        } catch let error {
            handleError(error)
            return 0
        }
    }
}
