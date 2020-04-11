//
//  SwitchCell.swift
//  gotporn
//
//  Created by Denis G. Kim on 11.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import Combine

class SwitchCell: UITableViewCell {

    @IBOutlet var label: UILabel!
    @IBOutlet var switcher: UISwitch!
    
    var switcherAction: ((Bool) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        switcherAction = nil
    }
    
    @IBAction func switchValueChanged(_ sender: Any) {
        switcherAction?(switcher.isOn)
    }
}
