//
//  LockerUIObjC.swift
//  CSLockerUI
//
//  Created by Michal Sverak on 11/6/17.
//  Copyright © 2017 Applifting. All rights reserved.
//
/*
 Here is a short list of Swift features that are not available in objective-c: tuples,
 generics, any global variables, structs, typealiases, or enums defined in swift,
 and the top-level swift functions.
 https://medium.com/ios-os-x-development/swift-and-objective-c-interoperability-2add8e6d6887
 */

import Foundation
import CSCoreSDK

@objc public class LockerUIObjC: NSObject {
    
    /**
     LockerUI shared instance, singleton.
     */
    @objc public static var sharedInstance = LockerUIObjC()
    
    /**
     * Get or set current UI arrangement for the landscape device orientation.
     */
    @objc public var currentUIHandOrientation: UIHandOrientation {
        get {
            return LockerUI.sharedInstance.currentUIHandOrientation
        }
        set(orientation) {
            LockerUI.sharedInstance.currentUIHandOrientation = orientation
        }
    }
    
    /**
     * Get supported device orientations.
     */
    @objc public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return LockerUI.sharedInstance.supportedInterfaceOrientations
        }
    }
    
    /**
     Determines whether the locker UI is visible.
     */
    @objc public var isLockerUIVisible : Bool {
        get {
            return LockerUI.sharedInstance.isLockerUIVisible
        }
    }
    
    /**
     Sets the lockerUIOptions.
     - parameter options: LockerUIOptions to be set.
     */
    @discardableResult
    @objc public func useLockerUIOptions(appName: String, allowedLockTypes: [LockInfo], backgroundImage: UIImage?, customTint: UIColor?, navBarColor: UIColor?, navBarTint: UIColor?) -> LockerUIObjC {
        
        var options = LockerUIOptions()
        
        options.appName = appName
        options.allowedLockTypes = allowedLockTypes
        options.backgroundImage = backgroundImage
        options.customTint = customTint
        if let color = navBarColor {
            options.navBarColor = .custom(color: color)
        }
        if let color = navBarTint {
            options.navBarTintColor = .custom(color: color)
        }
        
        options.allowedLockTypes = allowedLockTypes
        
        LockerUI.sharedInstance.useLockerUIOptions(options)
        return self
    }
    
    /**
     Sets the auth flow options.
     - parameter skipStatusScreen: should Status screen be skipped or displayed to the user?
     - parameter registrationScreenText: text that should be displayed on registration screen
     - parameter lockedScreenText: text that should be displayed on locked screen
     */
    @objc public func setAuthFlowOptions(skipStatusScreen: SkipStatusScreen, registrationScreenText: String?, lockedScreenText: String?) {
        LockerUI.sharedInstance.authFlowOptions = AuthFlowOptions(skipStatusScreen: skipStatusScreen,
                                                                  registrationScreenText: registrationScreenText,
                                                                  lockedScreenText: lockedScreenText)
    }
    
    /**
     Starts the LockerUI authentication flow. When user is not registered yet, the user registration process will be started.
     When user is locked, the user unlock process is started.
     - parameter authFlowOptions: Options for user authentication process. If not set, the default AuthFlowOptions will be used.
     - parameter completion: Authentication process result status.
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     */
    @objc public func startAuthenticationFlow(animated: Bool, skipStatusScreen: SkipStatusScreen, registrationScreenText: String?, lockedScreenText: String?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) ) {
        let options = AuthFlowOptions(skipStatusScreen: skipStatusScreen,
                                      registrationScreenText: registrationScreenText,
                                      lockedScreenText: lockedScreenText)
        LockerUI.sharedInstance.startAuthenticationFlow(animated: animated, options: options) { status in
            completion(status)
        }
    }
    
    /**
     Starts the LockerUI authentication flow. When user is not registered yet, the user registration process will be started.
     When user is locked, the user unlock process is started.
     - parameter authFlowOptions: Options for user authentication process. If not set, the default AuthFlowOptions will be used.
     - parameter completion: Authentication process result status.
     */
    @objc public func startAuthenticationFlow(skipStatusScreen: SkipStatusScreen, registrationScreenText: String?, lockedScreenText: String?, completion: @escaping (LockerStatus) -> Void) {
        let options = AuthFlowOptions(skipStatusScreen: skipStatusScreen,
                                      registrationScreenText: registrationScreenText,
                                      lockedScreenText: lockedScreenText)
        LockerUI.sharedInstance.startAuthenticationFlow(options: options) { status in
            completion(status)
        }
    }
    
    /**
     Starts the UI flow (with animation) to change user lockType and password.
     - parameter completion: Password change result.
     */
    @objc public func changePassword(success: ((Bool)->())?, backward: (()->())?, cancel: (()->())?, failure: ((NSError)->())?) {
        LockerUI.sharedInstance.changePasswordWithCompletion { (result) in
            switch result {
            case .success(let result):
                success?(result)
            case .backward:
                backward?()
            case .cancel:
                cancel?()
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    /**
     Starts the UI flow (with animation) to change user lockType and password.
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     - parameter completion: Password change result.
     */
    @objc public func changePassword(animated: Bool, success: ((Bool)->())?, backward: (()->())?, cancel: (()->())?, failure: ((NSError)->())?) {
        LockerUI.sharedInstance.changePassword(animated: animated) { (result) in
            switch result {
            case .success(let result):
                success?(result)
            case .backward:
                backward?()
            case .cancel:
                cancel?()
            case .failure(let error):
                failure?(error)
            }
        }
    }
    
    /**
     Shows animated the info screen using options when the application is unlocked with informations:
     
     - Current lockType
     
     and user choice:
     
     - Change user security ( lockType and password ).
     - Unregister user.
     
     - parameter displayInfoOptions: A message in the alert dialog to be shown before user unregistration.
     - parameter completion: The LockStatus after user choice.
     */
    @objc public func displayInfo(unregisterPromptText: String?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) ) {
        LockerUI.sharedInstance.displayInfo(options: unregisterPromptText == nil ? nil : DisplayInfoOptions(unregisterPromptText: unregisterPromptText!), completion: completion)
    }
    
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
    @objc public func displayInfo( animated: Bool, unregisterPromptText: String?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) ) {
        LockerUI.sharedInstance.displayInfo(animated: animated, options: unregisterPromptText == nil ? nil : DisplayInfoOptions(unregisterPromptText: unregisterPromptText!), completion: completion)
    }
    
    /**
     Cancel all running locker operations, dismisses UI (with animation) and returns the current lockerStatus in completion handler.
     - parameter completion: The current user status.
     */
    @objc public func cancelWithCompletion( _ completion: (( _ status: LockerStatus ) -> ())? ) {
        LockerUI.sharedInstance.cancelWithCompletion(completion)
    }
    
    /**
     Cancel all running locker operations, dismisses UI and returns the current lockerStatus in completion handler.
     - parameter completion: The current user status.
     - parameter animated: Whether there should be crossfade animation at the start of the flow
     */
    @objc public func cancel(animated : Bool, completion: (( _ status: LockerStatus ) -> ())?) {
        LockerUI.sharedInstance.cancel(animated: animated, completion: completion)
    }
    
    /**
     Enables execution of injected JavaScript code to allow testers to automate
     entering and submiting credentials and thus speed up human testing considerably.
     
     - parameter javaScript: valid JavaScript code that should be injected
     into the page and executed when the login page
     finishes loading.
     */
    @objc public func injectTestingJSForRegistration(javaScript: String?) {
        LockerUI.sharedInstance.injectTestingJSForRegistration(javaScript: javaScript)
    }
    
    
    
}
