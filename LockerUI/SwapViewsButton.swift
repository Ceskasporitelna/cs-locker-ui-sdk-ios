//
//  SwapViewsButton.swift
//  CSLockerUI
//
//  Created by Vladimír Nevyhoštěný on 22/07/16.
//  Copyright © 2016 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
@IBDesignable class SwapViewsButton: UIButton
{
    let DefaultSize: CGFloat = 60.0
    
    var buttonImage: UIImage!
    var buttonImageView: UIImageView!
    var animationDuration = 0.15
    var size: CGFloat     = 60.0 {
        didSet {
            for constraint in self.constraints {
                constraint.constant = self.size
            }
            
            if ( self.buttonImageView != nil ) {
                self.buttonImageView.removeFromSuperview()
                self.buttonImageView = nil
            }
            
            self.layoutSubviews()
        }
    }
    
    //--------------------------------------------------------------------------
    @IBInspectable var borderColor:UIColor = UIColor.white {
        didSet {
            self.setupView()
        }
    }
    
    //--------------------------------------------------------------------------
    @IBInspectable var selectedColor:UIColor = UIColor.lightGray {
        didSet {
            self.setupView()
        }
    }
    
    //--------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    //--------------------------------------------------------------------------
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView()
    {
        self.bounds                             = CGRect(x: 0, y: 0, width: self.size, height: self.size)
        self.layer.borderWidth                  = 1.5
        self.layer.borderColor                  = self.borderColor.cgColor
        
        var frame               = self.frame
        frame.size.width        = self.size
        frame.size.height       = self.size
        self.frame              = frame
    }
    
    //--------------------------------------------------------------------------
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.frame.size.height / 2.0 // Makes the button round
        
        if ( self.buttonImage == nil ) {
            self.buttonImage = UIImage(named: "switch-hand", in: LockerUI.getBundle(), compatibleWith: nil)
        }
        
        if ( self.buttonImageView == nil ) {
            self.buttonImageView                    = UIImageView(image: self.buttonImage.imageWithColor(self.borderColor))
            self.layer.cornerRadius                 = self.frame.size.height / 2.0 // Makes the button round
            self.buttonImageView.layer.cornerRadius = self.layer.cornerRadius
            
            let pictureSize                         = round(self.buttonImageView.bounds.width/DefaultSize * self.size)
            let delta: CGFloat                      = round((self.size - pictureSize)/2.0)
            self.buttonImageView.frame              = CGRect(x: delta, y: delta, width: self.size - 2.0 * delta, height: self.size - 2.0 * delta)
            self.addSubview(self.buttonImageView)
            self.bringSubview(toFront: self.buttonImageView)
        }
    }
    
    //--------------------------------------------------------------------------
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: UIViewKeyframeAnimationOptions(), animations: { 
            self.layer.borderColor     = self.selectedColor.cgColor
            self.buttonImageView.image = self.buttonImage.imageWithColor(self.selectedColor)
            self.isHighlighted           = true
            }, completion: nil)
    }
    
    //--------------------------------------------------------------------------
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesEnded(touches, with: event)
        UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: UIViewKeyframeAnimationOptions.allowUserInteraction, animations: { 
            self.layer.borderColor     = self.borderColor.cgColor
            self.buttonImageView.image = self.buttonImage.imageWithColor(self.borderColor)
            self.isHighlighted           = false
            }, completion: nil)
    }
    
    //--------------------------------------------------------------------------
    override var intrinsicContentSize : CGSize
    {
        return CGSize(width: self.size, height: self.size)
    }
    
    
    
    
}
