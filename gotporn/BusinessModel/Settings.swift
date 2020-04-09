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
    
    //search
    case searchHD
    case searchAdult
    case searchSort
    case searchMinimumDuration
    case searchMaximumDuration
}

enum SearchSort: String {
    case added = "0"
    case duration = "1"
    case relevance = "2"
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
        get { return value(.keyboardJumpSeconds) ?? 10 }
        set { set(value: newValue, for: .keyboardJumpSeconds) }
    }
    
    static var keyboardJumpVolume: Float {
        get { return value(.keyboardJumpVolume) ?? 0.1 }
        set { set(value: newValue, for: .keyboardJumpVolume) }
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
        get { return value(.searchSort) ?? .added }
        set { set(value: newValue, for: .searchSort) }
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
