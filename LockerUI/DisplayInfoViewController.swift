//
//  DisplayInfoViewController.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 27.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit
import CSCoreSDK

//==============================================================================
class DisplayInfoViewController: LockerViewController
{
    @IBOutlet weak var statusIcon: LockerImageView!
    @IBOutlet weak var firstActionButton: ShadowButton!
    @IBOutlet weak var secondActionButton: ShadowButton!
    @IBOutlet weak var infoMainLabel: UILabel!
    @IBOutlet weak var infoDescriptionLabel: UILabel!
    
    // Info Base View ...
    @IBOutlet weak var infoBaseViewTopConstraint: NSLayoutConstraint!
    
    // First Button ...
    @IBOutlet weak var firstButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstButtonTrailingConstraint: NSLayoutConstraint!
    
    // Second Button ...
    
    @IBOutlet weak var secondButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondButtonLeadingConstraint: NSLayoutConstraint!
    
    var lockType = LockType.noLock
    
    var secondCompletion: ((_ result: LockerUIDialogResult<AnyObject>) -> Void)?
    var options: DisplayInfoOptions?
    
    //--------------------------------------------------------------------------
    override func viewDidLoad()
    {
        self.lockerViewOptions = LockerViewOptions.showCancelButton.rawValue
        super.viewDidLoad()
        
        self.infoMainLabel.text = LockerUI.localized( "info-settings" )
        self.infoDescriptionLabel.text = String( format: LockerUI.localized( "info-settings-description-format" ), lockType.toString() )
        
        self.firstActionButton.setTitle( LockerUI.localized("btn-change-security"), for: UIControl.State() )
        self.secondActionButton.setTitle( LockerUI.localized("btn-unregister"), for: UIControl.State() )
        
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
        var size        = UIScreen.main.bounds.size
        let isLandscape = UIDevice.current.isLandscape
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            
            size.height -= self.navigationController!.navigationBar.bounds.size.height
            
            self.infoBaseViewTopConstraint.constant      = ( UIDevice.current.isSmallDevice ? 0.0 : MinConstraint * 2.0)
            
            self.firstButtonTrailingConstraint.constant   = MinConstraint
            self.secondButtonLeadingConstraint.constant   = MinConstraint
            
            let buttonWidth                              = (size.width - self.firstButtonTrailingConstraint.constant - MinConstraint - self.secondButtonLeadingConstraint.constant)/2.0
            
            self.firstButtonWidthConstraint.constant     = buttonWidth
            self.secondButtonWidthConstraint.constant    = buttonWidth
            
            if ( UIDevice.current.isSmallDevice ) {
                self.secondButtonBottomConstraint.constant   = MinConstraint
            }
            else {
                self.secondButtonBottomConstraint.constant   = 2.0 * MinConstraint
            }
            self.firstButtonBottomConstraint.constant    = self.secondButtonBottomConstraint.constant
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.infoBaseViewTopConstraint.constant      = ( isLandscape ? MinConstraint * 8.0 : MinConstraint * 16.0 )
                let buttonWidth                              = size.width / 2.0
                self.firstButtonWidthConstraint.constant     = buttonWidth
                self.secondButtonWidthConstraint.constant    = buttonWidth
                self.secondButtonBottomConstraint.constant   = 8.0 * MinConstraint
                self.firstButtonBottomConstraint.constant    = self.secondButtonBottomConstraint.constant + self.secondButtonHeightConstraint.constant + MinConstraint
                self.firstButtonTrailingConstraint.constant  = (size.width - buttonWidth)/2.0
                self.secondButtonLeadingConstraint.constant  = (size.width - buttonWidth)/2.0
            }
            else {
                self.infoBaseViewTopConstraint.constant      = 4.0 * MinConstraint
                let buttonWidth                              = size.width - 2.0 * MinConstraint
                self.firstButtonWidthConstraint.constant     = buttonWidth
                self.secondButtonWidthConstraint.constant    = buttonWidth
                self.secondButtonBottomConstraint.constant   = 2.0 * MinConstraint
                self.firstButtonBottomConstraint.constant    = self.secondButtonBottomConstraint.constant + self.secondButtonHeightConstraint.constant + MinConstraint
                self.firstButtonTrailingConstraint.constant  = MinConstraint
                self.secondButtonLeadingConstraint.constant  = MinConstraint
            }
        }
    }
    
    
    //MARK: -
    @IBAction func firstButtonAction(_ sender: UIButton)
    {
        self.completion?( lockerUIDialogResultOk() )
    }
    
    @IBAction func secondButtonAction(_ sender: UIButton)
    {
        let alert = UIAlertController(title: LockerUI.localized( "title-unregister" ), message: options?.unregisterPromptText, preferredStyle: UIAlertController.Style.alert )
        alert.addAction( UIAlertAction(title: LockerUI.localized( "btn-cancel" ), style: UIAlertAction.Style.default, handler: nil ))
        alert.addAction( UIAlertAction(title: LockerUI.localized( "btn-ok" ), style: UIAlertAction.Style.destructive, handler: { action in
            self.secondCompletion?( lockerUIDialogResultOk() )
        }))
        self.present(alert, animated: false, completion: nil )
    }
    
}
