//
//  SliderCell.swift
//  gotporn
//
//  Created by Denis G. Kim on 13.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

class SliderCell: UITableViewCell {

    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelValue: UILabel!
    @IBOutlet var slider: UISlider!
    
    var onValueChanged: ((SliderCell, Float) -> Void)?
    
    @IBAction func valueChanged(_ sender: Any) {
        onValueChanged?(self, slider.value)
    }
}
