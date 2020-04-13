//
//  RangeControl.swift
//  gotporn
//
//  Created by Denis G. Kim on 12.04.2020.
//  Copyright © 2020 kimdenis. All rights reserved.
//

import UIKit

@IBDesignable
class RangeControl: UIControl {
    enum Thumb {
        case lower
        case upper
    }
    
    @IBInspectable var trackHeight: CGFloat = 2 {
           didSet {
               setNeedsLayout()
           }
       }
    
    @IBInspectable var minimum: Double = 0 {
        didSet {
            if minimum > maximum {
                maximum = minimum
            }
            setNeedsLayout()
        }
    }
    
    @IBInspectable var maximum: Double = 100 {
        didSet {
            if maximum < minimum {
                minimum = maximum
            }
            setNeedsLayout()
        }
    }
    
    @IBInspectable var isContinuous: Bool = true
    
    var lowerValue: Double {
        didSet {
            if lowerValue > upperValue {
                upperValue = lowerValue
            }
            setNeedsLayout()
        }
    }
    var upperValue: Double {
        didSet {
            if upperValue < lowerValue {
                lowerValue = upperValue
            }
            setNeedsLayout()
        }
    }
    
    var stepValue: Double?
    
    let track = UIView()
    let thumbLower = UIImageView()
    let thumbUpper = UIImageView()
    
    override var tintColor: UIColor! {
        didSet {
            track.backgroundColor = tintColor
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let top = thumbUpper.image?.size.height ?? 0
        let bottom = thumbLower.image?.size.height ?? 0
        
        let height = top + track.frame.height + bottom
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    private let panRecognizer = UIPanGestureRecognizer()
    private var activeThumb: Thumb?
    private var touchActive: Bool { return activeThumb != nil }
    
    //MARK: - Lifecycle
    override init(frame: CGRect) {
        lowerValue = minimum
        upperValue = maximum
        super.init(frame: frame)
        baseSetup()
    }
    
    required init?(coder: NSCoder) {
        lowerValue = minimum
        upperValue = maximum
        super.init(coder: coder)
        baseSetup()
    }
    
    private func baseSetup() {
        thumbLower.image = UIImage(systemName: "arrowtriangle.up.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .ultraLight))
        thumbUpper.image = UIImage(systemName: "arrowtriangle.down.fill",
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .ultraLight))
        
        thumbLower.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        thumbUpper.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        addSubview(track)
        addSubview(thumbLower)
        addSubview(thumbUpper)
        track.backgroundColor = tintColor
        
        isExclusiveTouch = true
        
        addGestureRecognizer(panRecognizer)
        panRecognizer.addTarget(self, action: #selector(handlePan(recongnizer:)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTrack()
        layoutLowerThumb()
        layoutUpperThumb()
    }
    
    private func layoutTrack() {
        var frame = bounds
        frame.size.height = trackHeight
        frame.origin.y = (self.frame.height - frame.height)/2
        track.frame = frame
    }
    
    private func layoutLowerThumb() {
        thumbLower.sizeToFit()
        let center = CGPoint(x: locationX(for: lowerValue), y: track.frame.maxY)
        thumbLower.center = center
    }
    
    private func layoutUpperThumb() {
        thumbUpper.sizeToFit()
        let center = CGPoint(x: locationX(for: upperValue), y: track.frame.minY)
        thumbUpper.center = center
    }
    
    //MARK: - Track movements
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return bounds.insetBy(dx: -22, dy: -22).contains(point) ? self : nil
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return touchShouldBeganWith(location: touch.location(in: self))
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        touchContinuesWith(location: touch.location(in: self))
        return true
    }
    
    override func cancelTracking(with event: UIEvent?) {
        if panRecognizer.state != .began {
            touchEnded()
        }
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        touchEnded()
    }
    
    @objc func handlePan(recongnizer: UIPanGestureRecognizer) {
        
        switch recongnizer.state {
        case .began, .changed:
            if !touchActive {
                if !touchShouldBeganWith(location: recongnizer.location(in: self)) {
                    recongnizer.isEnabled = false
                    recongnizer.isEnabled = true
                }
            } else {
                touchContinuesWith(location: recongnizer.location(in: self))
            }
        case .ended:
            touchEnded()
        default:
            break
        }
    }
    
    //MARK: - Handle movements
    private func touchShouldBeganWith(location: CGPoint) -> Bool {
        print("began \(location)")
        let nearLower = distance(location, thumbLower.center) < 22
        let nearUpper = distance(location, thumbUpper.center) < 22
        
        switch (nearLower, nearUpper) {
        case (true, true):
            let lower = distance(location, thumbLower.center) < distance(location, thumbUpper.center)
            activeThumb = lower ? .lower : .upper
        case (true, false):
            activeThumb = .lower
        case (false, true):
            activeThumb = .upper
        default:
            break
        }
        
        return activeThumb != nil
    }
    
    private func touchContinuesWith(location: CGPoint) {
        print("move \(location)")
        
        switch activeThumb {
        case .lower:
            lowerValue = value(for: location.x)
        case .upper:
            upperValue = value(for: location.x)
        default:
            assertionFailure("should not continue touch without active thumb")
        }
        
        if isContinuous {
            sendActions(for: .valueChanged)
        }
    }
    
    private func touchEnded() {
        activeThumb = nil
        print("values changed: \(lowerValue), \(upperValue)")
        sendActions(for: .valueChanged)
    }
    
    //MARK: - Helpers
    func locationX(for value: Double) -> CGFloat {
        let value = clamp(value, minimum, maximum)
        let result = (value - minimum) / (maximum - minimum) * Double(frame.width)
        return CGFloat(result)
    }
    
    func value(for locationX: CGFloat) -> Double {
        let locationX = clamp(locationX, 0, frame.width)
        let accurateValue = minimum + Double(locationX) / Double(frame.width) * (maximum - minimum)
        
        if let stepValue = stepValue {
            let calibratedValue = round(accurateValue / stepValue) * stepValue
            return calibratedValue
        } else {
            return accurateValue
        }
    }
}

fileprivate func clamp<T>(_ arg: T, _ limit1: T, _ limit2: T) -> T where T: Comparable {
    let minimum = min(limit1, limit2)
    let maximum = max(limit1, limit2)
    return min(maximum, max(minimum, arg))
}

fileprivate func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
    return sqrt( pow(lhs.x - rhs.x, 2) + pow(lhs.y - rhs.y, 2) )
}
