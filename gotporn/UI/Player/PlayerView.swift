//
//  PlayerView.swift
//  gotporn
//
//  Created by Denis G. Kim on 06.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import AVKit

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
