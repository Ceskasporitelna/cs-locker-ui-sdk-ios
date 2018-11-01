//
//  RoundedButtonView.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 01.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
@IBDesignable class RoundedButtonView: UIView
{
    @IBOutlet weak var button: UIButton!
    
    let buttonSelectedBackgroundColor: UIColor = UIColor.init(hexString: "9D0019")
    var view: UIView!
    var buttonTouchUpAction: ((UIButton) -> Void)?

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
        view = loadViewFromNib()
        
        view.frame = bounds
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
               addSubview(view)
        self.sendSubviewToBack(view)
        
        self.layer.cornerRadius  = 10.0
        self.layer.shadowColor   = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.6
        self.layer.shadowRadius  = 10.0
        self.layer.shadowOffset  = CGSize.init(width: 3.0, height: 3.0)
        
        self.button.setBackgroundColor(self.button.backgroundColor!, forUIControlState: UIControl.State())
        self.button.setBackgroundColor(buttonSelectedBackgroundColor, forUIControlState: UIControl.State.selected)
    }
    
    //--------------------------------------------------------------------------
    func loadViewFromNib() -> UIView
    {
        
        let bundle  = LockerUI.getBundle()
        let nib = UINib(nibName: "RoundedButtonView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    //--------------------------------------------------------------------------
    @IBAction func touchUpAction(_ sender: UIButton)
    {
        if let action = self.buttonTouchUpAction {
            action(sender)
        }
    }
    
    //--------------------------------------------------------------------------
    @IBInspectable var title:  String? {
        get {
            return self.button.titleLabel?.text
        }
        set(text) {
            self.button.setTitle(text, for: UIControl.State())
        }
    }
}
