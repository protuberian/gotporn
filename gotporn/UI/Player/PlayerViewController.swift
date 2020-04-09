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
    enum PanControlBehavior {
        case changesVolume
        case shiftingTime
        case settingTime
    }
    
    let url: URL
    
    @IBOutlet var playerView: PlayerView!
    @IBOutlet var controlView: UIView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var volumeView: UIProgressView!
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingIndicatorContainer: UIView!
    
    var mirrorMode: Bool = false {
        didSet {
            playerView.transform = CGAffineTransform(scaleX: mirrorMode ? -1 : 1, y: 1)
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - Private properties
    private var player: AVPlayer
    private var timeObserver: Any?
    
    #warning("todo: rework hack. disable tap recognizer, enable after")
    private var nextTouchUpDisabled = false
    
    private var panBeganAtVolume: Float?
    private var panBeganAtTimePosition: CMTime?
    private var panBehavior: PanControlBehavior?
    
    //MARK: - Lifecycle & inherited
    init?(coder: NSCoder, url: URL) {
        self.url = url
        self.player = AVPlayer(url: url)
        super.init(coder: coder)
        
        player.automaticallyWaitsToMinimizeStalling = Settings.minimizeStalling
    }
    
    required init?(coder: NSCoder) {
        fatalError("use init?(coder: url:)")
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.semanticContentAttribute = Settings.rightHandedPlayerControls ? .forceLeftToRight : .forceRightToLeft
        controlView.semanticContentAttribute = Settings.rightHandedPlayerControls ? .forceLeftToRight : .forceRightToLeft
        
        progressView.semanticContentAttribute = .playback
        volumeView.semanticContentAttribute = .playback
        
        playerView.player = player
        addPlayerObservers()
        
        volumeView.transform = CGAffineTransform(rotationAngle: -(.pi/2))
        setVolume(value: Settings.volume)
        hideVolumeView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player.play()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, progressView.frame.insetBy(dx: -20, dy: -20).contains(touch.location(in: view)) {
            setTime(location: touch.location(in: progressView).x / progressView.frame.width)
            controlView.isHidden = false
            nextTouchUpDisabled = true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(AVPlayer.timeControlStatus):
            if player.timeControlStatus == .paused, !player.automaticallyWaitsToMinimizeStalling {
                player.play()
            }
            loadingIndicatorContainer.isHidden = player.timeControlStatus != .waitingToPlayAtSpecifiedRate
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    //MARK: - Private functions
    private func addPlayerObservers() {
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 30), queue: DispatchQueue.main, using: { [weak self] time in
                guard let duration = self?.player.currentItem?.duration, duration.isNumeric else {
                    return
                }
                if self?.panRecognizer.state == .possible {
                    self?.timeProgressChanged(seconds: time.seconds, duration: duration.seconds)
                }
        })
        
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [], context: nil)
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
    
    private func timeProgressChanged(seconds: Double, duration: Double) {
        progressView.progress = Float(seconds/duration)
        let formatter = DateComponentsFormatter()
        if let now = formatter.string(from: seconds), let total = formatter.string(from: duration) {
            progressLabel.text = "\(now)/\(total)"
        }
    }
    
    //MARK: Time position
    private func shiftTime(translation: CGFloat) {
        guard let panStart = panBeganAtTimePosition else {
            return
        }
        
        let secondsPerPoint: CGFloat = 1
        let dt = Double(translation * secondsPerPoint)
        setTime(seconds: panStart.seconds + dt)
    }
    
    private func setTime(location: CGFloat) {
        guard let duration = player.currentItem?.duration.seconds, !duration.isNaN, !duration.isZero else {
            return
        }
        setTime(seconds: Double(location) * duration)
    }
    
    private func setTime(seconds: Double) {
        guard let duration = player.currentItem?.duration, duration.isNumeric else { return }
        
        let timescale = duration.timescale
        let trackStart = CMTime(seconds: 0, preferredTimescale: timescale)
        let target = CMTime(seconds: seconds, preferredTimescale: timescale)
        
        let time = clamp(target, trackStart, duration)
        
        player.currentItem?.cancelPendingSeeks()
        player.currentItem?.seek(to: time, completionHandler: nil)
        timeProgressChanged(seconds: time.seconds, duration: duration.seconds)
    }
    
    //MARK: Volume
    private func setVolume(translation: CGFloat) {
        guard let panBeganAtVolume = panBeganAtVolume else { return }
        
        let volumeControlHeight: CGFloat = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) * 0.5
        let targetVolume = panBeganAtVolume + Float(translation / volumeControlHeight * -1)
        
        setVolume(value: clamp(targetVolume, 0, 1))
        
        print("volume: \(player.volume)")
    }
    
    private func setVolume(value: Float) {
        Settings.volume = value
        player.volume = value
        volumeView.progress = value
        volumeView.isHidden = false
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideVolumeView), object: nil)
        perform(#selector(hideVolumeView), with: nil, afterDelay: 1.5)
    }
    
    @objc private func hideVolumeView() {
        volumeView.isHidden = true
    }
    
    //MARK: - IBActions
    @IBAction func mirrorTap(_ sender: Any) {
        mirrorMode = !mirrorMode
    }
    
    @IBAction func closeTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func viewTap(_ sender: Any) {
        if nextTouchUpDisabled {
            nextTouchUpDisabled = false
            return
        }
        controlView.isHidden = !controlView.isHidden
    }
    
    @IBAction func viewPan(_ sender: UIPanGestureRecognizer) {
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
                    setVolume(translation: translation.y)
                }
            } else {
                resolvePanBehavior(location: sender.location(in: view), translation: translation)
            }
            
        case .ended:
            panBehavior = nil
            
        default:
            break
        }
    }
}

//MARK: - Helpers
fileprivate func clamp<T>(_ arg: T, _ limit1: T, _ limit2: T) -> T where T: Comparable {
    let minimum = min(limit1, limit2)
    let maximum = max(limit1, limit2)
    return min(maximum, max(minimum, arg))
}
