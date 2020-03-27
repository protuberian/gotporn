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
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var volumeView: UIProgressView!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
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
            guard let duration = self?.player.currentItem?.duration, duration.isNumeric else {
                return
            }
            if self?.panRecognizer.state == .possible {
                self?.timeProgressChanged(seconds: time.seconds, duration: duration.seconds)
            }
        })
        
        volumeView.transform = CGAffineTransform(rotationAngle: -(.pi/2))
        if let volume: Float = Settings.value(.volume) {
            setVolume(volume)
        }
        hideVolumeView()
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
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
    
    private func timeProgressChanged(seconds: Double, duration: Double) {
        progressView.progress = Float(seconds/duration)
        let formatter = DateComponentsFormatter()
        if let now = formatter.string(from: seconds), let total = formatter.string(from: duration) {
            progressLabel.text = "\(now)/\(total)"
        }
    }
    
    #warning("todo: rework hack. disable tap recognizer, enable after")
    private var nextTouchUpDisabled = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, progressView.frame.insetBy(dx: -20, dy: -20).contains(touch.location(in: view)) {
            setTime(location: touch.location(in: progressView).x / progressView.frame.width)
            controlView.isHidden = false
            nextTouchUpDisabled = true
        }
    }
    
    @IBAction func mirrorTap(_ sender: Any) {
        mirrorMode = !mirrorMode
    }
    
    @IBAction func tapView(_ sender: Any) {
        if nextTouchUpDisabled {
            nextTouchUpDisabled = false
            return
        }
        controlView.isHidden = !controlView.isHidden
        player.play()
    }
    
    @IBAction func closeTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    private var panBeganAtVolume: Float?
    private var panBeganAtTimePosition: CMTime?
    private var panBehavior: PanControlBehavior?
    
    enum PanControlBehavior {
        case changesVolume
        case shiftingTime
        case settingTime
    }
    
    func clamp<T>(_ arg: T, _ limit1: T, _ limit2: T) -> T where T: Comparable {
        
        let minimum = min(limit1, limit2)
        let maximum = max(limit1, limit2)
        
        return min(maximum, max(minimum, arg))
    }
    
    private func shiftTime(translation: CGFloat) {
        guard let panStart = panBeganAtTimePosition else {
            return
        }
        
        let secondsPerPoint: CGFloat = 1
        let dt = Double(translation * secondsPerPoint)
        setTime(seconds: panStart.seconds + dt)
    }
    
    private func setTime(location: CGFloat) {
        guard let duration = player.currentItem?.duration else {
            return
        }
        setTime(seconds: Double(location) * duration.seconds)
    }
    
    private func updateVolume(translation: CGFloat) {
        guard let panBeganAtVolume = panBeganAtVolume else { return }
        
        let volumeControlHeight: CGFloat = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) * 0.5
        let targetVolume = panBeganAtVolume + Float(translation / volumeControlHeight * -1)
        
        setVolume(clamp(targetVolume, 0, 1))
        
        print(player.volume)
    }
    
    private func setVolume(_ volume: Float) {
        Settings.set(value: volume, for: .volume)
        player.volume = volume
        volumeView.progress = volume
        volumeView.isHidden = false
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideVolumeView), object: nil)
        perform(#selector(hideVolumeView), with: nil, afterDelay: 1.5)
    }
    
    private func setTime(seconds: Double) {
        guard let duration = player.currentItem?.duration else { return }
        
        let timescale = duration.timescale
        let trackStart = CMTime(seconds: 0, preferredTimescale: timescale)
        let target = CMTime(seconds: seconds, preferredTimescale: timescale)
        
        let time = clamp(target, trackStart, duration)
        
        player.seek(to: time)
        timeProgressChanged(seconds: time.seconds, duration: duration.seconds)
    }
    
    @objc private func hideVolumeView() {
        volumeView.isHidden = true
    }
    
    private func resolvePanBehavior(location: CGPoint, translation: CGPoint) {
        guard translation != .zero else {
            panBehavior = nil
            return
        }
        
        if progressView.frame.insetBy(dx: -20, dy: -20).contains(location) {
            panBehavior = .settingTime
        } else {
            if abs(translation.y) > abs(translation.x) {
                panBeganAtVolume = player.volume
                panBehavior = .changesVolume
            } else {
                panBehavior = .shiftingTime
                panBeganAtTimePosition = player.currentTime()
            }
        }
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        switch sender.state {
            
        case .began:
            resolvePanBehavior(location: sender.location(in: view), translation: translation)
            nextTouchUpDisabled = false
            
        case .changed:
            if let panBehavior = panBehavior {
                switch panBehavior {
                case .shiftingTime:
                    shiftTime(translation: translation.x)
                case .settingTime:
                    setTime(location: sender.location(in: progressView).x / progressView.frame.width)
                case .changesVolume:
                    updateVolume(translation: translation.y)
                }
            } else {
                resolvePanBehavior(location: sender.location(in: view), translation: translation)
            }
            
        case .ended:
            panBehavior = nil
            player.play()
            
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
