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
    
    enum SettingsProperty {
        case searchSort
        case searchHD
        case searchAdult
        case searchDuration
        
        case minimizeStalling
        case rightHandedPlayerControls
        case keyboardJumpSeconds
//        case keyboardJumpVolume //not available
        
        case logout
        
        var localizedTitle: String {
            switch self {
            case .searchSort:
                return NSLocalizedString("Search order", comment: "Settings property title")
            case .searchHD:
                return NSLocalizedString("Search in HD", comment: "Settings property title")
            case .searchAdult:
                return NSLocalizedString("Show 18+ content", comment: "Settings property title")
            case .searchDuration:
                return NSLocalizedString("Duration filter", comment: "Settings property title")
            case .minimizeStalling:
                return NSLocalizedString("Minimize stalling", comment: "Settings property title")
            case .rightHandedPlayerControls:
                return NSLocalizedString("Right-handed controls", comment: "Settings property title")
            case .keyboardJumpSeconds:
                return NSLocalizedString("Jump with arrows", comment: "Settings property title")
            case .logout:
                return NSLocalizedString("Logout", comment: "Settings property title")
            }
        }
    }
    
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
        let properties: [SettingsProperty]
    }
    
    let sections: [SettingsSection] = {
        let search: [SettingsProperty] = [
            .searchSort,
            .searchHD,
            .searchAdult,
            .searchDuration
        ]
        
        var player: [SettingsProperty] = [
            .minimizeStalling,
            .rightHandedPlayerControls
        ]
        
        let logout: [SettingsProperty] = [
            .logout
        ]
        
        #if targetEnvironment(macCatalyst)
        player.append(.keyboardJumpSeconds)
        #endif
        
        return [SettingsSection(type: .search, properties: search),
                SettingsSection(type: .player, properties: player),
                SettingsSection(type: .logout, properties: logout)]
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
    func getBoolSettings(_ key: SettingsProperty) -> Bool {
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
    
    func setBoolSettings(value: Bool, for key: SettingsProperty) {
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
    
    private func searchDurationFilterString(range: ClosedRange<Double>, max: Double) -> String {
        let formatter = DateComponentsFormatter()
        let unlimited = NSLocalizedString("Unlimited", comment: "maximum search video duration")
        let from = formatter.string(from: range.lowerBound)!
        let to = range.upperBound < max ? formatter.string(from: range.upperBound)! : unlimited
        return "\(from) - \(to)"
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
            
        case .searchDuration:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RangeCell") as? RangeCell else { break }
            let max = Double(3600)
            
            cell.labelTitle.text = property.localizedTitle
            cell.rangeControl.minimum = 0
            cell.rangeControl.maximum = max
            cell.rangeControl.lowerValue = Double(Settings.searchMinimumDuration ?? 0)
            cell.rangeControl.upperValue = Double(Settings.searchMaximumDuration ?? UInt(max))
            cell.rangeControl.stepValue = 5
            
            cell.labelValue.text = searchDurationFilterString(range: cell.rangeControl.lowerValue...cell.rangeControl.upperValue, max: max)
            
            cell.onValueChanged = { [unowned self, weak cell] range in
                cell?.labelValue.text = self.searchDurationFilterString(range: range, max: max)
                Settings.searchMinimumDuration = range.lowerBound > 0 ? UInt(range.lowerBound) : nil
                Settings.searchMaximumDuration = range.upperBound < max ? UInt(range.upperBound) : nil
                self.searchParamsChanged = true
            }
            
            return cell
            
        case .logout:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "LogoutCell") as? LogoutCell else { break }
            cell.labelTitle.text = property.localizedTitle
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
        
        if property == .logout {
            print("Logout tap")
        }
    }
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
