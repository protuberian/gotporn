//
//  HistoryViewController.swift
//  gotporn
//
//  Created by Denis Kim on 06.08.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var didSelectQuery: ((String) -> Void)?
    
    private let fetchedResultsController: NSFetchedResultsController<SearchQuery> = {
        let request: NSFetchRequest<SearchQuery> = SearchQuery.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastUsed", ascending: false)]
        
        return NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: db.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchedResultsController.delegate = self
        try? fetchedResultsController.performFetch()
    }
    
    @IBAction func buttonDoneTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        let model = fetchedResultsController.fetchedObjects![indexPath.row]
        cell.textLabel?.text = model.text
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = fetchedResultsController.fetchedObjects![indexPath.row]
        
        didSelectQuery?(model.text!)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let id = fetchedResultsController.fetchedObjects![indexPath.row].objectID
        db.save { moc in
            moc.delete(try! moc.existingObject(with: id))
        }
    }
}

extension HistoryViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        assertionFailure("not implemented")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .top)
        case .update:
            break
        default:
            fatalError("not implemented")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
