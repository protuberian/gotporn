//
//  SearchViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import CoreData

class SearchViewController: KeyboardObserverViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var seachBarBottomMargin: NSLayoutConstraint!
    
    private let panRecognizer = UIPanGestureRecognizer()
    private var additionalSafeAreaMaxBottomValue: CGFloat = 0
    
    private var model: NSFetchedResultsController<Video> = {
        let request: NSFetchRequest<Video> = Video.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
        let controller = NSFetchedResultsController(fetchRequest: request,
                                                    managedObjectContext: db.container.viewContext,
                                                    sectionNameKeyPath: nil,
                                                    cacheName: nil)
        return controller
    }()
    
    private var needScrollToTop = true
    private var ignoredErrors = 0
    private var parameters = SearchParameters(query: "", offset: 0, count: 20)
    
    //MARK: - Lifecycle & UI
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panRecognizer.delegate = self
        panRecognizer.addTarget(self, action: #selector(handlePan(recognizer:)))
        view.addGestureRecognizer(panRecognizer)
        
        model.delegate = self
        do {
            try model.performFetch()
        } catch {
            handleError(error)
        }
        
        DispatchQueue.main.async {
            if let query: String = Settings.value(.searchText) {
                //force reload invalidated data
                self.searchBar.text = query
                self.parameters.query = query
                self.loadMore()
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.contentInset.top = view.safeAreaInsets.top
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + searchBar.frame.height
        
        if needScrollToTop {
            needScrollToTop = false
            tableView.setContentOffset(CGPoint.init(x: 0, y: -view.safeAreaInsets.top), animated: false)
        }
    }
    
    override func keyboardWillChangeFrame(notification: Notification) {
        super.keyboardWillChangeFrame(notification: notification)
        
        guard
            let kbFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                return
        }
        
        let kbFrameInLocal = view.convert(kbFrame, from: view.window)
        let overlap = view.frame.inset(by: view.safeAreaInsets).maxY + additionalSafeAreaInsets.bottom - kbFrameInLocal.minY
        
        additionalSafeAreaInsets.bottom = max(0, overlap)
        additionalSafeAreaMaxBottomValue = additionalSafeAreaInsets.bottom
        
        view.layoutIfNeeded()
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        guard
            tableView.panGestureRecognizer.state == .began ||
            tableView.panGestureRecognizer.state == .changed
            else {
                return
        }
        
        let location = panRecognizer.location(in: view)
        
        let bottom = view.frame.inset(by: view.safeAreaInsets).maxY + additionalSafeAreaInsets.bottom - location.y
        additionalSafeAreaInsets.bottom = min(additionalSafeAreaMaxBottomValue, bottom)
    }
}

extension SearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .bottom
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(false)
        guard let query = searchBar.text, query.count > 0 else { return }
        parameters.query = query
        parameters.offset = 0
        Settings.set(value: query, for: .searchText)
        loadMore()
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
}

// MARK: - Model observing
extension SearchViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print(#function)
        assertionFailure("not implemented")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .top)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .top)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? VideoCell, let video = anObject as? Video {
                cell.updateWith(imageURL: video.photo320!, title: video.title!, duration: Int(video.duration))
            }
            
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError("unknown case")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

// MARK: - UITableView
extension SearchViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.sections![section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108.5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let video = model.object(at: indexPath)
        cell.updateWith(imageURL: video.photo320!, title: video.title!, duration: Int(video.duration))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let video = model.object(at: indexPath)
        
//        let url = "https://vk.com/video\(video.ownerId)_\(video.id)"
        var variants = [
//            video.qhls,
//            video.q1080,
            video.q720,
            video.q480,
            video.q360,
            video.q240
            ].compactMap({$0})
        
        if variants.count == 0 {
            variants = [
                video.q1080,
                video.qhls
                ].compactMap({$0})
        }
        guard let url = variants.first else {
            print("video not found")
            return
        }
        
        guard
            let vc = UIStoryboard(name: "Player", bundle: nil).instantiateInitialViewController(creator: { coder -> PlayerViewController? in
                return PlayerViewController(coder: coder, url: url)
            })
            else {
                handleError("not working")
                return
        }
        
        DispatchQueue.main.async {
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        
        print(indexPaths)
        
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if let max = indexPaths.sorted().last, max.row + 1 > lastRow {
            DispatchQueue.main.async {
                self.loadMore()
            }
        }
        
        for url in indexPaths.compactMap({ model.object(at: $0).photo320 }) {
            api.getImage(url: url)
        }
    }
}
