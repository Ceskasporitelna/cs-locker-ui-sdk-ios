//
//  GestureLockView.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 06.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit
import CSCoreSDK

//==============================================================================
class GesturePoint: UIView
{
    
    static let LineWidth:CGFloat           = 2.0
    static let InnerLineWidth:CGFloat      = 3.0
    static let InnerCircleDistance:CGFloat = 12.0
    static let colorSpace:CGColorSpace  = CGColorSpaceCreateDeviceRGB()

    var selected:      Bool    = false
    var index:         Int     = 0
    var normalColor:   CGColor = UIColor.init(hexString: "9D0019").cgColor
    var selectedColor: CGColor = UIColor.init(hexString: "D0334C").cgColor
    var gradientStartColor: CGColor = UIColor.init(hexString: "E1EBF1").cgColor
    var gradientEndColor:   CGColor = UIColor.init(hexString: "B2DCF2").cgColor
    
    //--------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView() {
        self.backgroundColor = UIColor.clear
        self.layer.shadowRadius = 5.0
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.6
//        self.accessibilityElementsHidden = true
    }
    
    //--------------------------------------------------------------------------
    override func draw(_ rect: CGRect) {
        let smallRect = rect.insetBy(dx: type(of: self).LineWidth, dy: type(of: self).LineWidth)
        let innerRect = smallRect.insetBy(dx: type(of: self).InnerCircleDistance, dy: type(of: self).InnerCircleDistance)
        let color     = self.selected ? selectedColor : normalColor
        self.drawCircleInRect(smallRect, lineWidth:type(of: self).LineWidth, color: color, fill: true)
        
        if self.selected {
            self.drawInnerGradient(innerRect)
            self.drawCircleInRect(innerRect, lineWidth:type(of: self).InnerLineWidth, color: color, fill: false)
        }
    }
    
    //--------------------------------------------------------------------------
    func drawCircleInRect(_ rect: CGRect, lineWidth: CGFloat, color: CGColor, fill: Bool) {
        let path      = UIBezierPath(ovalIn: rect)
        let context   = UIGraphicsGetCurrentContext()
        
        path.lineWidth = lineWidth
        context!.setStrokeColor(color)
        path.stroke()
        
        if fill {
            let fillColor = color.copy(alpha: 0.05)
            context!.setFillColor(fillColor!)
            path.fill()
        }
    }
    
    //--------------------------------------------------------------------------
    func drawInnerGradient(_ rect: CGRect)
    {
        guard let context = UIGraphicsGetCurrentContext() else {
            clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.error, format: "Can't obtain UIGraphicsGetCurrentContext()!" )
            return
        }
        
        let path      = UIBezierPath(ovalIn: rect)
        path.lineWidth = type(of: self).InnerLineWidth
        let colors = [gradientStartColor, gradientEndColor]
        
        // Clip the path
        context.saveGState()
        path.addClip()
        
        let colorLocations:[CGFloat] = [0.0, 1.0]
        let gradient   = CGGradient(colorsSpace: type(of: self).colorSpace, colors: colors as CFArray, locations: colorLocations)
        let startPoint = rect.origin
        let endPoint   = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        context.drawLinearGradient(gradient!,
            start: startPoint,
            end: endPoint,
            options: CGGradientDrawingOptions(rawValue: 0))
        
        context.restoreGState()
    }
    
    //--------------------------------------------------------------------------
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let path = UIBezierPath(ovalIn: self.bounds)
        if path.contains(point) {
            return self
        }
        return nil
    }
}

//==============================================================================
@IBDesignable class GestureLockView: UIView {
    
    static let LineWidth:CGFloat = 8.0
    
    var trackPoint:    CGPoint? = nil
    var dotViews:      [GesturePoint] = [] // Only used for IB
    var selectedViews: [GesturePoint] = []
    var callback:      ((_ key: String) -> Void)?
    
//    @IBInspectable var matrixSize: Int = 3 {
//        didSet {
//            refreshDots()
//        }
//    }
    
    @IBInspectable var matrixWidth: Int = 4 {
        didSet {
            refreshDots()
        }
    }
    
    @IBInspectable var matrixHeight: Int = 3 {
        didSet {
            refreshDots()
        }
    }
    
    @IBInspectable var dotSize: CGFloat = 40.0 {
        didSet {
            refreshDots()
        }
    }
    
    @IBInspectable var dotColor: UIColor = UIColor.init(hexString: "9D0019") {
        didSet {
           refreshDots()
        }
    }
    
    @IBInspectable var selectedDotColor: UIColor = UIColor.init(hexString: "D0334C") {
        didSet {
            refreshDots()
        }
    }
    
    @IBInspectable var lineColor: UIColor = UIColor.init(hexString: "FF667F") {
        didSet {
            refreshDots()
        }
    }
    
    //--------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    //--------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let space   = self.dotSize * 0.875
        let width   = CGFloat(self.matrixWidth) * self.dotSize + CGFloat(self.matrixWidth + 1) * space
        let height  = CGFloat(self.matrixHeight) * self.dotSize + CGFloat(self.matrixHeight + 1) * space
        self.bounds = CGRect(x:0.0, y:0.0, width: width, height: height)
        
