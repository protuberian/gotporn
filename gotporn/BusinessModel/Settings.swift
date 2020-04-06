//
//  Settings.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import Foundation

struct Settings {
    static func value<T>(_ key: SettingsKey) -> T? {
        return UserDefaults.standard.object(forKey: key.rawValue) as? T
    }
    
    static func set<T>(value: T?, for key: SettingsKey) {
        return UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    static func reset() {
        #warning("todo: reset settings storage")
    }
}

enum SettingsKey: String {
    case token
    case searchText
    case volume
    case minimizeStalling
}
