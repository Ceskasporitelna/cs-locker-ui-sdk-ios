//
//  SolidColorButton.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 01.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
@IBDesignable class SolidColorButton: UIButton 
{
    @IBInspectable var selectedBackgroundColor:UIColor? = UIColor.init(hexString: "9D0019")
   
    //--------------------------------------------------------------------------
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView()
    {
        if let backgroundColor = self.backgroundColor {
            self.setBackgroundColor(backgroundColor, forUIControlState: UIControl.State())
        }
        if let selectedBackgroundColor = self.selectedBackgroundColor {
            self.setBackgroundColor(selectedBackgroundColor, forUIControlState: UIControl.State.selected)
        }
    }
}
