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

class SettingsViewController: UIViewController, SearchSortOrderDelegate, UITableViewDelegate, UITableViewDataSource {
    
    enum SettingsProperty {
        case searchSort
        case searchHD
        case searchAdult
        case searchDuration
        
        case qualityPriority
        case minimizeStalling
        case rightHandedPlayerControls
        case keyboardJumpSeconds
//        case keyboardJumpVolume //not available
        
        case useNativePlayer
        
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
            case .qualityPriority:
                return NSLocalizedString("Quality priority", comment: "Settings property title")
            case .minimizeStalling:
                return NSLocalizedString("Minimize stalling", comment: "Settings property title")
            case .rightHandedPlayerControls:
                return NSLocalizedString("Right-handed controls", comment: "Settings property title")
            case .keyboardJumpSeconds:
                return NSLocalizedString("Jump with arrows", comment: "Settings property title")
            case .useNativePlayer:
                return NSLocalizedString("Use standard player", comment: "Settings property title")
            case .logout:
                return NSLocalizedString("Logout", comment: "Settings property title")
            }
        }
    }
    
    struct SettingsSection {
        enum SectionType {
            case search
            case player
            case nativePlayer
            case logout
            
            var localizedTitle: String? {
                switch self {
                case .search:
                    return NSLocalizedString("Search", comment: "Setting section title")
                case .player:
                    return NSLocalizedString("Player", comment: "Setting section title")
                case .nativePlayer:
                    return NSLocalizedString("Standard player", comment: "Setting section title")
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
            .qualityPriority,
            .minimizeStalling,
            .rightHandedPlayerControls
        ]
        
        var nativePlayer: [SettingsProperty] = [.useNativePlayer]
        
        let logout: [SettingsProperty] = [
            .logout
        ]
        
        #if targetEnvironment(macCatalyst)
        player.append(.keyboardJumpSeconds)
        #endif
        
        return [SettingsSection(type: .search, properties: search),
                SettingsSection(type: .player, properties: player),
                SettingsSection(type: .nativePlayer, properties: nativePlayer),
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        (segue.destination as? SearchSortOrder)?.delegate = self
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
            
        case .useNativePlayer:
            return Settings.nativePlayerEnabled
            
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
            
        case .useNativePlayer:
            Settings.nativePlayerEnabled = value
            
        default:
            assertionFailure("not handled")
            handleError("can't apply bool value for settings key \(key)")
        }
        
    }
    
    private func searchDurationFilterString(range: ClosedRange<Double>, max: Double) -> String {
        let formatter = DateComponentsFormatter()
        let unlimited = NSLocalizedString("Unlimited", comment: "maximum search video duration")
        let from = formatter.string(from: range.lowerBound)!
        let to = range.upperBound < max ? formatter.string(from: range.upperBound)! : unlimited
        return "\(from) - \(to)"
    }
    
    private func logout() {
        let vc = UIAlertController(
            title: NSLocalizedString("Confirmation", comment: "Logout confirmation title"),
            message: NSLocalizedString("Do you want to sign out?", comment: "Logout confirmation description"),
            preferredStyle: .alert)
        
        vc.addAction(UIAlertAction(
            title: NSLocalizedString("Sign out", comment: "Alert action text"),
            style: .destructive,
            handler: { _ in
                (UIApplication.shared.delegate as? AppDelegate)?.appCoordinator.logout()
        }))
        
        vc.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Alert action text"),
                                   style: .default,
                                   handler: nil))
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.prepare()
        feedback.notificationOccurred(.warning)
        
        DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    //MARK: - SearchSortOrderDelegate
    func sortOrderChanged() {
        searchParamsChanged = true
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
        case .searchHD, .searchAdult, .minimizeStalling, .rightHandedPlayerControls, .useNativePlayer:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell") as? SwitchCell else { break }
            cell.label.text = property.localizedTitle
            cell.label.numberOfLines = 0
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

        case .searchSort:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell") ?? UITableViewCell(style: .default, reuseIdentifier: "StandardCell")
            cell.textLabel?.text = property.localizedTitle
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            return cell
            
        case .qualityPriority:
            let cell = tableView.dequeueReusableCell(withIdentifier: "StandardCell") ?? UITableViewCell(style: .default, reuseIdentifier: "StandardCell")
            cell.textLabel?.text = property.localizedTitle
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .none
            return cell
            
        case .keyboardJumpSeconds:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SliderCell") as? SliderCell else { break }
            let min = Float(1)
            let max = Float(300)
            
            cell.labelTitle.text = property.localizedTitle
            cell.slider.minimumValue = min
            cell.slider.maximumValue = max
            cell.slider.value = Float(Settings.keyboardJumpSeconds)
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            cell.labelValue.text = formatter.string(from: Double(Settings.keyboardJumpSeconds))
            
            cell.onValueChanged = { cell, value in
                let roundedValue = Int(round(value))
                Settings.keyboardJumpSeconds = roundedValue
                cell.labelValue.text = formatter.string(from: Double(roundedValue))
            }
            
            return cell
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
        
        switch property {
        case .searchSort:
            performSegue(withIdentifier: "SortOrder", sender: self)
        case .qualityPriority:
            performSegue(withIdentifier: "QualityPriority", sender: self)
        case .logout:
            logout()
        default:
            break
        }
    }
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
