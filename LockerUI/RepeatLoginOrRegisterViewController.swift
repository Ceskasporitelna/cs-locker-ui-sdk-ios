//
//  RepeatLoginOrRegisterViewController.swift
//  CSLockerUI
//
//  Created by Vladimír Nevyhoštěný on 11/03/16.
//  Copyright © 2016 Applifting. All rights reserved.
//

import UIKit
import CSCoreSDK

//==============================================================================
class RepeatLoginOrRegisterViewController: LockerViewController
{
    @IBOutlet weak var statusIcon: LockerImageView!
    @IBOutlet weak var firstActionButton: ShadowButton!
    @IBOutlet weak var secondActionButton: ShadowButton!
    @IBOutlet weak var infoMainLabel: UILabel!
    @IBOutlet weak var infoDescriptionLabel: UILabel!
    
    // Info Base View ...
    @IBOutlet weak var infoBaseViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoBaseViewHeihgtConstraint: NSLayoutConstraint!
    
    // Try Again Button ...
    
    @IBOutlet weak var tryAgainButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tryAgainButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tryAgainButtonLeadingConstraint: NSLayoutConstraint!
    
    // New Registration Button ...
    
    @IBOutlet weak var newRegistrationButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var newRegistrationButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var newRegistrationButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var newRegistrationButtonTrailingConstraint: NSLayoutConstraint!
    
    var lockType = LockType.noLock
    let biometricsTypeManager = BiometricsTypeManager.shared
    
    var secondCompletion: ((_ result: LockerUIDialogResult<AnyObject>) -> Void)?
    var options: DisplayInfoOptions?
    
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let type = biometricsTypeManager.deviceUsedBiometricType()
        switch type {
        case .touchID:
            self.infoDescriptionLabel.text = LockerUI.localized("info-fingerprint-auth-failed")
            statusIcon.image = imageNamed("icons-finger-broken")
        case .faceID:
            self.infoDescriptionLabel.text = LockerUI.localized("info-face-auth-failed")
            statusIcon.image = imageNamed("icons-face-broken")
        }
        self.infoMainLabel.text        = LockerUI.localized("info-user-login-failed")
        
        self.firstActionButton.setTitle( LockerUI.localized("btn-repeat"), for: UIControl.State() )
        self.secondActionButton.setTitle( LockerUI.localized("btn-new-registration"), for: UIControl.State() )
        
        self.adjustUISettingsForWhiteButton( self.firstActionButton )
        self.adjustUISettingsForRedButton( self.secondActionButton )
        
        if let tint = self.backgroundTint {
            self.statusIcon.tint = tint
        }
        
        self.defaultAccessibilityView = self.infoMainLabel
    }
    
    //--------------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
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
    func updateConstraintsWithScreenSize()
    {
        var size                                    = UIScreen.main.bounds.size
        let isLandscape                             = UIDevice.current.isLandscape
        let isSmallDevice                           = UIDevice.current.isSmallDevice
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            size.height                                          -= self.navigationController!.navigationBar.bounds.size.height
            
            self.infoBaseViewTopConstraint.constant               = ( isSmallDevice ? 0.0 : MinConstraint * 2.0)
            
            self.tryAgainButtonLeadingConstraint.constant         = MinConstraint
            self.newRegistrationButtonTrailingConstraint.constant = MinConstraint
            
            let buttonWidth                                       = (size.width - self.tryAgainButtonLeadingConstraint.constant - MinConstraint - self.newRegistrationButtonTrailingConstraint.constant)/2.0
            
            self.tryAgainButtonWidthConstraint.constant           = buttonWidth
            self.newRegistrationButtonWidthConstraint.constant    = buttonWidth
            self.newRegistrationButtonBottomConstraint.constant   = ( isSmallDevice ? MinConstraint : MinConstraint * 2.0)
            self.tryAgainButtonBottomConstraint.constant          = self.newRegistrationButtonBottomConstraint.constant
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.infoBaseViewTopConstraint.constant               = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                let buttonWidth                                       = size.width / 2.0
                self.tryAgainButtonWidthConstraint.constant           = buttonWidth
                self.newRegistrationButtonWidthConstraint.constant    = buttonWidth
                self.newRegistrationButtonBottomConstraint.constant   = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                self.tryAgainButtonBottomConstraint.constant          = self.newRegistrationButtonBottomConstraint.constant + self.newRegistrationButtonHeightConstraint.constant + MinConstraint
                self.tryAgainButtonLeadingConstraint.constant         = (size.width - buttonWidth)/2.0
                self.newRegistrationButtonTrailingConstraint.constant = (size.width - buttonWidth)/2.0
            }
            else {
                //self.infoBaseViewTopConstraint.constant               = ( isSmallDevice ? MinConstraint : 3.0 * MinConstraint )
                self.infoBaseViewTopConstraint.constant               = 4.0 * MinConstraint
                let buttonWidth                                       = size.width - 2.0 * MinConstraint
                self.tryAgainButtonWidthConstraint.constant           = buttonWidth
                self.newRegistrationButtonWidthConstraint.constant    = buttonWidth
                self.newRegistrationButtonBottomConstraint.constant   = 2.0 * MinConstraint
                self.tryAgainButtonBottomConstraint.constant          = self.newRegistrationButtonBottomConstraint.constant + self.newRegistrationButtonHeightConstraint.constant + MinConstraint
                self.tryAgainButtonLeadingConstraint.constant         = MinConstraint
                self.newRegistrationButtonTrailingConstraint.constant = MinConstraint
            }
        }
    }
    
    //MARK: - Actions
    //--------------------------------------------------------------------------
    @IBAction func firstButtonAction(_ sender: UIButton)
    {
        self.completion?( lockerUIDialogResultOk() )
    }
    
    //--------------------------------------------------------------------------
    @IBAction func secondButtonAction(_ sender: UIButton)
    {
        let locker = CoreSDK.sharedInstance.locker
        if locker.lockStatus != .unregistered {
            locker.unregisterUserWithCompletion() { result in
                self.completion?( LockerUIDialogResult.cancel )
            }
        }
        else {
            self.completion?( LockerUIDialogResult.cancel )
        }
    }
    
}
