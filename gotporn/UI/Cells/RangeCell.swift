//
//  RangeCell.swift
//  gotporn
//
//  Created by Denis G. Kim on 12.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

class RangeCell: UITableViewCell {
    
    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelValue: UILabel!
    
    @IBOutlet var rangeControl: RangeControl!
    
    var onValueChanged: ((ClosedRange<Double>) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onValueChanged = nil
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        onValueChanged?(rangeControl.lowerValue...rangeControl.upperValue)
    }
}
