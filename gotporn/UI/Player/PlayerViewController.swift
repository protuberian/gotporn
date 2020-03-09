//
//  PlayerViewController.swift
//  gotporn
//
//  Created by Denis G. Kim on 08.03.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit
import AVKit


class PlayerViewController: UIViewController {
    
    let url: URL
    
    @IBOutlet var playerView: PlayerView!
    @IBOutlet var controlView: UIView!
    @IBOutlet var progressView: UIProgressView!
    
    var mirrorMode: Bool = false {
        didSet {
            playerView.transform = CGAffineTransform(scaleX: mirrorMode ? -1 : 1, y: 1)
        }
    }
    
    private var player: AVPlayer {
        return playerView.player!
    }
    
    init?(coder: NSCoder, url: URL) {
        self.url = url
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: url:)")
    }
    
    private var timeObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.player = AVPlayer(url: url)
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 30), queue: DispatchQueue.main, using: { [weak self] time in
            guard let duration = self?.player.currentItem?.duration, duration.isValid else {
                return
            }
            
            self?.progressView.progress = Float(time.seconds/duration.seconds)
            
            print(time.seconds/duration.seconds)
        })
        
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.automaticallyWaitsToMinimizeStalling = false
        player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
        tabBarController?.tabBar.isHidden = false
    }
    
    @IBAction func mirrorTap(_ sender: Any) {
        mirrorMode = !mirrorMode
    }
    
    @IBAction func tapPlayerView(_ sender: Any) {
        controlView.isHidden = false
    }
    
    @IBAction func tapControlView(_ sender: Any) {
        controlView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: true)
        player.play()
    }
    
    @IBAction func closeTap(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private var seekStarPosition: CMTime!
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        
        switch sender.state {
        case .began:
            seekStarPosition = player.currentTime()
        case .changed:
            let translation = sender.translation(in: view)
            
            let dt = Double(translation.x * 1)
            
            let shifted = CMTime(seconds: seekStarPosition.seconds + dt, preferredTimescale: seekStarPosition.timescale)
            
            guard let duration = player.currentItem?.duration else {
                return
            }
            
            let persent = player.currentTime().seconds / duration.seconds
            print(persent)
            
            player.seek(to: min(shifted, duration))
        default:
            break
        }
    }
}

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
    
    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
