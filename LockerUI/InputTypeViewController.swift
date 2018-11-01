//
//  InputTypeViewController.swift
//  CoreSDKTestApp
//
//  Created by František Kratochvíl on 01.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
class InputTypeViewController: LockerViewController
{
    @IBOutlet weak var statusMainLabel: UILabel!
    @IBOutlet weak var statusDescriptionLabel: UILabel!
    @IBOutlet weak var fingerprintButton: UIButton!
    @IBOutlet weak var pinButton: UIButton!
    @IBOutlet weak var gestureButton: UIButton!
    @IBOutlet weak var noAuthButton: UIButton!
    
    @IBOutlet var buttons: [UIButton]!
    
    @IBOutlet var buttonHeightConstraints: [NSLayoutConstraint]!
    @IBOutlet var buttonGapHeightConstraints: [NSLayoutConstraint]!
    
    // Info View ...
    @IBOutlet weak var infoViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var infoViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoViewHeightConstraint: NSLayoutConstraint!
    
    // Button View ...
    
    @IBOutlet weak var buttonViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonViewBottomConstraint: NSLayoutConstraint!
    
    // Status Icon ...
    @IBOutlet weak var statusIcon: LockerImageView!
    @IBOutlet weak var statusIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusIconHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusIconTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var infoBaseView: UIView!    
    @IBOutlet weak var buttonBaseView: UIView!
    
    var lockerUIOptions: LockerUIOptions = LockerUIOptions()
    let biometricsTypeManager = BiometricsTypeManager.shared
    
    var buttonHeight: CGFloat = 42.0
    var buttonGap: CGFloat    = 15.0
    
    //--------------------------------------------------------------------------
    var buttonsCommonHeight: CGFloat {
        var height: CGFloat = 0.0
        for button in [pinButton, fingerprintButton, gestureButton, noAuthButton] where !(button?.isHidden)! {
            height += ( self.buttonHeight + self.buttonGap )
        }
        return height - self.buttonGap
    }
    
    //--------------------------------------------------------------------------
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.statusMainLabel.text = LockerUI.localized( "info-security" )
        self.statusDescriptionLabel.text = LockerUI.localized( "info-security-description" )
        self.pinButton.setTitle(LockerUI.localized( "btn-use-pin"), for: UIControl.State())
        self.gestureButton.setTitle( LockerUI.localized( "btn-use-gesture"), for: UIControl.State())
        self.noAuthButton.setTitle(LockerUI.localized( "btn-without-security"), for: UIControl.State())
        self.statusIcon.image = self.imageNamed("lock-ok")
        
        let type = biometricsTypeManager.deviceUsedBiometricType()
        switch type {
        case .touchID:
            self.fingerprintButton.setImage(imageNamed("button-fingerprint"), for: UIControl.State())
            self.fingerprintButton.setTitle(LockerUI.localized( "btn-use-fingerprint"), for: UIControl.State())
            
        case .faceID:
            self.fingerprintButton.setImage(imageNamed("button-face"), for: UIControl.State())
            self.fingerprintButton.setTitle(LockerUI.localized( "btn-use-faceID"), for: UIControl.State())
        }
        
        var offset: CGFloat = 0.0
        
        for button in self.buttons {
            self.adjustUISettingsForDarkButton( button )
            self.setupButton( button, visible: false, offset: &offset )
        }
        
        if let tint = self.backgroundTint {
            self.statusIcon.tint = tint
        }
        
        for lockInfo in self.lockerUIOptions.allowedLockTypes {
            switch lockInfo.lockType {
            case .pinLock:
                self.pinButton.setImage(self.imageNamed("button-dots"), for: UIControl.State())
                self.setupButton( self.pinButton, visible: true, offset: &offset )
                
            case .biometricLock:
                self.setupButton( self.fingerprintButton, visible: true, offset: &offset )
                
            case .gestureLock:
                if ( !UIAccessibility.isVoiceOverRunning ) {
                    self.gestureButton.setImage(self.imageNamed("button-gesture"), for: UIControl.State())
                    self.setupButton( self.gestureButton, visible: true, offset: &offset )
                }
                
            case .noLock:
                self.noAuthButton.setImage(self.imageNamed("button-no-safety"), for: UIControl.State())
                self.setupButton( self.noAuthButton, visible: true, offset: &offset )
            }
        }
        self.fixButtonGaps()
        self.buttonViewHeightConstraint.constant = self.buttonsCommonHeight
        self.defaultAccessibilityView = self.statusMainLabel
        
