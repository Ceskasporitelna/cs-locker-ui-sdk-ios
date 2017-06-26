//
//  UIUtils.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 01.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
extension UIColor {
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    func colorWithHSB(_ hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> UIColor {
        var oldH: CGFloat = 0
        var oldS: CGFloat = 0
        var oldB: CGFloat = 0
        var oldA: CGFloat = 0
        self.getHue(&oldH, saturation: &oldS, brightness: &oldB, alpha: &oldA)
        return UIColor.init(hue: oldH + hue, saturation: oldS + saturation, brightness: oldB + brightness, alpha: oldA)
    }
    
    func maxBright() -> UIColor
    {
        var r:CGFloat = 0.0
        var g:CGFloat = 0.0
        var b:CGFloat = 0.0
        var a:CGFloat = 0.0
        
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let d:CGFloat = 1.0 - max(r,g,b)
            return UIColor(red: r + d, green: g + d , blue: b + d, alpha: 1.0)
        }
        return self
    }
}

//==============================================================================
extension UIButton {
    fileprivate func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    func setBackgroundColor(_ color: UIColor, forUIControlState state: UIControlState) {
        self.setBackgroundImage(imageWithColor(color), for: state)
    }
}

//==============================================================================
extension UIImage {    
    func imageWithTint(_ tint: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        
        // flip image
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // draw original image
        context.draw(self.cgImage!, in: rect)
        
        // tint image
        context.setBlendMode(CGBlendMode.color)
        tint.setFill()
        context.fill(rect)
        
        // mask by alpha values of original image
        context.setBlendMode(CGBlendMode.destinationIn)
        context.draw(self.cgImage!, in: rect)
                
        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imageWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()! as CGContext
        
        // flip image
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
//        // draw original image
//        CGContextDrawImage(context, rect, self.CGImage)
        
        // tint image
        context.setBlendMode(CGBlendMode.overlay)
        color.setFill()
        context.fill(rect)
        
        // mask by alpha values of original image
        context.setBlendMode(CGBlendMode.destinationIn)
        context.draw(self.cgImage!, in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func imageWithAlpha(_ alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(at: CGPoint.zero, blendMode: CGBlendMode.normal, alpha: alpha)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()! as UIImage
        UIGraphicsEndImageContext()
        return newImage
    }
}

//==============================================================================
extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
    var isIphone4: Bool {
        if modelName == "iPhone 4" || modelName == "iPhone 4s" {
            return true
        }
        if modelName == "Simulator" {
            let screenSize: CGRect = UIScreen.main.bounds
            return max(screenSize.width, screenSize.height) <= 480
        }
        return false
    }
    
    var isIphone5: Bool {
        if ( self.modelName.contains("iPhone 5") || self.modelName.contains("iPhone SE")) {
            return true
        }
        if (self.modelName == "Simulator") {
            let screenSize: CGRect = UIScreen.main.bounds
            let maxDimension       = max(screenSize.width, screenSize.height)
            return (maxDimension > 480 && maxDimension <= 568)
        }
        return false
    }
    
    var isSmallDevice: Bool {
        let screenSize: CGRect = UIScreen.main.bounds
        let maxDimension       = max(screenSize.width, screenSize.height)
        if ( maxDimension < 570 ) {
            return true
        }
        return false
    }
    
    var isSmallPhone: Bool {
        return self.isPhone && self.isSmallDevice
    }
    
    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
    }
    
    var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone
    }
    
    var isLandscape: Bool {
        let orientation = UIApplication.shared.statusBarOrientation
        return (orientation != .portrait && orientation != .portraitUpsideDown)
    }
}
