//
//  LockerUI+UnlockOrRegistration.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 14.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import Foundation
import CSCoreSDK



extension LockerUI
{
    
    fileprivate func clearSessionTimer()
    {
        self.sessionTimer?.cancel()
        self.sessionTimer = nil
    }
    
    public func unlockOrRegisterWithCompletion( _ completion : @escaping UIUnlockCompletion )
    {
        self.unlockOrRegister( animated: true, completion: completion )
    }
    
    public func unlockOrRegister( animated: Bool, completion : @escaping UIUnlockCompletion )
    {
        let currentUserStatus = self.locker.status
        switch currentUserStatus.lockStatus {
        case .unregistered:
            self.registerUser(animated: animated, completion: { registerUserResult in
                switch registerUserResult {
                case .success(_):
                    completion( LockerUIDialogBoolResult.success(true))
                    
                case .failure( let error ):
                    self.clearSessionTimer()
                    completion( LockerUIDialogBoolResult.failure(error))
                }
            })
            
        case .locked:
            self.unlockUser(animated: animated, completion: completion)
            
        case .unlocked:
            completion( LockerUIDialogBoolResult.success(true))
        }
    }
    
    // MARK: - 1) Registration step -login
    //--------------------------------------------------------------------------
    public func registerUserWithCompletion( _ completion : @escaping RegistrationCompletion )
    {
        self.registerUser( animated: true, completion: completion)
    }
    
