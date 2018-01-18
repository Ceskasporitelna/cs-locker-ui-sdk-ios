//
//  GestureViewController.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 06.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit
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
class GestureViewController: LockerPasswordViewController
{
    @IBOutlet weak var gestureLockView: GestureLockView!
    @IBOutlet weak var gestureIcon: LockerImageView!
    
    // Gesture Icon ...
    
    @IBOutlet weak var gestureIconTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var gestureIconHeightConstraint: NSLayoutConstraint!
    
    // Info Base View ...
    
    @IBOutlet weak var infoBaseTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var infoBaseViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var infoBaseViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseView: UIView!
    
    // Gesture View ...
    
    @IBOutlet var gestureViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var gestureViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var gestureViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var gestureViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var gestureViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var swapViewsButton: PadButton!
    
    fileprivate var lastUIHandOrientation: UIHandOrientation?
    
    var leftInfoViewLandscapeConstraint: CGFloat {
        return MinConstraint
    }
    
    var rightInfoViewLandscapeConstraint: CGFloat {
        return MinConstraint
    }
    
    var leftGestureViewLandscapeConstraint: CGFloat {
        return MinConstraint
    }
    
    var rightGestureViewLandscapeConstraint: CGFloat {
        return MinConstraint
    }
    
    //--------------------------------------------------------------------------
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder )
    }
    
    //--------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.lastPassword           = nil
        self.newPassword            = nil
        
        self.refreshPasswordDialog()
        
        self.gestureIcon.image = self.imageNamed("icon-gesture")
        
        if let tint = self.backgroundTint {
            self.gestureIcon.tint = tint
        }
        
        if (UIDevice.current.isSmallDevice) {
            self.gestureIconTopConstraint.constant    = 0
            self.gestureIconHeightConstraint.constant = 0
            self.gestureIcon.isHidden                   = true
        }
        
        // For UI tweaks ...
        
