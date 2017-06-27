//
//  LockerUIApi.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 25.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import Foundation
import CSCoreSDK


/**
The LockerUI public API.
*/

/**
 * Determines, where are controls for the landscape UI orientation displayed.
 */
public enum UIHandOrientation: Int {
    case right = 0
    case left  = 1
}


public protocol LockerUIApi
{
    /**
     * Get or set current UI arrangement for the landscape device orientation.
     */
    var currentUIHandOrientation: UIHandOrientation {get set}
    
    /**
     Determines whether the locker UI is visible.
    */
    var isLockerUIVisible : Bool {get}
    
    /**
     Sets the lockerUIOptions.
     - parameter options: LockerUIOptions to be set.
     */
    func useLockerUIOptions( _ options: LockerUIOptions ) -> LockerUI
    

    /**
     Starts the LockerUI authentication flow. When user is not registered yet, the user registration process will be started.
     When user is locked, the user unlock process is started.
     - parameter authFlowOptions: Options for user authentication process. If not set, the default AuthFlowOptions will be used.
     - parameter completion: Authentication process result status.
     */
    func startAuthenticationFlow( options authFlowOptions: AuthFlowOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    
    /**
     Starts the LockerUI authentication flow. When user is not registered yet, the user registration process will be started.
     When user is locked, the user unlock process is started.
     - parameter authFlowOptions: Options for user authentication process. If not set, the default AuthFlowOptions will be used.
     - parameter completion: Authentication process result status.
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     */
    func startAuthenticationFlow(animated: Bool, options authFlowOptions: AuthFlowOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    
    
    /**
     Starts the UI flow (with animation) to change user lockType and password.
     - parameter completion: Password change result.
     */
    func changePasswordWithCompletion( _ completion: @escaping UIUnlockCompletion )
    
    /**
     Starts the UI flow (with animation) to change user lockType and password.
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     - parameter completion: Password change result.
     */
    func changePassword(animated: Bool, completion: @escaping UIUnlockCompletion )
    
    /**
     Shows animated the info screen using options when the application is unlocked with informations:
     
     - Current lockType
     
     and user choice:
     
     - Change user security ( lockType and password ).
     - Unregister user.
     
     - parameter displayInfoOptions: A message in the alert dialog to be shown before user unregistration.
     - parameter completion: The LockStatus after user choice.
     */
    func displayInfo( options displayInfoOptions: DisplayInfoOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    
    /**
     Shows the info screen using options when the application is unlocked with informations:
     
     - Current lockType
     
     and user choice:
     
     - Change user security ( lockType and password ).
     - Unregister user.
     
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     - parameter displayInfoOptions: A message in the alert dialog to be shown before user unregistration.
     - parameter completion: The LockStatus after user choice.
     */
    func displayInfo( animated: Bool, options displayInfoOptions: DisplayInfoOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )

    /**
     Cancel all running locker operations, dismisses UI (with animation) and returns the current lockerStatus in completion handler.
     - parameter completion: The current user status.
     */
    func cancelWithCompletion( _ completion: (( _ status: LockerStatus ) -> ())? )
    
    
    /**
        Cancel all running locker operations, dismisses UI and returns the current lockerStatus in completion handler.
        - parameter completion: The current user status.
        - parameter animated: Whether there should be crossfade animation at the start of the flow
    */
    func cancel(animated : Bool, completion: (( _ status: LockerStatus ) -> ())?)

    /**
       Enables execution of injected JavaScript code to allow testers to automate
       entering and submiting credentials and thus speed up human testing considerably.
     
       - parameter javaScript: valid JavaScript code that should be injected 
                               into the page and executed when the login page 
                               finishes loading.
     */
    func injectTestingJSForRegistration(javaScript: String?)
}


/**
    A LockerUIDialogBoolResult wrapper.
*/
public typealias UIUnlockCompletion = (( _ result: LockerUIDialogBoolResult ) ->() )


//==============================================================================
/**
    When to skip the status screen.

    - Always: Skip the status screen always.
    - WhenLocked: Skip the status screen only if the LockerStatus is locked.
    - WhenNotRegistered: Skip the status screen only if the LockerStatus is Unregistered.
    - Never: Never skip the status screen.
*/
public enum SkipStatusScreen: UInt8
{
    case always = 0
    case whenLocked = 1
    case whenNotRegistered = 2
    case never = 3
}

//==============================================================================
/**
    User password attributes.

    - lockType: The password type. 
    - length: The password length. Has to be set in the design phase.
    - minLength: The minimal password length. If the password length is less than minLength, an exception will be thrown.
    - maxLength: The maximal password length. If the password length is greater than maxLength, an exception will be thrown.
*/
public struct LockInfo
{
    var lockType: LockType
    var length: UInt8
    
    public init()
    {
        self.lockType = LockType.pinLock
        self.length = 6
    }
    
    public init( lockType: LockType )
    {
        self.lockType = lockType
        switch lockType {
        case .pinLock:
            self.length = 6
        case .gestureLock:
            self.length = 4
        default:
            self.length = 0
        }
    }
    
    public init( lockType: LockType, length: UInt8 )
    {
        self.lockType = lockType
        self.length = length
    }
}

//==============================================================================
/**
 * - never: Logo is never displayed
 * - exceptRegistration: Logo is displayed everywhere besides WebView registration screen
 * - always: Logo is displayed on all screens
 */
public enum ShowLogoOption: Int {
    case never               = 0
    case exceptRegistration  = 1
    case always              = 2
}

//==============================================================================
/**
    General LockerUI options.

    - appName: Application display name.
    - allowedLockTypes: An array of LockInfo allowed for application.
    - backgroundImage: LockerUI background image.
    - customTint: LockerUI background color. When set, the background image and icons will be colorized with this color.
    - navBarTintColor: Navigation bar tint color.
    - navBarColor: Navigation bar background color.
    - showLogo: Determines when to show the logo in the navigation bar.
*/
public struct LockerUIOptions
{
    public var appName: String?
    public var allowedLockTypes: [LockInfo]
    public var backgroundImage: UIImage?
    public var customTint: UIColor?
    public var navBarTintColor: CSNavBarTintColor = .default
    public var navBarColor:CSNavBarColor = .default
    public var showLogo: ShowLogoOption = .always
    
    public init()
    {
        let bundleInfoDict: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        let bundleName = bundleInfoDict["CFBundleDisplayName"] as? String
        if let bundleName = bundleName{
            self.appName = bundleName
        } else {
            self.appName = "AppName"
        }
        self.allowedLockTypes = [LockInfo(lockType:LockType.pinLock),
                                 LockInfo(lockType:LockType.gestureLock),
                                 LockInfo(lockType:LockType.fingerprintLock),
                                 LockInfo(lockType:LockType.noLock)]
    }
}

public enum CSNavBarColor{
    
    case `default`
    case white
    case custom(color: UIColor)
    
    var color : UIColor {
        switch self{
        case .default:
            return UIColor(red: 202.0/255, green: 218.0/255, blue: 241.0/255, alpha: 1.0)
        case .white:
            return UIColor.white
        case .custom(let color):
            return color
        }
    }
    
}

public enum CSNavBarTintColor {
    
    case `default`
    case dark
    case custom(color: UIColor)
    
    var color : UIColor {
        switch self{
        case .default:
            return UIColor(red: 35.0/255.0, green: 74.0/255.0, blue: 128.0/255.0, alpha: 1.0)
            
        case .dark:
            return UIColor(red: 33.0/255.0, green: 33.0/255.0, blue: 33.0/255.0, alpha: 1.0)
            
        case .custom(let color):
            return color
        }
    }
    
}



//==============================================================================
/**
    Attributes for authentication flow customization.

    - skipStatusScreen: Specifies when to skip the LockerUI status screen.
    - registrationScreenText: Specifies text to be used on the registration screen.
    - lockedScreenText: Specifies text to be used on the locked screen.
    - hideCancelButtonInAuthFlow: Specifies if developer want hide cancel button during authorization flow 
*/
public struct AuthFlowOptions
{
    var skipStatusScreen: SkipStatusScreen
    var registrationScreenText: String?
    var lockedScreenText: String?
    var hideCancelButton: Bool
    
    public init()
    {
        self.skipStatusScreen = SkipStatusScreen.always
        self.hideCancelButton = false
    }
    
    public init( skipStatusScreen: SkipStatusScreen, registrationScreenText: String?, lockedScreenText: String?, hideCancelButton:Bool = false)
    {
        self.skipStatusScreen = skipStatusScreen
        self.registrationScreenText = registrationScreenText
        self.lockedScreenText = lockedScreenText
        self.hideCancelButton = hideCancelButton
    }
    
}

//==============================================================================
/**
    Specifies text in the unregister alert dialog.

    - unregisterPromptText: The unregister warning message to be shown before unregistering user. Whe not set, a default message will be shown.
*/
public struct DisplayInfoOptions
{
    public var unregisterPromptText: String?
    
    //--------------------------------------------------------------------------
    public init()
    {
        self.unregisterPromptText = LockerUI.localized( "unregister-prompt-text" )
    }
    
    //--------------------------------------------------------------------------
    public init( unregisterPromptText: String )
    {
        self.unregisterPromptText = unregisterPromptText
    }
}

//==============================================================================
/**
    Display options for the status screen.
    - appName: Application display name. When omitted, a CFBundleName will be used.
    - statusIconName:
    - statusMainText: Mandatory status text.
    - statusDescriptionText: Optional status description.
    - actionCaption: Mandatory action button caption.
*/
public struct StatusScreenOptions
{
    var appName: String?
    var statusIconName: String
    var statusMainText: String
    var statusDescriptionText: String?
    var actionCaption: String
    
    public init( iconName: String, mainText: String, actionCaption: String )
    {
        let bundleInfoDict: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        let bundleName                   = bundleInfoDict["CFBundleDisplayName"] as? String
        if let bundleName = bundleName{
            self.appName = bundleName
        }else{
            self.appName = "AppName"
        }
        
        self.statusIconName = iconName
        self.statusMainText = mainText
        self.actionCaption = actionCaption
    }
    
}
