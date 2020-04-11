//
//  SettingsViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 11.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate {
    func settingsViewController(_ controller: SettingsViewController, completedWith changes: Bool)
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct SettingsSection {
        enum SectionType {
            case search
            case player
            case logout
            
            var localizedTitle: String? {
                switch self {
                case .search:
                    return NSLocalizedString("Search", comment: "Setting section title")
                case .player:
                    return NSLocalizedString("Player", comment: "Setting section title")
                case .logout:
                    return nil
                }
            }
        }
        let type: SectionType
        let properties: [SettingsKey]
    }
    
    let sections = [
        SettingsSection(type: .search, properties: [
            .searchHD,
            .searchAdult,
            .searchSort
        ]),
        playerSection,
        SettingsSection(type: .logout, properties: [
            .token
        ])
    ]
    
    private static let playerSection: SettingsSection = {
        var properties: [SettingsKey] = [
            .minimizeStalling,
            .rightHandedPlayerControls
        ]
        #if targetEnvironment(macCatalyst)
        properties.append(.keyboardJumpSeconds)
        properties.append(.keyboardJumpVolume)
        #endif
        return SettingsSection(type: .player, properties: properties)
    }()
    
    private(set) var searchParamsChanged = false
    
    var delegate: SettingsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.settingsViewController(self, completedWith: searchParamsChanged)
    }
    
    //MARK: - Private helpers
    func getBoolSettings(_ key: SettingsKey) -> Bool {
        switch key {
            
        case .searchHD:
            return Settings.searchHD
            
        case .searchAdult:
            return Settings.searchAdult
            
        case .minimizeStalling:
            return Settings.minimizeStalling
            
        case .rightHandedPlayerControls:
            return Settings.rightHandedPlayerControls
            
        default:
            assertionFailure("not handled")
        }
        handleError("not found bool value for settings key \(key)")
        return false
    }
    
    func setBoolSettings(value: Bool, for key: SettingsKey) {
        switch key {
            
        case .searchHD:
            Settings.searchHD = value
            searchParamsChanged = true
            
        case .searchAdult:
            Settings.searchAdult = value
            searchParamsChanged = true
            
        case .minimizeStalling:
            Settings.minimizeStalling = value
            
        case .rightHandedPlayerControls:
            Settings.rightHandedPlayerControls = value
            
        default:
            assertionFailure("not handled")
        }
        handleError("can't apply bool value for settings key \(key)")
    }
    
    //MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].properties.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let property = sections[indexPath.section].properties[indexPath.row]
        
        switch property {
        case .searchHD, .searchAdult, .minimizeStalling, .rightHandedPlayerControls:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? SwitchCell else { break }
            cell.label.text = property.localizedTitle
            cell.switcher.isOn = getBoolSettings(property)
            cell.switcherAction = { [unowned self] in self.setBoolSettings(value: $0, for: property) }
            return cell
            
        case .token:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutCell") else { break }
            return cell
            
        default:
            break
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("can't configure cell", comment: "Fallback cell text if unexpected error occured")
        cell.selectionStyle = .none
        handleError("Can't resolve configured cell at indexPath \(indexPath)")
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].type.localizedTitle
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let property = sections[indexPath.section].properties[indexPath.row]
        
        if property == .token {
            print("Logout tap")
        }
    }
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
