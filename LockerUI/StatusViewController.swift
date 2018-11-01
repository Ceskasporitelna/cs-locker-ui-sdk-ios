//
//  StatusViewController.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 26.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
class StatusViewController: LockerViewController
{
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var statusIcon: LockerImageView!
    @IBOutlet weak var statusMainLabel: UILabel!
    @IBOutlet weak var statusDescriptionLabel: UILabel!
    @IBOutlet weak var actionButton: ShadowButton!
    @IBOutlet weak var iconViewHeight: NSLayoutConstraint!
    @IBOutlet weak var statusDetailVerticalSpaceConstraint: NSLayoutConstraint!
    
    
    var options: StatusScreenOptions?
    var originalIconHeight: CGFloat!
    
    //--------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.originalIconHeight       = iconViewHeight.constant
        
        self.adjustUISettingsForWhiteButton( self.actionButton )
        self.respectStatusOptions()
        
        if let tint = self.backgroundTint {
            self.statusIcon.tint = tint
        }
        
        self.defaultAccessibilityView = self.statusMainLabel
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
            }, completion:nil )
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    //--------------------------------------------------------------------------
    func updateConstraintsWithScreenSize()
    {
        var size          = UIScreen.main.bounds.size
        let isLandscape   = UIDevice.current.isLandscape
        let isSmallDevice = UIDevice.current.isSmallDevice
        
        if ( isLandscape && UIDevice.current.isPhone ) {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            size.height                                      -= self.navigationController!.navigationBar.bounds.size.height
            self.statusDetailVerticalSpaceConstraint.constant = (isSmallDevice ? 2.0 * MinConstraint : 4.0 * MinConstraint )
            self.statusIcon.isHidden                            = true
            self.iconViewHeight.constant                      = 0.0
        }
        else {
            if ( self.shouldShowTitleLogo ) {
                self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
            }
            
            if ( UIDevice.current.isPad ) {
                self.statusDetailVerticalSpaceConstraint.constant = (isLandscape ? 8.0 * MinConstraint : 16.0 * MinConstraint )
            }
            else {
                self.statusDetailVerticalSpaceConstraint.constant = (isSmallDevice ? 2.0 * MinConstraint : 6.0 * MinConstraint )
            }
            
            if ( UIDevice.current.isIphone4 ) {
                self.statusIcon.isHidden                            = true
                self.iconViewHeight.constant                      = 0.0
            }
            else {
                self.statusIcon.isHidden                            = false
                self.iconViewHeight.constant                      = self.originalIconHeight
            }
        }
    }

    
    @IBAction func actionAction(_ sender: UIButton)
    {
        self.completion?( lockerUIDialogResultOk() )
    }
    
    override func viewWillLayoutSubviews()
    {
        self.actionButton.layer.layoutSublayers()
    }
    
    //--------------------------------------------------------------------------
    func respectStatusOptions()
    {
        if let options = self.options { 
            self.appNameLabel.text = options.appName
            self.statusMainLabel.text = options.statusMainText
            self.statusDescriptionLabel.text = options.statusDescriptionText
            self.actionButton.setTitle( options.actionCaption, for: UIControl.State() )
            
            self.statusIcon.image        = self.imageNamed(options.statusIconName)
            if let tint                  = self.backgroundTint {
                self.statusIcon.tint     = tint
            }
        }
    }
}
