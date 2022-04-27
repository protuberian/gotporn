//
//  Settings.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation

enum SettingsKey: String {
    //application
    case token
    case searchText
    
    //player
    case volume
    case minimizeStalling
    case rightHandedPlayerControls
    case keyboardJumpSeconds
    case keyboardJumpVolume
    case videoQuality
    
    //native player
    case nativePlayerEnabled
    
    //search
    case searchHD
    case searchAdult
    case searchSort
    case searchMinimumDuration
    case searchMaximumDuration
}

enum SearchSort: String, CaseIterable {
    case added = "0"
    case duration = "1"
    case relevance = "2"
    case viewed = "3"
    
    var localizedTitle: String {
        switch self {
        case .added:
            return NSLocalizedString("by date", comment: "Search sort description")
        case .duration:
            return NSLocalizedString("by duration", comment: "Search sort description")
        case .relevance:
            return NSLocalizedString("by relevance", comment: "Search sort description")
        case .viewed:
            return NSLocalizedString("by views", comment: "Search sort description")
        }
    }
}

enum VideoQuality: String, CaseIterable {
    case q1080
    case q720
    case q480
    case q360
    case q240
    case qhls
    
    var localizedTitle: String {
        switch self {
        case .q1080:
            return "1080p"
        case .q720:
            return "720p"
        case .q480:
            return "480p"
        case .q360:
            return "360p"
        case .q240:
            return "240p"
        case .qhls:
            return "HLS"
        }
    }
}

struct Settings {
    
    //MARK: Application related
    static var token: String? {
        get { return value(.token) }
        set { set(value: newValue, for: .token) }
    }
    
    static var searchText: String? {
        get { return value(.searchText) }
        set { set(value: newValue, for: .searchText) }
    }
    
    //MARK: Player related
    static var volume: Float {
        get { return value(.volume) ?? 1 }
        set { set(value: newValue, for: .volume) }
    }
    
    static var minimizeStalling: Bool {
        get { return value(.minimizeStalling) ?? false }
        set { set(value: newValue, for: .minimizeStalling) }
    }
    
    static var rightHandedPlayerControls: Bool {
        get { return value(.rightHandedPlayerControls) ?? true }
        set { set(value: newValue, for: .rightHandedPlayerControls) }
    }
    
    static var keyboardJumpSeconds: Int {
        get { return value(.keyboardJumpSeconds) ?? 15 }
        set { set(value: newValue, for: .keyboardJumpSeconds) }
    }
    
    static var keyboardJumpVolume: Float {
        get { return value(.keyboardJumpVolume) ?? 0.1 }
        set { set(value: newValue, for: .keyboardJumpVolume) }
    }
    
    static var videoQuality: [VideoQuality] {
        get {
            guard let rawValues = value(.videoQuality) as [String]? else {
                return VideoQuality.allCases
            }
            return rawValues.compactMap({VideoQuality(rawValue: $0)})
        }
        set {
            set(value: newValue.map({$0.rawValue}), for: .videoQuality)
        }
    }
    
    //MARK: Native player
    static var nativePlayerEnabled: Bool {
        get { return value(.nativePlayerEnabled) ?? false }
        set { set(value: newValue, for: .nativePlayerEnabled) }
    }
    
    //MARK: Search request related
    static var searchHD: Bool {
        get { return value(.searchHD) ?? false }
        set { set(value: newValue, for: .searchHD) }
    }
    
    static var searchAdult: Bool {
        get { return value(.searchAdult) ?? true }
        set { set(value: newValue, for: .searchAdult) }
    }
    
    static var searchSort: SearchSort {
        get {
            if let rawValue = value(.searchSort) as String?, let sort = SearchSort(rawValue: rawValue) {
                return sort
            } else {
                return .added
            }
        }
        set { set(value: newValue.rawValue, for: .searchSort) }
    }
    
    static var searchMinimumDuration: UInt? {
        get { return value(.searchMinimumDuration) }
        set { set(value: newValue, for: .searchMinimumDuration) }
    }
    
    static var searchMaximumDuration: UInt? {
        get { return value(.searchMaximumDuration) }
        set { set(value: newValue, for: .searchMaximumDuration) }
    }
}

//MARK: Private helpers

fileprivate func value<T>(_ key: SettingsKey) -> T? {
    return UserDefaults.standard.object(forKey: key.rawValue) as? T
}

fileprivate func set<T>(value: T?, for key: SettingsKey) {
    return UserDefaults.standard.setValue(value, forKey: key.rawValue)
}
