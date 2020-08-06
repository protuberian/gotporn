//
//  SearchSortOrder.swift
//  gotporn
//
//  Created by Denis G. Kim on 15.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

protocol SearchSortOrderDelegate {
    func sortOrderChanged()
}

class SearchSortOrder: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var delegate: SearchSortOrderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let index = SearchSort.allCases.firstIndex(of: Settings.searchSort)!
        tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SearchSort.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? SearchSortCell(style: .default, reuseIdentifier: "Cell")
        cell.selectionStyle = .none
        cell.textLabel?.text = SearchSort.allCases[indexPath.row].localizedTitle
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Settings.searchSort = SearchSort.allCases[indexPath.row]
        delegate?.sortOrderChanged()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return " "
    }
}

class SearchSortCell: UITableViewCell {
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}
