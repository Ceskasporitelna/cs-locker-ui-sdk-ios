//
//  LockerViewController.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 09.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
enum LockerViewOptions: UInt
{
    case showNoButton        = 0
    case showBackButton      = 1
    case showCancelButton    = 2
}

let MinConstraint: CGFloat   = 8.0
let SwapViewDuration         = 0.3

//==============================================================================
class LockerViewController: UIViewController
{
    @IBOutlet weak var backgroundBaseView: LockerBackgroundView!
    
    @IBOutlet weak var backgroundTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundTrailingConstraint: NSLayoutConstraint!
    
    var backButton: UIButton! = UIButton()
    var cancelButton: UIButton! = UIButton()
    var defaultAccessibilityView: UIView?
    
    var completion: ((_ result: LockerUIDialogResult<AnyObject>) -> Void)?
    
    var backgroundTint: UIColor?
    var lockerViewOptions: UInt = LockerViewOptions.showNoButton.rawValue {
        
        didSet{
            if (lockerViewOptions & LockerViewOptions.showBackButton.rawValue) == LockerViewOptions.showBackButton.rawValue {
                self.backButton?.isHidden = false
                self.backButton?.isEnabled = true
            }else{
                self.backButton?.isHidden = true
                self.backButton?.isEnabled = false
            }
            
            if (lockerViewOptions & LockerViewOptions.showCancelButton.rawValue) == LockerViewOptions.showCancelButton.rawValue {
                self.cancelButton?.isHidden = false
                self.cancelButton?.isEnabled = true
            }else{
                self.cancelButton?.isHidden = true
                self.cancelButton?.isEnabled = false
            }
        }
    }
    
    var shouldShowTitleLogo: Bool {
        switch (LockerUI.internalSharedInstance.lockerUIOptions.showLogo) {
        case .always, .exceptRegistration:
            return true
        case .never:
            return false
        }
    }
    
    //MARK: -
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    //--------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.backgroundTint = LockerUI.internalSharedInstance.mainColor
        
        if let tint = self.backgroundTint {
            self.backgroundBaseView.tint = tint
        }
        
        self.colorNavButtons()
        self.navigationController?.isNavigationBarHidden = false
        
        self.navigationItem.leftBarButtonItems  = [self.createBarButtonSpace(CGFloat(-15)),
            self.createBarButtonItemWithImage( "button-back", button:self.backButton, action: #selector(LockerViewController.backButtonAction(_:)))]
        self.navigationItem.rightBarButtonItems = [self.createBarButtonSpace(CGFloat(-15)),
            self.createBarButtonItemWithImage( "button-dismiss", button:self.cancelButton, action: #selector(LockerViewController.cancelButtonAction(_:)))]
        
        if ( self.shouldShowTitleLogo ) {
            self.navigationItem.titleView = UIImageView(image: self.imageNamed("logo-csas") )
        }
        
        self.backButton.isAccessibilityElement     = true
        self.backButton.accessibilityLabel         = LockerUI.localized( "btn-back" )
        self.backButton.accessibilityHint          = LockerUI.localized( "btn-back-hint" )
        
        self.cancelButton.isAccessibilityElement   = true
        self.cancelButton.accessibilityLabel       = LockerUI.localized( "btn-cancel" )
        self.cancelButton.accessibilityHint        = LockerUI.localized( "btn-cancel-hint" )
        
        let size                                   = self.view.bounds.size
        let maxDim                                 = max(size.width, size.height)
        let hypotenuse                             = sqrt(maxDim * maxDim + maxDim * maxDim)
        let delta                                  = round((hypotenuse - maxDim)/(-1.0))
        
        self.backgroundTopConstraint.constant      = delta
        self.backgroundLeadingConstraint.constant  = delta
        self.backgroundTrailingConstraint.constant = delta
        self.backgroundBottomConstraint.constant   = delta
    }
    
    
    //--------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if let voiceOverView = self.defaultAccessibilityView {
            if UIAccessibilityIsVoiceOverRunning() {
                DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, voiceOverView)
                })
            }
        }
    }

    
    //MARK: -
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all
    }
    
    //MARK: -
    func createBarButtonSpace(_ size: CGFloat) -> UIBarButtonItem
    {
        let item = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        item.width = size
        return item
    }
    
    func imageNamed(_ imageName : String) -> UIImage?
    {
        return UIImage(named: imageName, in: Bundle(for: LockerViewController.self), compatibleWith: nil )
    }
    
    func createBarButtonItemWithImage(_ imageName: String, button:UIButton, action: Selector) -> UIBarButtonItem
    {
        if let image = self.imageNamed(imageName) {
            
            let color = LockerUI.internalSharedInstance.lockerUIOptions.navBarTintColor.color
            let newImage = image.imageWithColor(color)
            button.frame = CGRect( x: 0, y: 0, width: newImage.size.width, height: newImage.size.height )
            
            button.setImage(newImage, for: UIControlState() )
            button.addTarget(self, action: action, for: UIControlEvents.touchUpInside )
            
            return UIBarButtonItem(customView: button )
        } else {
            assert( false, "Button image \(imageName) not found!" )
            return UIBarButtonItem()
        }
    }
    
    func colorNavButtons()
    {
        for button in [self.backButton, self.cancelButton] where button != nil {
            let oldImage = button?.image(for: UIControlState())
            let color = LockerUI.internalSharedInstance.lockerUIOptions.navBarTintColor.color
            let newImage = oldImage?.imageWithColor(color)
            button?.setImage(newImage, for: UIControlState())
        }
    }
    
    //MARK: -
    @IBAction func backButtonAction(_ sender: UIButton)
    {
        self.completion?( LockerUIDialogResult.backward )
    }
    
    @IBAction func cancelButtonAction(_ sender: UIButton)
    {
        self.completion?( LockerUIDialogResult.cancel )
    }
    
    //MARK: -
    func shakeViewForError(_ view: UIView)
    {
        view.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.1, initialSpringVelocity: 0.2, options: UIViewAnimationOptions(), animations: { () -> Void in
            view.transform = CGAffineTransform.identity
            }, completion: nil)
    }
    
    
    //MARK: -
    func adjustUISettingsForDarkButton( _ button: UIButton )
    {
        button.setBackgroundColor(LockerUI.internalSharedInstance.darkColor, forUIControlState: UIControlState())
        button.setBackgroundColor(LockerUI.internalSharedInstance.darkColor.colorWithHSB(0, saturation: 0, brightness: -11/255), forUIControlState: .highlighted)
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.setTitleColor(UIColor(white: 0.8, alpha: 1), for: .highlighted)
        button.layer.cornerRadius = 5.0
        button.layer.masksToBounds = true
    }
    
    func adjustUISettingsForWhiteButton( _ button: ShadowButton )
    {
        button.setTitleColor(LockerUI.internalSharedInstance.mainColor, for: UIControlState())
        button.buttonColor = UIColor.white
        button.shadowColor = LockerUI.internalSharedInstance.lightColor
    }
    
    func adjustUISettingsForRedButton( _ button: ShadowButton )
    {
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.buttonColor = UIColor(red: 0.93, green: 0.13, blue: 0.11, alpha: 1.0)
        button.shadowColor = UIColor(red: 0.69, green: 0.08, blue: 0.11, alpha: 1.0 )
    }
    
}
