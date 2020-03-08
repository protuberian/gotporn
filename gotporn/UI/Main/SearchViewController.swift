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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        panRecognizer.delegate = self
        panRecognizer.addTarget(self, action: #selector(handlePan(recognizer:)))
        view.addGestureRecognizer(panRecognizer)
        
        model.delegate = self
        
        try? model.performFetch()
        
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.contentInset.top = view.safeAreaInsets.top
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + searchBar.frame.height
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
        let parameters = SearchParameters(query: query)
        api.search(parameters: parameters)
    }
}

extension SearchViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.sections![section].numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let video = model.object(at: indexPath)
        cell.updateWith(imageURL: video.photo320!, title: video.title!, duration: Int(video.duration))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