    //--------------------------------------------------------------------------
    public func registerUser(animated: Bool, completion : @escaping RegistrationCompletion )
    {
        self.sessionTimer = WebSessionTimer( completion:completion)
        
        (GlobalUserInteractiveQueue).async(execute: {
            if let url = self.locker.registrationURL() {
                
                let locker = CoreSDK.sharedInstance.locker as! Locker
                locker.useOAuth2URLHandler( self.resumeUserRegistrationUsingOAuth2Url, completion: completion )
                
                (GlobalMainQueue).async( execute: {
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationStarted.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.debug, format: "OAuth2 request has been send with url: \(url)")
                    self.pushWebViewControllerOnLockerStack( animated: animated, url: url, completion: completion)
                })
            }
            else {
                self.locker.completionQueue.async {
                    completion( CoreResult.failure(LockerError.errorOfKind( .emptyClientId) ))
                }
            }
        })
    }
    
    //--------------------------------------------------------------------------
    fileprivate func pushWebViewControllerOnLockerStack(animated: Bool, url:URL, completion : @escaping RegistrationCompletion)
    {
        let webViewContorller = self.viewControllerWithName(LockerUI.WebViewSceneName) as! WebViewController
        
        webViewContorller.requestURL = url
        webViewContorller.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        webViewContorller.backgroundTint = self.mainColor
        webViewContorller.lockerRedirectUrlPath = self.locker.redirectUrlPath
        webViewContorller.testingJSForRegistration = self.testingJSForRegistration
        webViewContorller.completion = { result in
            self.clearSessionTimer()
            switch result {
            case .success( _ as Int):
                completion(CoreResult.success(true))
                
            case .failure( let error ):
                if ( error is CoreSDKError ) {
                    let coreError = ( error as! CoreSDKError )
                    if ( coreError.isServerError || ( coreError.code == HttpStatusCodeNotFound ) || ( coreError.kind == .operationCancelled ) ) {
                        completion(CoreResult.failure(coreError))
                        return
                    }
                }
                completion(CoreResult.failure(LockerError.errorOfKind(.registrationFailed, underlyingError: error)))
                
            default:
                self.popToRootLockerUIControllerWithCompletion({
                    completion(CoreResult.success(false))
                })
            }
        }
        
        self.pushLockerUIController(webViewContorller, animated: animated)
    }
    
    // MARK: - 2) Registration step - continue
    internal func resumeUserRegistrationUsingOAuth2Url( _ oauth2url: URL ) -> Bool
    {
        self.clearSessionTimer()
        
        let urlPath = oauth2url.absoluteString
        if !self.locker.canContinueWithOAuth2UrlPath( urlPath) {
            return false
        }
        
        clog(LockerUI.ModuleName, activityName: LockerUIActivities.ProceedWithOAuthURL.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.debug, format: "Got OAuth2 URL: \(oauth2url)"  )
        
        let locker = CoreSDK.sharedInstance.locker as! Locker
        guard let oauth2handler: OAuth2Handler = locker.oauth2handler else {
            assert( false, "CoreSDK.oauth2handler not set!")
            return false
        }
        
        self.proceedUserRegistrationWithCompletion( oauth2handler.completion!)
        return true
    }
    
    
    // MARK: - 0) Unregister User
    public func unregisterUserWithCompletion( _ completion: UIUnlockCompletion? )
    {
        let status = self.locker.status.lockStatus
        if status == LockStatus.unregistered {
            completion?( LockerUIDialogBoolResult.success(true))
            
        } else {
            
            self.showWaitViewWithMessage( "info-moment", detailMessage: "info-unregistration-in-progress")
            self.locker.unregisterUserWithCompletion( { result in
                DispatchQueue.main.async(execute: {
                    self.dismissWaitViewAnimated(true, dismissWaitCompletion: {
                        if let unregisterCompletion = completion {
                            var dialogResult: LockerUIDialogBoolResult!
                            switch result {
                            case .success:
                                dialogResult = LockerUIDialogBoolResult.success(true)
                                
                            case .failure( let error):
                                dialogResult = LockerUIDialogBoolResult.failure( error)
                                if ( error is CoreSDKError ) {
                                    if ( ( error as! CoreSDKError ).kind == .operationCancelled ) {
                                        dialogResult = LockerUIDialogBoolResult.cancel
                                    }
                                }
                            }
                            unregisterCompletion( dialogResult )
                        }
                    })
                })
            })
        }
    }
    
    // MARK: Private methods
    
    // MARK: - 3) Choose the LockType
    fileprivate func proceedUserRegistrationWithCompletion( _ completion : @escaping RegistrationCompletion )
    {
        if self.lockerUIOptions.allowedLockTypes.count == 1,
            let forcedLockType = self.lockerUIOptions.allowedLockTypes.first?.lockType {
            self.registerUserWithLockType( forcedLockType, completion: completion )
        } else {
            let inputTypeController = self.viewControllerWithName( LockerUI.InputTypeSceneName ) as! InputTypeViewController
            inputTypeController.lockerUIOptions = self.lockerUIOptions
            inputTypeController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
            inputTypeController.backgroundTint = self.mainColor
            
            inputTypeController.completion = { result in
                switch result {
                case .success( let inputButtonTag as Int):
                    let lockType = LockType( rawValue: inputButtonTag )!
                    self.registerUserWithLockType( lockType, completion: completion )
                    
                case .cancel, .backward:
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( CoreResult.failure( CoreSDKError.errorOfKind( .operationCancelled)) )
                    })
                    
                case .failure( let error ):
                    if ( error is CoreSDKError ) {
                        if ( ( error as! CoreSDKError ).kind == .operationCancelled ) {
                            completion( CoreResult.failure( error))
                            return
                        }
                    }
                    completion( CoreResult.failure( LockerError.errorOfKind(.registrationFailed, underlyingError: error)))
                    
                default:
                    self.popToRootLockerUIControllerWithCompletion(nil)
                }
            }
            self.pushLockerUIController( inputTypeController )
        }
    }
    
    // MARK: - 4) Registration step - Input password
    fileprivate func registerUserWithLockType( _ lockType: LockType, completion: @escaping RegistrationCompletion )
    {
        do {
            try self.checkLockType(lockType)
        }
        catch let error {
            clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationFinished.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.error, format: "LockType: \(lockType), error: \(error.localizedDescription) User registration unsuccessfull." )
            completion(CoreResult.failure(error as NSError))
        }

        self.remainingAttempts = nil
        
        if let passwordController = self.passwordControllerWithLockType( lockType ) {
            
            passwordController.backgroundTint = self.mainColor
            passwordController.dialogType = PasswordDialogType.inputPasswordAndVerifyThem
            passwordController.passwordLength = Int( self.passwordLengthWithLockType( lockType ) )
            passwordController.step = 0
            passwordController.remainingAttempts = self.remainingAttempts
            passwordController.lockerViewOptions = LockerViewOptions.showBackButton.rawValue
            
            passwordController.completion = { passwordInput in
                
                switch passwordInput {
                case .success( let password ):
                    self.showWaitViewWithMessage( "info-moment", detailMessage: "info-registration-in-progress" )
                    self.locker.completeUserRegistrationWithLockType( lockType, password: password as? String, completion: { ( result: CoreResult<Bool> ) in
                        switch result {
                        case .success:
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( CoreResult.success( true ) )
                            })
                            
                        case .failure( let error ):
                            if ( error is CoreSDKError ) {
                                if ( ( error as! CoreSDKError ).kind == .operationCancelled ) {
                                    completion( CoreResult.failure( CoreSDKError.errorOfKind( .operationCancelled)))
                                    return
                                }
                            }
                            
                            var options: StatusScreenOptions!
                            let coreError: CoreSDKError = ( ( error is CoreSDKError ) ? error as! CoreSDKError : CoreSDKError.errorWithCode(error.code, underlyingError: error)! )
                            let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController

                            if ( coreError.isNetworkError ) {
                                // Problem with connection to internet.
                                options                       = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-network-connection-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
                                options.statusDescriptionText = LockerUI.localized( "info-connect-to-internet-and-try-again" )
                            }
                            else if ( coreError.isServerError ) {
                                // Http error 5xx
                                options                       = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-different-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
                                options.statusDescriptionText = LockerUI.localized( "info-retry-later" )
                            }
                            else {
                                options = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-user-registration-failed" ), actionCaption: LockerUI.localized( "btn-register" ) )
                                options.statusDescriptionText = error.localizedDescription
                            }
                            
                            statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
                            statusController.options = options
                            statusController.backgroundTint = self.mainColor
                            
                            statusController.completion = { result in
                                switch result{
                                case .success(_):
                                    self.popToRootLockerUIController( animated: true, dismissCompletion: {
                                        self.registerUserWithCompletion({(result: CoreResult<Bool>) in
                                            switch result {
                                            case .success(_):
                                                completion( CoreResult.success( true ) )
                                            case .failure(let error):
                                                completion( CoreResult.failure(error))
                                            }
                                        })
                                    })
                                    
                                default:
                                    self.popToRootLockerUIControllerWithCompletion( {
                                        completion( CoreResult.failure( CoreSDKError.errorOfKind( .operationCancelled) ) )
                                    })
                                }
                            }
                            
                            self.locker.unregisterUserWithCompletion({ result in
                                //self.pushAlertWithError( error, withViewController: statusController )
                                self.popToRootLockerUIControllerAndPushNewController(statusController)
                            })
                        }
                    })
                case .backward:
                    self.popLockerUIController()
                    
                case .cancel:
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( CoreResult.failure( CoreSDKError.errorOfKind( .operationCancelled) ) )
                    })
                case .failure( let nestedError ):
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( CoreResult.failure( LockerError.errorOfKind(.loginFailed, underlyingError: nestedError ) ) )
                    })
                }
            }
            self.pushLockerUIController( passwordController )
            
        } else {
            // No auth. selected.
            self.showWaitViewWithMessage( "info-moment", detailMessage: "info-registration-in-progress" )
            self.locker.completeUserRegistrationWithLockType( lockType, password: nil, completion: { result in
                switch result {
                case .success:
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( CoreResult.success( true ) )
                    })
                case .failure( let error ):
                    if ( error is CoreSDKError ) {
                        if ( ( error as! CoreSDKError ).kind == .operationCancelled ) {
                            completion( CoreResult.failure( error) )
                            return
                        }
                    }
                    
                    let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
                    var options = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-user-registration-failed" ), actionCaption: LockerUI.localized( "btn-register" ) )
                    options.statusDescriptionText = LockerUI.localized( "info-user-registration-failed-description" )
                    statusController.options = options
                    statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
                    statusController.backgroundTint = self.mainColor
                    
                    statusController.completion = { result in
                        self.popToRootLockerUIControllerWithCompletion( {
                            completion( CoreResult.failure( CoreSDKError.errorOfKind( .operationCancelled) ) )
                        })
                    }
                    self.locker.unregisterUserWithCompletion({ result in
                        //self.pushAlertWithError( error, withViewController: statusController )
                        self.popToRootLockerUIControllerAndPushNewController(statusController)
                    })
                }
            })
        }
    }
    
}