//        self.infoBaseView.layer.borderColor      = UIColor.white.cgColor
//        self.infoBaseView.layer.borderWidth      = 1.5
//        self.gestureLockView.layer.borderColor   = UIColor.white.cgColor
//        self.gestureLockView.layer.borderWidth   = 1.5
    }
    
    //--------------------------------------------------------------------------
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    //--------------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
        self.view.setNeedsLayout()
        self.updateConstraintsWithScreenSize()
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
    func activateConstraintsWithRespectToCurrentUIHandOrientation()
    {
        self.lastUIHandOrientation = LockerUI.sharedInstance.currentUIHandOrientation
        
        switch ( self.lastUIHandOrientation! ) {
        case .right:
            self.infoBaseViewTrailingConstraint.isActive = false
            self.infoBaseViewLeadingConstraint.isActive  = true
            self.gestureViewLeadingConstraint.isActive   = false
            self.gestureViewTrailingConstraint.isActive  = true
            
        case .left:
            self.infoBaseViewTrailingConstraint.isActive = true
            self.infoBaseViewLeadingConstraint.isActive  = false
            self.gestureViewLeadingConstraint.isActive   = true
            self.gestureViewTrailingConstraint.isActive  = false
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
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            
            size.height -= self.navigationController!.navigationBar.bounds.size.height
            
            var constraintValue                         = size.width - self.gestureViewWidthConstraint.constant - MinConstraint - self.infoBaseViewLeadingConstraint.constant
            self.infoBaseViewWidthConstraint.constant   = constraintValue
            
            constraintValue                             = (size.height - self.gestureViewHeightConstraint.constant)/2.0
            self.gestureViewBottomConstraint.constant   = constraintValue
            
            if ( isSmallDevice ) {
                self.infoBaseTopConstraint.constant         = constraintValue
                self.infoBaseViewHeightConstraint.constant  = self.gestureViewHeightConstraint.constant
            }
            else {
                self.infoBaseViewHeightConstraint.constant  = self.gestureViewHeightConstraint.constant + 2.0 * MinConstraint
                self.infoBaseTopConstraint.constant         = (size.height - self.infoBaseViewHeightConstraint.constant)/2.0
                
            }
            
            switch ( currentHandOrientation ) {
            case .right:
                self.gestureViewTrailingConstraint.constant  = self.rightGestureViewLandscapeConstraint
                self.infoBaseViewTrailingConstraint.constant = self.leftInfoViewLandscapeConstraint
                
            case .left:
                self.gestureViewLeadingConstraint.constant   = self.leftGestureViewLandscapeConstraint
                self.infoBaseViewTrailingConstraint.constant = self.rightInfoViewLandscapeConstraint
            }
            
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.infoBaseTopConstraint.constant         = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                self.gestureViewBottomConstraint.constant   = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
            }
            else {
                self.infoBaseTopConstraint.constant         = ( isSmallDevice ? 0.0 : MinConstraint * 4.0 )
                self.gestureViewBottomConstraint.constant   = ( isSmallDevice ? 0.0 : MinConstraint * 4.0 )
            }
            
            self.infoBaseViewWidthConstraint.constant   = size.width - 2.0 * MinConstraint
            if ( self.infoBaseViewLeadingConstraint.isActive ) {
                self.infoBaseViewLeadingConstraint.constant  = self.leftInfoViewLandscapeConstraint
            }
            else {
                self.infoBaseViewTrailingConstraint.constant = self.rightInfoViewLandscapeConstraint
            }
            
            self.infoBaseViewHeightConstraint.constant  = size.height - self.gestureViewHeightConstraint.constant - self.gestureViewBottomConstraint.constant - MinConstraint
            var constraintValue                         = (size.width - self.gestureViewWidthConstraint.constant)/2.0
            if ( constraintValue < MinConstraint ) {
                constraintValue = MinConstraint
            }
            if ( self.gestureViewLeadingConstraint.isActive ) {
                self.gestureViewLeadingConstraint.constant   = constraintValue
            }
            else {
                self.gestureViewTrailingConstraint.constant  = constraintValue
            }
        }
        
        let showSwapButton                          = UIDevice.current.isPhone && isLandscape
        self.swapViewsButton.isHidden                 = !showSwapButton
        self.swapViewsButton.isUserInteractionEnabled = showSwapButton
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
                            self.gestureLockView.bringSubview(toFront: subView)
                        }
                        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
                        self.gestureViewTrailingConstraint.constant = self.rightGestureViewLandscapeConstraint
                        self.infoBaseViewLeadingConstraint.constant = self.leftInfoViewLandscapeConstraint
                        self.view.layoutIfNeeded()
                })
                
            case .left:
                UIView.animate(withDuration: animationDuration,
                    animations: {
                        for subView in self.infoBaseView.subviews {
                            self.gestureLockView.bringSubview(toFront: subView)
                        }
                        self.activateConstraintsWithRespectToCurrentUIHandOrientation()
                        self.gestureViewLeadingConstraint.constant   = self.leftGestureViewLandscapeConstraint
                        self.infoBaseViewTrailingConstraint.constant = self.rightInfoViewLandscapeConstraint
                        self.view.layoutIfNeeded()
                })
            }
        })
    }
    
    
    
    //--------------------------------------------------------------------------
    func checkForMinimalLength( _ password: String ) -> Bool
    {
        if ( password.lengthOfBytes(using: String.Encoding.ascii) / 2 < self.passwordLength ) {
            return false
        }
        else {
            return true
        }
    }
    
    func setupCompletionForInputPasswordOnly()
    {
        if ( self.dialogType == PasswordDialogType.inputOldPasswordOnly ) {
            self.infoLabel.text = LockerUI.localized( "info-input-original-unlock-gesture" )
        } else {
            self.infoLabel.text = LockerUI.localized( "info-input-unlock-gesture" )
        }
        
        if let attemptsLeft = self.remainingAttempts {
            self.infoDetailLabel.text = String( format: LockerUI.localized( "info-gesture-bad-format" ), attemptsLeft )
            self.shakeViewForError(self.gestureLockView)
        } else {
            // the user should know the length of his password
            self.infoDetailLabel.text = String( format: LockerUI.localized( "info-gesture-trough-format" ), self.passwordLength! )
            //self.infoDetailLabel.text = nil
        }
        
        self.gestureLockView.callback = { key in
            // the user should know the length of his password
            //let password: String = key
            if self.checkForMinimalLength( key ) {
                self.lastPassword = key
                self.completion!( LockerUIDialogResult.success(key as AnyObject) )
            } else {
                DispatchQueue.main.async(execute: {
                    self.infoDetailLabel.text = String( format: LockerUI.localized( "info-gesture-trough-format" ), self.passwordLength! )
                })
                self.shakeViewForError(self.gestureLockView)
            }
        }
    }
    
    func setupCompletionForInputPasswordAndVerifyThem()
    {
        self.infoLabel.text       = LockerUI.localized( "info-input-unlock-gesture" )
        self.infoDetailLabel.text = String( format: LockerUI.localized( "info-gesture-trough-format" ), self.passwordLength! )
        
        self.gestureLockView.callback = { key in
            
            let password: String = key
            if self.checkForMinimalLength( password ) {
                self.step += 1
                if ( self.step <= 1 ) {
                    self.infoLabel.text       = LockerUI.localized( "info-repeat-gesture" )
                    self.infoDetailLabel.text = LockerUI.localized( "info-repeat-gesture-detail" )
                    self.lastPassword         = key
                } else {
                    if ( self.lastPassword! == key ) {
                        self.completion!( LockerUIDialogResult.success(self.lastPassword! as AnyObject) )
                    } else {
                        self.step                 = 0
                        self.lastPassword         = nil
                        self.infoLabel.text       = LockerUI.localized( "info-input-unlock-gesture" )
                        self.infoDetailLabel.text = LockerUI.localized( "info-second-gesture-not-match" )
                        self.shakeViewForError(self.gestureLockView)
                        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 2.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                            self.infoDetailLabel.text = String( format: LockerUI.localized( "info-gesture-trough-format" ), self.passwordLength! )
                        })
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------
    override func refreshPasswordDialog()
    {
        super.refreshPasswordDialog()
        
        switch ( self.dialogType ) {
        case .inputPasswordOnly, .inputOldPasswordOnly:
            self.setupCompletionForInputPasswordOnly()
            
        case .inputPasswordAndVerifyThem:
            self.setupCompletionForInputPasswordAndVerifyThem()
        }
    }
    
    
    //--------------------------------------------------------------------------
    @IBAction func swapViewsAction(_ sender: PadButton)
    {
        LockerUI.internalSharedInstance.swapCurrentUIHandOrientation()
        self.respectCurrentUIHandOrientation()
    }
    
}
