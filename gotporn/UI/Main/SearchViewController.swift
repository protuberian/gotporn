//
//  SearchViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import CoreData
import AVKit

class SearchViewController: KeyboardObserverViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var seachBarBottomMargin: NSLayoutConstraint!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var footerLabel: UILabel!
    
    private let panRecognizer = UIPanGestureRecognizer()
    private var additionalSafeAreaMaxBottomValue: CGFloat = 0
    
    let model = VideoSearchModel()
    
    private var needScrollToTop = true
    private var showsLoading = false {
        didSet {
            updateLoadingState()
        }
    }
    
    //MARK: - Lifecycle & UI
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLoadingState()
        tableView.contentInsetAdjustmentBehavior = .never
        
        panRecognizer.delegate = self
        panRecognizer.addTarget(self, action: #selector(handlePan(recognizer:)))
        view.addGestureRecognizer(panRecognizer)
        
        model.delegate = self
        
        if let query = Settings.searchText, query.count > 0 {
            showsLoading = true
            searchBar.text = query
            model.query = query
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.contentInset.top = view.safeAreaInsets.top
        tableView.contentInset.bottom = view.safeAreaInsets.bottom + searchBar.frame.height
        
        if needScrollToTop {
            needScrollToTop = false
            tableView.setContentOffset(CGPoint(x: 0, y: -view.safeAreaInsets.top), animated: false)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        super.prepare(for: segue, sender: nil)
    }
    
    func updateLoadingState() {
        loadViewIfNeeded()
        footerLabel.isHidden = showsLoading
        
        if model.query.count > 0, model.sectionsCount > 0 {
            let identifier = NSLocalizedString("search_footer", comment: "Used by plurals dict, do not translate")
            footerLabel.text = String.localizedStringWithFormat(identifier, model.videosCount(in: 0))
        } else {
            footerLabel.text = nil
        }
        
        if showsLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
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
    
    @IBSegueAction func createSettingsController(_ coder: NSCoder) -> SettingsViewController? {
        let vc = SettingsViewController(coder: coder)
        vc?.delegate = self
        return vc
    }
    
    private func playVideoWithNativePlayer(url: URL) {
        let standardPlayer = AVPlayerViewController()
        standardPlayer.player = AVPlayer(playerItem: AVPlayerItem(url: url))
        self.present(standardPlayer, animated: true, completion: {
            standardPlayer.player?.play()
        })
    }
    
    private func playVideoWithApplicationPlayer(url: URL, quality: VideoQuality) {
        let playerViewController = UIStoryboard(name: "Player", bundle: nil).instantiateInitialViewController(creator: { coder -> PlayerViewController? in
            return PlayerViewController(coder: coder, url: url, quality: quality)
        })
        
        guard let vc = playerViewController else {
            handleError("Error initializing PlayerViewController")
            return
        }
        
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    private func performSearch() {
        view.endEditing(true)
        guard let query = searchBar.text, query.count > 0 else { return }
        showsLoading = true
        Settings.searchText = query
        model.query = query
    }
}

extension SearchViewController: SettingsViewControllerDelegate {
    func settingsViewController(_ controller: SettingsViewController, completedWith changes: Bool) {
        if changes, model.queryValid {
            showsLoading = true
            model.reload()
        }
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
        let vc = UIStoryboard(name: "History", bundle: nil).instantiateInitialViewController() as! HistoryViewController
        vc.didSelectQuery = { [weak self] query in
            guard let self = self else { return }
            self.searchBar.text = query
            self.performSearch()
            self.dismiss(animated: true, completion: nil)
        }
        
        view.endEditing(true)
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
}

// MARK: - Model observing
extension SearchViewController: VideoSearchModelDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
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
                cell.updateWith(video: video)
            }
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            fatalError("unknown case")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if tableView.indexPathsForVisibleRows?.max()?.row == lastRow {
            model.loadMore()
        }
    }
    
    func videoSearchModelDidLoadAllResults(_ model: VideoSearchModel) {
        showsLoading = false
    }
}

// MARK: - UITableView
extension SearchViewController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.videosCount(in: section)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 108.5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        cell.updateWith(video: model.video(at: indexPath))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
        let video = model.video(at: indexPath)
        
        guard let info = video.videoInfo else {
            handleError("video unavailable")
            if let playerURL = video.external ?? video.player {
                UIApplication.shared.open(playerURL, options: [:], completionHandler: nil)
            }
            return
        }
        
        DispatchQueue.main.async {
            if Settings.nativePlayerEnabled {
                self.playVideoWithNativePlayer(url: info.0)
            } else {
                self.playVideoWithApplicationPlayer(url: info.0, quality: info.1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        let lastRow = tableView.numberOfRows(inSection: 0) - 1
        if let max = indexPaths.sorted().last, max.row + 1 > lastRow {
            DispatchQueue.main.async {
                self.model.loadMore()
            }
        }
        
        //cache images
        for url in indexPaths.compactMap({ model.video(at: $0).photoURL }) {
            api.getImage(url: url)
        }
    }
}

//MARK: - Extensions
extension VideoCell {
    func updateWith(video: Video) {
        updateWith(imageURL: video.photo320!, title: video.title!, duration: Double(video.duration))
    }
}

extension Video {
    var photoURL: URL {
        return photo320!
    }
    
    var videoInfo: (URL, VideoQuality)? {
//        let url = "https://vk.com/video\(video.ownerId)_\(video.id)"
        
        let preferredQuality = Settings.videoQuality
        let availableInfo = preferredQuality.compactMap({ quality -> (URL?, VideoQuality) in
            switch quality {
            case .q1080: return (q1080, quality)
            case .q720: return (q720,quality)
            case .q480: return (q480,quality)
            case .q360: return (q360,quality)
            case .q240: return (q240,quality)
            case .qhls: return (qhls,quality)
            }
        }).compactMap({ info -> (URL, VideoQuality)? in
            if let url = info.0 {
                return (url, info.1)
            } else {
                return nil
            }
        })
        
        return availableInfo.first
    }
}
