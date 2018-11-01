//
//  PadButton.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 11.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
@IBDesignable class PadButton: UIButton {
    
    var selectedView      = UIView()
    var animationDuration = 0.15
    var size: CGFloat     = 60.0 {
        didSet {
            for constraint in self.constraints {
                constraint.constant = self.size
            }
        }
    }
    
    //--------------------------------------------------------------------------
    @IBInspectable var borderColor:UIColor = UIColor.white {
        didSet {
            setupView()
        }
    }
    
    //--------------------------------------------------------------------------
    @IBInspectable var selectedColor:UIColor = UIColor.lightGray {
        didSet {
            setupView()
        }
    }
    
    //--------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView() {
        self.layer.borderWidth            = 1.5
        self.layer.borderColor            = self.borderColor.cgColor
        self.selectedView.alpha           = 0
        self.selectedView.backgroundColor = self.selectedColor
    }
    
    //--------------------------------------------------------------------------
    override func layoutSubviews() {
        self.layer.cornerRadius = self.frame.size.height / 2 // Makes the button round
        self.selectedView.layer.cornerRadius = self.layer.cornerRadius
        self.selectedView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)

        self.addSubview(self.selectedView)
    }
           
    //--------------------------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: UIView.KeyframeAnimationOptions(), animations: { () -> Void in
            self.selectedView.alpha = 1
            self.isHighlighted        = true
            }, completion: nil)
    }
    
    //--------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: UIView.KeyframeAnimationOptions.allowUserInteraction, animations: { () -> Void in
            self.selectedView.alpha = 0
            self.isHighlighted        = false
            }, completion: nil)
    }
    
    //--------------------------------------------------------------------------
    override var intrinsicContentSize : CGSize
    {
        return CGSize(width: self.size, height: self.size)
    }
}
