//
//  KeypadView.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 11.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

@IBDesignable class KeypadView: UIView
{

    @IBOutlet var verticalGapConstraints: [NSLayoutConstraint]!
    @IBOutlet var horizontalGapConstraints: [NSLayoutConstraint]!
    
    
    @IBOutlet var      buttons:       [UIView]!
    @IBOutlet weak var deleteButton:  TextPadButton!
    @IBOutlet weak var swapViewButton: SwapViewsButton!
    
    @IBOutlet weak var padView: UIView!
    
    
    @IBOutlet weak var padWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var padHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var padLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var padTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var button1TopConstraint: NSLayoutConstraint!
    @IBOutlet weak var button1LeadingConstraint: NSLayoutConstraint!
    
    var view:              UIView!
    var buttonCallback:    ((Int) -> Void)?
    
    var buttonTextColor: UIColor = UIColor(hexString: "#115E92") {
        didSet {
            self.deleteButton.textColor = self.buttonTextColor
        }
    }
    
    var padBackgroundColor: UIColor = UIColor.clear {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    class var baseSize: CGSize {
        return _baseSize
    }
    fileprivate static let _baseSize = (UIDevice.current.isSmallDevice ? CGSize(width: 260.0, height: 290.0) : CGSize(width: 270.0, height: 320.0))
    
    var viewSize        = baseSize
    

    let HorizontalButtonGap: CGFloat = 25.0
    let VerticalButtonGap: CGFloat   = 17.0
    let DefaultButtonSize: CGFloat   = 60.0
    let DefaultMargin: CGFloat       = 10.0//20.0
    
    //--------------------------------------------------------------------------
    var buttonSize: CGFloat = 60.0 {
        didSet {
            self.setupButtons()
            
            self.button1TopConstraint.constant     = DefaultMargin
            self.button1LeadingConstraint.constant = DefaultMargin
            
            let horizontalGap = round(self.buttonSize * HorizontalButtonGap/DefaultButtonSize)
            for constraint in self.horizontalGapConstraints {
                constraint.constant = horizontalGap
            }
            
            let verticalGap   = round(self.buttonSize * VerticalButtonGap/DefaultButtonSize)
            for constraint in self.verticalGapConstraints {
                constraint.constant = verticalGap
            }
            
            self.viewSize                        = CGSize(width: self.buttonSize * 3.0 + horizontalGap * 2.0 + DefaultMargin * 2.0,
                                                              height: self.buttonSize * 4.0 + verticalGap * 3.0 + DefaultMargin * 2.0)
            
            //self.bounds                        = CGRect(x:0.0, y:0.0, width: self.viewSize.width, height:self.viewSize.height)
            self.bounds                        = CGRect(x: 0.0, y: 0.0, width: type(of: self).baseSize.width, height: type(of: self).baseSize.height)
            self.padWidthConstraint.constant   = self.viewSize.width
            self.padHeightConstraint.constant  = self.viewSize.height
            
            self.padTopConstraint.constant     = (self.bounds.height - self.viewSize.height)/2.0
            if ( self.padTopConstraint.constant < 0.0 ) {
                self.padTopConstraint.constant = 0.0
            }
            
            self.padLeadingConstraint.constant = (self.bounds.width - self.viewSize.width)/2.0
            if ( self.padLeadingConstraint.constant < 0.0 ) {
                self.padLeadingConstraint.constant = 0.0
            }
            
            self.padView.setNeedsUpdateConstraints()
            self.padView.setNeedsLayout()
            
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
        }
    }
    
    //--------------------------------------------------------------------------
    var numberLabelFont: UIFont = UIFont(name: "AvenirNext-Medium", size: 32)! {
        didSet {
            self.setupButtons()
        }
    }
    
    //--------------------------------------------------------------------------
    var lettersLabelFont = UIFont(name: "AvenirNext-Regular", size: 14)! {
        didSet {
            self.setupButtons()
        }
    }
    
    //--------------------------------------------------------------------------
    var textLabelFont = UIFont(name: "AvenirNext-Bold", size: 12)! {
        didSet {
            self.setupButtons()
        }
    }
   
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
        self.setupView()
    }
    
    //--------------------------------------------------------------------------
    func setupView()
    {
        self.view                              = self.loadViewFromNib()
        
        self.view.frame                        = self.bounds
        self.view.autoresizingMask             = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        self.addSubview(self.view)
        
        self.deleteButton.textColor            = self.buttonTextColor
        self.deleteButton.accessibilityLabel   = LockerUI.localized( "btn-pad-delete" )
        self.deleteButton.accessibilityHint    = LockerUI.localized( "btn-pad-delete-hint" )
        self.swapViewButton.accessibilityLabel = LockerUI.localized( "btn-swap-views" )
        self.swapViewButton.accessibilityHint  = LockerUI.localized( "btn-swap-views-hint" )
        
        self.padView.layer.cornerRadius        = 5.0
        
        self.setNeedsUpdateConstraints()
    }
    
    //--------------------------------------------------------------------------
    func loadViewFromNib() -> UIView
    {
        let bundle = LockerUI.getBundle()
        let nib    = UINib(nibName: "KeypadView", bundle: bundle)
        let view   = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view
    }
    
    //--------------------------------------------------------------------------
    func setupButtons()
    {
        for button in self.buttons {
            if let padButton = button as? PadButton {
                padButton.size = self.buttonSize
            }
            if let padButton = button as? NumberPadButton {
                padButton.numberLabelFont  = self.numberLabelFont
                padButton.lettersLabelFont = self.lettersLabelFont
            }
            if let swapButton = button as? SwapViewsButton {
                swapButton.size = self.buttonSize
            }
            if let textButton = button as? TextPadButton {
                textButton.labelFont = self.textLabelFont
            }
        }
    }
    
    //--------------------------------------------------------------------------
    @IBAction func buttonAction(_ sender: UIButton)
    {
        self.buttonCallback?(sender.tag)
    }

    //--------------------------------------------------------------------------
    override var intrinsicContentSize : CGSize
    {
        //return self.viewSize
        return type(of: self).baseSize
    }
    
    //--------------------------------------------------------------------------
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.backgroundColor               = UIColor.clear
        self.view.backgroundColor          = UIColor.clear
        self.padView.layer.backgroundColor = self.padBackgroundColor.cgColor
    }
}
