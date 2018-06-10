//
//  KDCircularProgress.swift
//  KDCircularProgress
//
//  Created by Kaan Dedeoglu on 1/14/15.
//  Copyright (c) 2015 Kaan Dedeoglu. All rights reserved.
//
// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa

public enum KDCircularProgressGlowMode {
    case forward, reverse, constant, noGlow
}

@IBDesignable
public class KDCircularProgress: NSView, CAAnimationDelegate {
    
    private struct ConversionFunctions {
        static func DegreesToRadians (_ value:CGFloat) -> CGFloat {
            return value * CGFloat.pi / 180.0
        }
        
        static func RadiansToDegrees (_ value:CGFloat) -> CGFloat {
            return value * 180.0 / CGFloat.pi
        }
    }
    
    private struct UtilityFunctions {
        static func Clamp<T: Comparable>(_ value: T, minMax: (T, T)) -> T {
            let (min, max) = minMax
            if value < min {
                return min
            } else if value > max {
                return max
            } else {
                return value
            }
        }
        
        static func Mod(_ value: Int, range: Int, minMax: (Int, Int)) -> Int {
            let (min, max) = minMax
            assert(abs(range) <= abs(max - min), "range should be <= than the interval")
            if value >= min && value <= max {
                return value
            } else if value < min {
                return Mod(value + range, range: range, minMax: minMax)
            } else {
                return Mod(value - range, range: range, minMax: minMax)
            }
        }
    }
    
    private var progressLayer: KDCircularProgressViewLayer! {
        get {
            return layer as? KDCircularProgressViewLayer
        }
    }
    
    private var radius: CGFloat! {
        didSet {
            progressLayer.radius = radius
        }
    }
    
    @IBInspectable public var angle: Int = 0 {
        didSet {
            if self.isAnimating() {
                self.pauseAnimation()
            }
            progressLayer.angle = angle
        }
    }
    