        self.setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView() {
        self.backgroundColor = UIColor.clear
        trackPoint = CGPoint(x: 0,y: 0)
    }
    
    //--------------------------------------------------------------------------
    override func draw(_ rect: CGRect) {
        if let point = self.trackPoint, !self.selectedViews.isEmpty {
            
            let context = UIGraphicsGetCurrentContext()
            context!.setLineWidth(type(of: self).LineWidth)
            context!.setStrokeColor(self.lineColor.cgColor)
            
            // Connect the dots
            var lastDot: UIView? = nil
            for dotView in self.selectedViews {
                let cnt = dotView.center
                if lastDot != nil {
                    context!.addLine(to: CGPoint(x: cnt.x, y: cnt.y))
                } else {
                    context!.move(to: CGPoint(x: cnt.x, y: cnt.y))
                }
                lastDot = dotView
            }
            
            // The ending
            context!.addLine(to: CGPoint(x: point.x, y: point.y))
            context!.strokePath()
            
            trackPoint = nil
        }
        
        #if TARGET_INTERFACE_BUILDER
            var index = 0
            for pt in self.dotViews {
                pt.drawRect(self.rectForDot(rect, index: index))
                ++index
            }
        #endif
    }
    
    //--------------------------------------------------------------------------
    func refreshDots() {
        _ = self.subviews.map({ $0.removeFromSuperview() })
        self.dotViews.removeAll()
        self.createDots(self.bounds)
    }
    
    //--------------------------------------------------------------------------
    func createDots(_ frame: CGRect) {
        for i in 0..<matrixHeight {
            for j in 0..<matrixWidth {
                
                var index = 0
                
                if matrixWidth > matrixHeight {
                    index             = i * matrixWidth + j
                }   else if matrixHeight > matrixWidth {
                    index             = j * matrixHeight + i
                } else {
                    index             = i * matrixHeight + j
                }
                
                let pt                = GesturePoint(frame: self.rectForDot(frame, index: index))
                pt.index              = index
                pt.normalColor        = self.dotColor.cgColor
                pt.selectedColor      = self.selectedDotColor.cgColor
                #if !TARGET_INTERFACE_BUILDER
                    pt.gradientStartColor     = UIColor.white.cgColor
                    pt.gradientEndColor       = LockerUI.internalSharedInstance.lightColor.cgColor
//                    pt.accessibilityLabel     = String( format: LockerUI.localized("fmt-gesture"), i % matrixSize + 1, j % matrixSize + 1 )
                    addSubview(pt)
                #else
                    dotViews.append(pt)
                    if index % 3 == 1 {
                        addDotView(pt)
                    }
                #endif
            }
        }
    }
    
    //--------------------------------------------------------------------------
    func rectForDot(_ rect: CGRect, index: Int) -> CGRect {
        let w = frame.size.width  / CGFloat(matrixWidth)
        let h = frame.size.height / CGFloat(matrixHeight)
        
        let size  = dotSize
        let rect  = CGRect(x: 0, y: 0, width: size, height: size)
        let i     = CGFloat(index / matrixHeight)
        let j     = CGFloat(index % matrixHeight)
        let x     = h * (i + 0.5) - 0.5 * size
        let y     = w * (j + 0.5) - 0.5 * size
        let moved = rect.offsetBy(dx: x, dy: y)
        
        return moved
    }
    
    //--------------------------------------------------------------------------
    func addDotView(_ view: GesturePoint) {
        self.selectedViews.append(view)
        view.selected = true
        self.bringSubview(toFront: view)
        view.setNeedsDisplay()
    }
    
    //--------------------------------------------------------------------------
    func clearDotViews() {
        for view in self.selectedViews {
            view.selected = false
            view.setNeedsDisplay()
        }
        self.selectedViews.removeAll()
    }
    
    //--------------------------------------------------------------------------
    func drawLineFromLastDotTo(_ point: CGPoint) -> Void {
        trackPoint = point
        self.setNeedsDisplay()
    }
    
    //--------------------------------------------------------------------------
    func processTouches(_ touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.trackPoint = touches.first?.location(in: self)
        let touched = self.hitTest(self.trackPoint!, with: event)
        
        if let dot = touched as? GesturePoint , !self.selectedViews.contains(dot) {
            self.addDotView(dot)
        }
        
        self.setNeedsDisplay()
    }
    
    //--------------------------------------------------------------------------
    override func layoutSubviews() {
        self.backgroundColor = UIColor.clear
    }
    
    //--------------------------------------------------------------------------
    override var intrinsicContentSize : CGSize {
        return CGSize(width: 260, height: 260)
    }

    //--------------------------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.processTouches(touches, withEvent: event)
    }
    
    //--------------------------------------------------------------------------
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.processTouches(touches, withEvent: event)
    }
    
    //--------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let key = self.selectedViews.reduce("", {  $0 + String(format: "%02d", $1.index) })
        if let callback = self.callback {
            callback(key)
        }
        
        self.clearDotViews()
        self.setNeedsDisplay()
    }
    
}
