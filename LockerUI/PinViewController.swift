//
//  PinViewController.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 09.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit
import CSCoreSDK
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


//==============================================================================
class PinViewController: LockerPasswordViewController
{
    // Info Base View ...
    
    @IBOutlet var infoBaseViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var infoBaseViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseView: UIView!
    
    // Keypad View ...
    
    @IBOutlet var keypadViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var keypadViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var keypadBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var selectionView: PadSelectionView!
    @IBOutlet weak var keypadView: KeypadView!
    
    
    var key: String = ""
    var keyHandler: ((_ key: String) -> ())?
    
    fileprivate var lastUIHandOrientation: UIHandOrientation?
    
    var leftInfoViewLandscapeConstraint: CGFloat {
        return MinConstraint * -1.0
    }
    
    var rightInfoViewLandscapeConstraint: CGFloat {
        return MinConstraint * 1.0
    }
    
    var leftKeypadLandscapeConstraint: CGFloat {
        return (UIDevice.current.isSmallDevice ? 0.0 : MinConstraint )
    }
    
    var rightKeypadLandscapeConstraint: CGFloat {
        return (UIDevice.current.isSmallDevice ? 0.0 : MinConstraint )
    }
    
    //--------------------------------------------------------------------------
    var selectedPoints: Int {
        get {
            return selectionView.value
        }
        set(value) {
            selectionView.value = value
            selectionView.setNeedsDisplay()
        }
    }
    
    //--------------------------------------------------------------------------
    var numericPasswordLength: Int = 6 {
        didSet {
            self.selectionView.points = self.numericPasswordLength
            self.selectionView.setNeedsLayout()
        }
    }
    
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder )
        self.passwordLength = 6
    }
    
    //--------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.keypadView.buttonCallback  = keyPressed
        
        self.lastPassword = nil
        self.newPassword = nil
        
        self.refreshPasswordDialog()
        
        self.setDeleteButtonAppearance()
        self.numericPasswordLength = self.passwordLength!
        
    #if !TARGET_INTERFACE_BUILDER
        self.selectionView.color = LockerUI.internalSharedInstance.lightColor
    #endif
        
        // For UI tweaks. Don't remove, just comment ...
        