    @IBInspectable public var startAngle: Int = 0 {
        didSet {
            progressLayer.startAngle = UtilityFunctions.Mod(startAngle, range: 360, minMax: (0,360))
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var clockwise: Bool = true {
        didSet {
            progressLayer.clockwise = clockwise
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var roundedCorners: Bool = true {
        didSet {
            progressLayer.roundedCorners = roundedCorners
        }
    }
    
    @IBInspectable public var gradientRotateSpeed: CGFloat = 0 {
        didSet {
            progressLayer.gradientRotateSpeed = gradientRotateSpeed
        }
    }
    
    @IBInspectable public var glowAmount: CGFloat = 1.0 {//Between 0 and 1
        didSet {
            progressLayer.glowAmount = UtilityFunctions.Clamp(glowAmount, minMax: (0, 1))
        }
    }
    
    public var glowMode: KDCircularProgressGlowMode = .forward {
        didSet {
            progressLayer.glowMode = glowMode
        }
    }
    
    @IBInspectable public var progressThickness: CGFloat = 0.4 {//Between 0 and 1
        didSet {
            progressThickness = UtilityFunctions.Clamp(progressThickness, minMax: (0, 1))
            progressLayer.progressThickness = progressThickness/2
        }
    }
    
    @IBInspectable public var trackThickness: CGFloat = 0.5 {//Between 0 and 1
        didSet {
            trackThickness = UtilityFunctions.Clamp(trackThickness, minMax: (0, 1))
            progressLayer.trackThickness = trackThickness/2
        }
    }
    
    @IBInspectable public var trackColor: NSColor = NSColor.black {
        didSet {
            progressLayer.trackColor = trackColor
            progressLayer.setNeedsDisplay()
        }
    }
    
    @IBInspectable public var progressInsideFillColor: NSColor? = nil {
        didSet {
            if let color = progressInsideFillColor {
                progressLayer.progressInsideFillColor = color
            } else {
                progressLayer.progressInsideFillColor = NSColor.clear
            }
        }
    }
    
    @IBInspectable public var progressColors: [NSColor]! {
        get {
            return progressLayer.colorsArray
        }
        
        set(newValue) {
            setColors(newValue)
        }
    }
    
    //These are used only from the Interface-Builder. Changing these from code will have no effect.
    //Also IB colors are limited to 3, whereas programatically we can have an arbitrary number of them.
    @objc @IBInspectable private var IBColor1: NSColor?
    @objc @IBInspectable private var IBColor2: NSColor?
    @objc @IBInspectable private var IBColor3: NSColor?
    
    
    private var animationCompletionBlock: ((Bool) -> Void)?
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer = KDCircularProgressViewLayer()
        self.layerContentsRedrawPolicy = .duringViewResize
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
    }
    
    convenience public init(frame:CGRect, colors: NSColor...) {
        self.init(frame: frame)
        setColors(colors)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.wantsLayer = true
        self.layer = KDCircularProgressViewLayer()
        self.layerContentsRedrawPolicy = .duringViewResize
        translatesAutoresizingMaskIntoConstraints = false
        setInitialValues()
        refreshValues()
    }

    public override func awakeFromNib() {
        checkAndSetIBColors()
    }

    private func setInitialValues() {
        radius = (frame.size.width/2.0) * 0.8 //We always apply a 20% padding, stopping glows from being clipped
        //backgroundColor = .clearColor()
        setColors(NSColor.white, NSColor.red)
    }
    
    private func refreshValues() {
        progressLayer.angle = angle
        progressLayer.startAngle = UtilityFunctions.Mod(startAngle, range: 360, minMax: (0,360))
        progressLayer.clockwise = clockwise
        progressLayer.roundedCorners = roundedCorners
        progressLayer.gradientRotateSpeed = gradientRotateSpeed
        progressLayer.glowAmount = UtilityFunctions.Clamp(glowAmount, minMax: (0, 1))
        progressLayer.glowMode = glowMode
        progressLayer.progressThickness = progressThickness/2
        progressLayer.trackColor = trackColor
        progressLayer.trackThickness = trackThickness/2
    }
    
    private func checkAndSetIBColors() {
        let nonNilColors = [IBColor1, IBColor2, IBColor3].filter { $0 != nil}.map { $0! }
        if nonNilColors.count > 0 {
            setColors(nonNilColors)
        }
    }
    
    public func setColors(_ colors: NSColor...) {
        setColors(colors)
    }
    
    private func setColors(_ colors: [NSColor]) {
        progressLayer.colorsArray = colors
        progressLayer.setNeedsDisplay()
    }
    
    public func animateFromAngle(_ fromAngle: Int, toAngle: Int, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        
        let animationDuration: TimeInterval
        if relativeDuration {
            animationDuration = duration
        } else {
            let traveledAngle = UtilityFunctions.Mod(toAngle - fromAngle, range: 360, minMax: (0, 360))
            let scaledDuration = (TimeInterval(traveledAngle) * duration) / 360
            animationDuration = scaledDuration
        }
        
        let animation = CABasicAnimation(keyPath: "angle")
        animation.fromValue = fromAngle
        animation.toValue = toAngle
        animation.duration = animationDuration
        animation.delegate = self
        angle = toAngle
        animationCompletionBlock = completion
        
        progressLayer.add(animation, forKey: "angle")
    }
    
    public func animateToAngle(_ toAngle: Int, duration: TimeInterval, relativeDuration: Bool = true, completion: ((Bool) -> Void)?) {
        if isAnimating() {
            pauseAnimation()
        }
        animateFromAngle(angle, toAngle: toAngle, duration: duration, relativeDuration: relativeDuration, completion: completion)
    }
    
    public func pauseAnimation() {
        guard let presentationLayer = progressLayer.presentation() else { return }
        let currentValue = presentationLayer.angle
        progressLayer.removeAllAnimations()
        animationCompletionBlock = nil
        angle = currentValue
    }
    
    public func stopAnimation() {
        progressLayer.removeAllAnimations()
        angle = 0
    }
    
    public func isAnimating() -> Bool {
        return progressLayer.animation(forKey: "angle") != nil
    }
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let completionBlock = animationCompletionBlock {
            completionBlock(flag)
            animationCompletionBlock = nil
        }
    }
    
    public override func prepareForInterfaceBuilder() {
        setInitialValues()
        refreshValues()
        checkAndSetIBColors()
        progressLayer.setNeedsDisplay()
    }
    
    private class KDCircularProgressViewLayer: CALayer {
        @NSManaged var angle: Int
        var radius: CGFloat! {
            didSet {
                invalidateGradientCache()
            }
        }
        var startAngle: Int!
        var clockwise: Bool! {
            didSet {
                if clockwise != oldValue {
                    invalidateGradientCache()
                }
            }
        }
        var roundedCorners: Bool!
        var gradientRotateSpeed: CGFloat! {
            didSet {
                invalidateGradientCache()
            }
        }
        var glowAmount: CGFloat!
        var glowMode: KDCircularProgressGlowMode!
        var progressThickness: CGFloat!
        var trackThickness: CGFloat!
        var trackColor: NSColor!
        var progressInsideFillColor: NSColor = NSColor.clear
        var colorsArray: [NSColor]! {
            didSet {
                invalidateGradientCache()
            }
        }
        private var gradientCache: CGGradient?
        private var locationsCache: [CGFloat]?
        
        private struct GlowConstants {
            private static let sizeToGlowRatio: CGFloat = 0.00015
            static func glowAmountForAngle(_ angle: Int, glowAmount: CGFloat, glowMode: KDCircularProgressGlowMode, size: CGFloat) -> CGFloat {
                switch glowMode {
                case .forward:
                    return CGFloat(angle) * size * sizeToGlowRatio * glowAmount
                case .reverse:
                    return CGFloat(360 - angle) * size * sizeToGlowRatio * glowAmount
                case .constant:
                    return 360 * size * sizeToGlowRatio * glowAmount
                default:
                    return 0
                }
            }
        }
        
        override class func needsDisplay(forKey key: String) -> Bool {
            return key == "angle" ? true : super.needsDisplay(forKey: key)
        }
        
        override init(layer: Any) {
            super.init(layer: layer)
            let progressLayer = layer as! KDCircularProgressViewLayer
            radius = progressLayer.radius
            angle = progressLayer.angle
            startAngle = progressLayer.startAngle
            clockwise = progressLayer.clockwise
            roundedCorners = progressLayer.roundedCorners
            gradientRotateSpeed = progressLayer.gradientRotateSpeed
            glowAmount = progressLayer.glowAmount
            glowMode = progressLayer.glowMode
            progressThickness = progressLayer.progressThickness
            trackThickness = progressLayer.trackThickness
            trackColor = progressLayer.trackColor
            colorsArray = progressLayer.colorsArray
            progressInsideFillColor = progressLayer.progressInsideFillColor
        }
        
        override init() {
            super.init()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
        }
        
        override func draw(in ctx: CGContext) {
            NSGraphicsContext.saveGraphicsState()
            let nsgc = NSGraphicsContext(cgContext: ctx, flipped: true)
            NSGraphicsContext.current = nsgc
            let rect = bounds
            let size = rect.size
            let center = CGPoint(x: CGFloat(size.width/2.0), y: CGFloat(size.height/2.0))

            let trackLineWidth: CGFloat = radius * trackThickness
            let progressLineWidth = radius * progressThickness
            let arcRadius = max(radius - trackLineWidth/2, radius - progressLineWidth/2)
            ctx.addArc(center: center, radius: arcRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: false)
            trackColor.set()
            ctx.setStrokeColor(trackColor.cgColor)
            ctx.setFillColor(progressInsideFillColor.cgColor)
            ctx.setLineWidth(trackLineWidth)
            ctx.setLineCap(CGLineCap.butt)
            ctx.drawPath(using: .fillStroke)

            let image = NSImage(size: size)
            image.lockFocus()
            let imageCtx = NSGraphicsContext.current?.cgContext
            let reducedAngle = UtilityFunctions.Mod(angle, range: 360, minMax: (0, 360))
            let fromAngle = ConversionFunctions.DegreesToRadians(CGFloat(-startAngle))
            let toAngle = ConversionFunctions.DegreesToRadians(CGFloat((clockwise == true ? -reducedAngle : reducedAngle) - startAngle))
            imageCtx?.addArc(center: center, radius: arcRadius, startAngle: fromAngle, endAngle: toAngle, clockwise: clockwise)
            let glowValue = GlowConstants.glowAmountForAngle(reducedAngle, glowAmount: glowAmount, glowMode: glowMode, size: size.width)
            if glowValue > 0 {
                imageCtx?.setShadow(offset: CGSize.zero, blur: glowValue, color: NSColor.black.cgColor)
            }
            imageCtx?.setLineCap(roundedCorners == true ? .round : .butt)
            imageCtx?.setLineWidth(progressLineWidth)
            imageCtx?.drawPath(using: .stroke)
            
            let drawMask: CGImage = imageCtx!.makeImage()!
            image.unlockFocus()
            
            ctx.saveGState()
            ctx.clip(to:bounds, mask: drawMask)
            
            //Gradient - Fill
            if colorsArray.count > 1 {
                var componentsArray: [CGFloat] = []
                let rgbColorsArray: [NSColor] = colorsArray.map {c in // Make sure every color in colors array is in RGB color space
                    if c.cgColor.numberOfComponents == 2 {
                        let whiteValue = c.cgColor.components?[0]
                        return NSColor(red: whiteValue!, green: whiteValue!, blue: whiteValue!, alpha: 1.0)
                    } else {
                        return c
                    }
                }
                
                for color in rgbColorsArray {
                    let colorComponents = color.cgColor.components!
                    componentsArray.append(contentsOf: [colorComponents[0],colorComponents[1],colorComponents[2],1.0])
                }
                
                drawGradientWithContext(ctx, componentsArray: componentsArray)
            } else {
                if colorsArray.count == 1 {
                    fillRectWithContext(ctx, color: colorsArray[0])
                } else {
                    fillRectWithContext(ctx, color: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
                }
            }
            NSGraphicsContext.restoreGraphicsState()
        }

        private func fillRectWithContext(_ ctx: CGContext!, color: NSColor) {
            ctx.setFillColor(color.cgColor)
            ctx.fill(bounds)
        }
        
        private func drawGradientWithContext(_ ctx: CGContext!, componentsArray: [CGFloat]) {
            let baseSpace = CGColorSpaceCreateDeviceRGB()
            let locations = locationsCache ?? gradientLocationsFromColorCount(componentsArray.count/4, gradientWidth: bounds.size.width)
            let gradient: CGGradient
            
            if let g = self.gradientCache {
                gradient = g
            } else {
                guard let g = CGGradient(colorSpace: baseSpace, colorComponents: componentsArray, locations: locations,count: componentsArray.count / 4) else { return }
                self.gradientCache = g
                gradient = g
            }
            
            let halfX = bounds.size.width/2.0
            let floatPi = CGFloat.pi
            let rotateSpeed = clockwise == true ? gradientRotateSpeed : gradientRotateSpeed * -1
            let angleInRadians = ConversionFunctions.DegreesToRadians(rotateSpeed! * CGFloat(angle) - 90)
            let oppositeAngle = angleInRadians > floatPi ? angleInRadians - floatPi : angleInRadians + floatPi
            
            let startPoint = CGPoint(x: (cos(angleInRadians) * halfX) + halfX, y: (sin(angleInRadians) * halfX) + halfX)
            let endPoint = CGPoint(x: (cos(oppositeAngle) * halfX) + halfX, y: (sin(oppositeAngle) * halfX) + halfX)
            
            ctx.drawLinearGradient(gradient, start: startPoint, end: endPoint, options: .drawsBeforeStartLocation)
        }
        
        private func gradientLocationsFromColorCount(_ colorCount: Int, gradientWidth: CGFloat) -> [CGFloat] {
            if colorCount == 0 || gradientWidth == 0 {
                return []
            } else {
                var locationsArray: [CGFloat] = []
                let progressLineWidth = radius * progressThickness
                let firstPoint = gradientWidth/2 - (radius - progressLineWidth/2)
                let increment = (gradientWidth - (2*firstPoint))/CGFloat(colorCount - 1)
                
                for i in 0..<colorCount {
                    locationsArray.append(firstPoint + (CGFloat(i) * increment))
                }
                assert(locationsArray.count == colorCount, "color counts should be equal")
                let result = locationsArray.map { $0 / gradientWidth }
                locationsCache = result
                return result
            }
        }
        
        private func invalidateGradientCache() {
            gradientCache = nil
            locationsCache = nil
        }
    }
}