        if ( UIDevice.current.isSmallDevice ) {
            self.statusDescriptionLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)!
            
            let smallDeviceRatio: CGFloat                  = 0.7
            self.statusIconWidthConstraint.constant       *= smallDeviceRatio
            self.statusIconHeightConstraint.constant      *= smallDeviceRatio
        }
        
        // For UI tweaks ...
        
//        self.infoBaseView.layer.borderColor = UIColor.whiteColor().CGColor
//        self.infoBaseView.layer.borderWidth = 1.0
    }
    
    //--------------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        for button in self.buttons{
            button.isEnabled = true
        }
        
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
        var size           = UIScreen.main.bounds.size
        let isLandscape    = UIDevice.current.isLandscape
        let isSmallDevice  = UIDevice.current.isSmallDevice
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            
            size.height -= self.navigationController!.navigationBar.bounds.size.height
            
            self.infoViewLeadingConstraint.constant    = MinConstraint
            self.buttonViewTrailingConstraint.constant = MinConstraint
            
            let constraintValue = size.width - self.buttonViewWidthConstraint.constant - MinConstraint - self.infoViewLeadingConstraint.constant
            if ( self.infoViewWidthConstraint.constant > constraintValue ) {
                self.infoViewWidthConstraint.constant = constraintValue
            }
            
            self.buttonViewBottomConstraint.constant   = max((size.height - self.buttonViewHeightConstraint.constant)/2.0, MinConstraint)
            self.infoViewTopConstraint.constant        = max((size.height - self.infoViewHeightConstraint.constant)/2.0, MinConstraint)
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.infoViewTopConstraint.constant        = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                self.infoViewWidthConstraint.constant      = size.width - MinConstraint * 2.0
                self.infoViewLeadingConstraint.constant    = (size.width - self.infoViewWidthConstraint.constant)/2.0
                self.buttonViewTrailingConstraint.constant = (size.width - self.buttonViewWidthConstraint.constant)/2.0
                self.buttonViewBottomConstraint.constant   = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
            }
            else {
                self.infoViewTopConstraint.constant        = ( isSmallDevice ? MinConstraint * 5.0 : MinConstraint * 10.0 )
                self.infoViewWidthConstraint.constant      = size.width - MinConstraint * 2.0
                self.infoViewLeadingConstraint.constant    = (size.width - self.infoViewWidthConstraint.constant)/2.0
                self.buttonViewTrailingConstraint.constant = (size.width - self.buttonViewWidthConstraint.constant)/2.0
                self.buttonViewBottomConstraint.constant   = ( isSmallDevice ? MinConstraint * 2.0 : MinConstraint * 6.0 )//MinConstraint
            }
        }
    }
    
    
    //MARK: -
    func setupButton( _ button: UIButton, visible: Bool, offset: inout CGFloat )
    {
        button.isHidden  = !visible
        
        for constraint in self.buttonHeightConstraints {
            if ( constraint.firstItem as! UIButton == button ) {
                buttonHeight = constraint.constant > 0 ? constraint.constant : buttonHeight
                constraint.constant = visible ? buttonHeight : 0
                break
            }
        }
    }
    
    func fixButtonGaps()
    {
        for button in [pinButton, fingerprintButton, gestureButton, noAuthButton] where (button?.isHidden)! {
            for constraint in self.buttonGapHeightConstraints where constraint.constant > 0 {
                if ( (constraint.firstItem as! UIButton) == button || (constraint.secondItem as! UIButton) == button ) {
                    constraint.constant = 0
                    break
                }
            }
        }
    }
    
    //MARK: Navigation
    @IBAction func goBackToMenu(_ segue:UIStoryboardSegue){}
    
    @IBAction func buttonTouchAction( _ sender: UIButton )
    {
        sender.isEnabled = false
        self.completion?( LockerUIDialogResult.success( sender.tag as AnyObject ) )
    }
    
    
}