//        self.infoBaseView.layer.borderColor       = UIColor.whiteColor().CGColor
//        self.infoBaseView.layer.borderWidth       = 1.0
//        self.keypadView.padView.layer.borderColor = UIColor.whiteColor().CGColor
//        self.keypadView.padView.layer.borderWidth = 0.25
//        self.keypadView.layer.borderColor         = UIColor.whiteColor().CGColor
//        self.keypadView.layer.borderWidth         = 1.0
    }
    
    //--------------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
        self.updateConstraintsWithScreenSize()
    }
    
    //--------------------------------------------------------------------------
    func activateConstraintsWithRespectToCurrentUIHandOrientation()
    {
        self.lastUIHandOrientation = LockerUI.sharedInstance.currentUIHandOrientation
        
        switch ( self.lastUIHandOrientation! ) {
        case .right:
            self.infoBaseViewTrailingConstraint.isActive = false
            self.infoBaseViewLeadingConstraint.isActive  = true
            self.keypadViewLeadingConstraint.isActive    = false
            self.keypadViewTrailingConstraint.isActive   = true
            
        case .left:
            self.infoBaseViewTrailingConstraint.isActive = true
            self.infoBaseViewLeadingConstraint.isActive  = false
            self.keypadViewLeadingConstraint.isActive    = true
            self.keypadViewTrailingConstraint.isActive   = false
        }
    }
    
    //--------------------------------------------------------------------------
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(alongsideTransition: { _ in
            self.updateConstraintsWithScreenSize()
        }, completion: nil)
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    //--------------------------------------------------------------------------
    func setupKeypad( _ isLandscape: Bool )
    {
        if ( isLandscape && UIDevice.current.isPhone ) {
            // iPhone landscape device orientation ...
            if ( UIDevice.current.isSmallDevice ) {
                self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 24)!
                self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 9)!
                self.keypadView.textLabelFont                  = UIFont(name: "AvenirNext-Bold", size: 9)!
                
                NumberPadButton.LettersOffset                  = 26
                NumberPadButton.NumberOffset                   = 4
                self.keypadView.buttonSize                     = 48.0
                
                self.keypadBottomConstraint.constant           = 0
                self.infoLabel.numberOfLines                   = 1
                self.infoLabel.adjustsFontSizeToFitWidth       = true
                self.infoDetailLabel.adjustsFontSizeToFitWidth = true
            }
            else if (UIDevice.current.isPhone) {
                self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 28)!
                self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 12)!
                self.keypadView.buttonSize                     = 58.0
            }
            else {
                self.keypadView.buttonSize                     = 65
            }
        }
        else {
            // Portrait device orientation ...
            
            if (UIDevice.current.isSmallDevice) {
                if (UIDevice.current.isIphone5) {
                    self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 28)!
                    self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 10)!
                    self.keypadView.textLabelFont                  = UIFont(name: "AvenirNext-Bold", size: 10)!
                    
                    NumberPadButton.LettersOffset                  = 28
                    NumberPadButton.NumberOffset                   = 6
                    self.keypadView.buttonSize                     = 54.0
                }
                else {
                    self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 24)!
                    self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 9)!
                    self.keypadView.textLabelFont                  = UIFont(name: "AvenirNext-Bold", size: 9)!
                    
                    NumberPadButton.LettersOffset                  = 26
                    NumberPadButton.NumberOffset                   = 4
                    self.keypadView.buttonSize                     = 48.0
                }
                
                self.keypadBottomConstraint.constant           = 0
                self.infoLabel.numberOfLines                   = 1
                self.infoLabel.adjustsFontSizeToFitWidth       = true
                self.infoDetailLabel.adjustsFontSizeToFitWidth = true
                
            }
            else if (UIDevice.current.isPhone) {
                self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 32)!
                self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 12)!
                self.keypadView.textLabelFont                  = UIFont(name: "AvenirNext-Bold", size: 12)!
                
                NumberPadButton.LettersOffset                  = 32
                NumberPadButton.NumberOffset                   = 8
                self.keypadView.buttonSize                     = 65.0
            }
            else {
                self.keypadView.numberLabelFont                = UIFont(name: "AvenirNext-Medium", size: 36)!
                self.keypadView.lettersLabelFont               = UIFont(name: "AvenirNext-Regular", size: 14)!
                self.keypadView.textLabelFont                  = UIFont(name: "AvenirNext-Bold", size: 14)!
                
                NumberPadButton.LettersOffset                  = 32
                NumberPadButton.NumberOffset                   = 8
                self.keypadView.buttonSize                     = 70.0
            }
        }
    }

    
    //--------------------------------------------------------------------------
    func updateConstraintsWithScreenSize()
    {
        //var size                                    = screenSize
        var size                                    = UIScreen.main.bounds.size
        let isLandscape                             = UIDevice.current.isLandscape
        let currentHandOrientation                  = LockerUI.sharedInstance.currentUIHandOrientation
        let isSmallDevice                           = UIDevice.current.isSmallDevice
        
        self.setupKeypad(isLandscape)
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            
            size.height                                -= self.navigationController!.navigationBar.bounds.size.height
            
            var constraintValue                         = size.width - KeypadView.baseSize.width - MinConstraint * 2.0
            self.infoBaseViewWidthConstraint.constant   = constraintValue

            constraintValue                             = (size.height - KeypadView.baseSize.height)/2.0
            if ( constraintValue < MinConstraint ) {
                constraintValue = ( isSmallDevice ? 0.0 : MinConstraint )
            }
            self.keypadBottomConstraint.constant        = constraintValue
            
            constraintValue                             = (size.height - self.infoBaseViewHeightConstraint.constant)/2.0//size.height - self.keypadView.bounds.size.height - self.keypadBottomConstraint.constant
            if ( constraintValue < MinConstraint ) {
                constraintValue = MinConstraint
            }
            self.infoBaseViewTopConstraint.constant     = constraintValue
            
            switch ( currentHandOrientation ) {
            case .right:
                self.keypadViewTrailingConstraint.constant   = self.rightKeypadLandscapeConstraint
                self.infoBaseViewLeadingConstraint.constant  = self.leftInfoViewLandscapeConstraint
                
            case .left:
                self.keypadViewLeadingConstraint.constant    = self.leftKeypadLandscapeConstraint
                self.infoBaseViewTrailingConstraint.constant = self.rightInfoViewLandscapeConstraint
            }
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.infoBaseViewTopConstraint.constant         = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                self.keypadBottomConstraint.constant            = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
            }
            else {
                self.infoBaseViewTopConstraint.constant         = ( isSmallDevice ? MinConstraint * 2.0 : MinConstraint * 4.0 )
                self.keypadBottomConstraint.constant            = ( isSmallDevice ? MinConstraint * 2.0 : MinConstraint * 4.0 )
            }
            
            self.infoBaseViewWidthConstraint.constant       = size.width - 4.0 * MinConstraint
            
            if ( self.infoBaseViewLeadingConstraint.isActive ) {
                self.infoBaseViewLeadingConstraint.constant  = -2.0 * MinConstraint
            }
            else {
                self.infoBaseViewTrailingConstraint.constant = 2.0 * MinConstraint
            }
            
            var constraintValue                             = (size.width - KeypadView.baseSize.width)/2.0
            if ( constraintValue < MinConstraint ) {
                constraintValue = MinConstraint
            }
            if ( self.keypadViewLeadingConstraint.isActive ) {
                self.keypadViewLeadingConstraint.constant   = constraintValue
            }
            else {
                self.keypadViewTrailingConstraint.constant  = constraintValue
            }
            
        }
        
        self.keypadView.padBackgroundColor                    = ( isLandscape && UIDevice.current.isPhone ? UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.05) : UIColor.clear )
        
        let showSwapButton                                    = UIDevice.current.isPhone && isLandscape
        self.keypadView.swapViewButton.isHidden                 = !showSwapButton
        self.keypadView.swapViewButton.isUserInteractionEnabled = showSwapButton
        
        self.keypadView.padView.setNeedsUpdateConstraints()
        self.keypadView.padView.setNeedsLayout()
        self.keypadView.padView.setNeedsDisplay()
        
        self.keypadView.setNeedsUpdateConstraints()
        self.keypadView.setNeedsLayout()
        self.keypadView.setNeedsDisplay()
    }
    
    //--------------------------------------------------------------------------
    func respectCurrentUIHandOrientation()
    {
        if ( !UIDevice.current.isLandscape ) {
            return
        }
        
        let currentHandOrientation = LockerUI.sharedInstance.currentUIHandOrientation
                
        self.lastUIHandOrientation = currentHandOrientation
        
        DispatchQueue.main.async(execute: {
            let animationDuration = SwapViewDuration
            switch ( currentHandOrientation ) {
            case .right:
                UIView.animate(withDuration: animationDuration,
                    animations: {
                        for subView in self.infoBaseView.subviews {
                            self.keypadView.bringSubview(toFront: subView)
                        }
                        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
                        self.keypadViewTrailingConstraint.constant  = self.rightKeypadLandscapeConstraint
                        self.infoBaseViewLeadingConstraint.constant = self.leftInfoViewLandscapeConstraint
                        self.view.layoutIfNeeded()
                })
                
            case .left:
                UIView.animate(withDuration: animationDuration,
                    animations: {
                        for subView in self.infoBaseView.subviews {
                            self.keypadView.bringSubview(toFront: subView)
                        }
                        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
                        self.keypadViewLeadingConstraint.constant    = self.leftKeypadLandscapeConstraint
                        self.infoBaseViewTrailingConstraint.constant = self.rightInfoViewLandscapeConstraint
                        self.view.layoutIfNeeded()
                })
            }
        })
    }

    
    func setDeleteButtonAppearance()
    {
        var isVisible: Bool = false
        var title: String
        var hint:  String
        
        let titleDelete = LockerUI.localized( "btn-pad-delete" )
        let hintDelete  = LockerUI.localized( "btn-pad-delete-hint" )
        let titleBack   = LockerUI.localized( "btn-pad-back" )
        let hintBack    = LockerUI.localized( "btn-pad-back-hint" )
        
        let passwordNotEmpty = !self.key.isEmpty
        
        switch self.dialogType {
        case .inputPasswordOnly, .inputOldPasswordOnly:
            isVisible = passwordNotEmpty
            title     = titleDelete
            hint      = hintDelete
            
        case .inputPasswordAndVerifyThem:
            isVisible = passwordNotEmpty || self.step == 1
            title     = passwordNotEmpty ? titleDelete : titleBack
            hint      = passwordNotEmpty ? hintDelete  : hintBack
        }
        
        self.keypadView.deleteButton.text               = title
        self.keypadView.deleteButton.accessibilityLabel = title
        self.keypadView.deleteButton.accessibilityHint  = hint
        self.keypadView.deleteButton.isHidden             = !isVisible
    }
    
    //MARK: - Key
    //--------------------------------------------------------------------------
    func keyPressed(_ value: Int)
    {
        switch value {
        case 0...9:
            key += "\(value)"
            
        case -2:
            LockerUI.internalSharedInstance.swapCurrentUIHandOrientation()
            self.respectCurrentUIHandOrientation()
            
        default: // delete or back button
            if self.step == 1 && key.isEmpty {
                self.goBack()
            }
            key = String(key.dropLast())
        }
        
        self.selectionView.value = key.count
        
        if key.count >= self.passwordLength! {
            self.didEnterKey(key)
        }
        
        self.setDeleteButtonAppearance()
    }
    
    func didEnterKey(_ key: String)
    {
        self.keyHandler?( key )
    }
    
    func resetKeyInput(_ now: Bool = false)
    {
        if now {
            self.selectionView.value = 0
            self.key = ""
            self.setDeleteButtonAppearance()
        } else {
            DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                self.resetKeyInput(true)
            })
        }
    }
    
    func checkForMinimalLength( _ password: String ) -> Bool
    {
        if password.lengthOfBytes(using: String.Encoding.ascii) < self.passwordLength  {
            self.infoLabel.text    = String( format: LockerUI.localized( "info-pin-trough-format" ), self.passwordLength! )
            return false
        } else {
            return true
        }
    }
    
    func goBack()
    {
        self.step = 0
        self.lastPassword = nil
        self.infoLabel.text = LockerUI.localized( "info-input-new-unlock-pin" )
        self.infoDetailLabel.text = nil
        self.resetKeyInput()
    }
    
    //MARK: -
    override func refreshPasswordDialog()
    {
        super.refreshPasswordDialog()
        
        switch self.dialogType {
        case .inputPasswordOnly, .inputOldPasswordOnly:
            self.setupCompletionForInputPasswordOnly()
        case .inputPasswordAndVerifyThem:
            self.setupCompletionForInputPasswordAndVerifyThem()
        }
        self.resetKeyInput()
    }

    func setupCompletionForInputPasswordOnly()
    {
        if self.dialogType == PasswordDialogType.inputOldPasswordOnly {
            self.infoLabel.text = LockerUI.localized( "info-input-original-unlock-pin" )
        } else {
            self.infoLabel.text = LockerUI.localized( "info-input-unlock-pin" )
        }
        
        if let attemptsLeft = self.remainingAttempts {
            self.infoDetailLabel.text = String( format: LockerUI.localized( "info-input-unlock-pin-format" ), attemptsLeft )
            self.shakeViewForError(self.selectionView)
        } else {
            self.infoDetailLabel.text = nil
        }
        
        self.keyHandler = { key in
            let password: String = key
            if self.checkForMinimalLength(password ) {
                self.lastPassword = key
                self.completion!( LockerUIDialogResult.success(key as AnyObject) )
            }
        }
    }
    
    func setupCompletionForInputPasswordAndVerifyThem()
    {
        self.infoLabel.text = LockerUI.localized( "info-input-new-unlock-pin" )
        self.infoDetailLabel.text = nil
        
        self.keyHandler = { key in
            let password: String = key
            
            if self.checkForMinimalLength( password ) {
                self.step += 1
                if self.step <= 1 {
                    self.infoLabel.text = LockerUI.localized( "info-repeat-pin" )
                    self.infoDetailLabel.text = LockerUI.localized( "info-repeat-pin-detail" )
                    self.lastPassword = key
                    self.resetKeyInput(true)
                } else {
                    if self.lastPassword! == key {
                        self.completion!( LockerUIDialogResult.success(self.lastPassword! as AnyObject) )
                    } else {
                        self.step                 = 0
                        self.lastPassword         = nil
                        self.infoLabel.text       = LockerUI.localized( "info-input-new-unlock-pin" )
                        self.infoDetailLabel.text = LockerUI.localized( "info-second-pin-not-match" )
                        self.resetKeyInput(true)
                        self.shakeViewForError(self.selectionView)
                        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 2.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                            self.infoLabel.text       = LockerUI.localized( "info-input-new-unlock-pin" )
                            self.infoDetailLabel.text = nil
                        })
                    }
                }
                
                if UIAccessibilityIsVoiceOverRunning() {
                    DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.infoLabel)
                    })
                }
            }
        }
    }
    
    
}
