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
    @IBOutlet var youtubeMark: UIImageView!
    @IBOutlet var labelLikes: UILabel!
    
    private var thumbLoadingTask: URLSessionDataTask?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumb.image = nil
        thumbLoadingTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        labelLikes.layer.cornerRadius = labelLikes.frame.height/2
    }

    func updateWith(
        imageURL: URL,
        title: String,
        duration: Double,
        isYoutubeVideo: Bool,
        likes: Int64
    ) {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        if duration >= 3600 {
            formatter.allowedUnits.insert(.hour)
        }
        
        titleLabel.text = "[\(formatter.string(from: duration) ?? "-")] \(title)"
        
        thumbLoadingTask?.cancel()
        thumbLoadingTask = api.getImage(url: imageURL) { [weak self] image in
            self?.thumb.image = image
        }

        youtubeMark.isHidden = !isYoutubeVideo

        if likes > 0 {
            labelLikes.text = "♥ \(likes)"
            labelLikes.isHidden = false
        } else {
            labelLikes.isHidden = true
        }
    }
}
