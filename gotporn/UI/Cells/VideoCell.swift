//
//  VideoCell.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {

    @IBOutlet var thumb: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    private var thumbLoadingTask: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumb.image = nil
        thumbLoadingTask?.cancel()
    }
    
    func updateWith(imageURL: URL, title: String, duration: Int) {
        titleLabel.text = title
        
        thumbLoadingTask?.cancel()
        thumbLoadingTask = api.getImage(url: imageURL) { [weak self] image in
            self?.thumb.image = image
        }
    }
}
