//
//  LockerUI.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 14.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import UIKit
import CSCoreSDK
import Security
import LocalAuthentication


/**
 The generic LockerUI dialog result.
 - Success(T): User did choice on the LockerUI dialog and the successfull result of choice is returned as the data object.
 - Backward: User tapped on the back button. Used internally.
 - Cancel: User tapped on the Cancel button.
 - Failure(NSError): User did choice on the LockerUI dialog and the unsuccessfull result of choice is returned as the NSError.
 */
public enum LockerUIDialogResult<T>
{
    case success(T)
    case backward
    case cancel
    case failure(NSError)
}

/**
 * Successfull LockerUI dialog result.
 */
@inline(__always) public func lockerUIDialogResultOk() -> LockerUIDialogResult<AnyObject>
{
    return LockerUIDialogResult.success(true as AnyObject)
}

/**
 An alias for LockerUIDialogResult returning Bool true instead of data object.
 */
public typealias LockerUIDialogBoolResult = LockerUIDialogResult<Bool>


private let kUIHandOrientation = "cs.lockerui.handOrientation"

/**
 * LockerUI log activities.
 */
//==============================================================================
internal enum LockerUIActivities: String {
    case UserRegistrationStarted  = "UserRegistrationStarted"
    case ProceedWithOAuthURL      = "ProceedWithOAuthURL"
    case UserRegistrationFinished = "UserRegistrationFinished"
    case TouchID                  = "TouchID"
    case AuthenticationFlow       = "AuthenticationFlow"
    case DisplayInfo              = "DisplayInfo"
    case ChangePassword           = "ChangePassword"
    case NewLockType              = "NewLockType"
    case UnlockUser               = "UnlockUser"
}


//==============================================================================
public class LockerUI: NSObject, LockerUIApi
{
    public static let BundleIdentifier                  = "CSLockerUI"
    public static let StoryboardName                    = "Locker"
    internal static let ModuleName                      = "LockerUI"
    
    //MARK: Scene names ...
    public static let RegisterSceneName                 = "register_user"
    public static let InputTypeSceneName                = "input_type"
    public static let GestureInputSceneName             = "gesture_login"
    public static let PinInputSceneName                 = "pin_login"
    public static let FingerprintInputSceneName         = "fingerprint_login"
    public static let WaitSceneName                     = "wait_view"
    public static let BaseSceneName                     = "lockerui_base"
    public static let StatusSceneName                   = "lockerui_status"
    public static let DisplayInfoSceneName              = "lockerui_display_info"
    public static let RepeatLoginOrRegisterSceneName    = "lockerui_repeat_unlock_or_register"
    public static let WebViewSceneName                  = "web_view"
    
    public var remainingAttempts: Int?
    
    internal var lightColor: UIColor
    internal var darkColor: UIColor
    internal var mainColor: UIColor {
        didSet {
            let auxColors = LockerUI.createAuxColors(mainColor)
            self.lightColor = auxColors[0]
            self.darkColor = auxColors[1]
        }
    }
    
    var sessionTimer: WebSessionTimer?
    
    internal var testingJSForRegistration: String?
    fileprivate let testingJSUrlWhitelist = [
        "https://bezpecnost.csast.csas.cz/mep/fs/fl/oauth2/",
        "https://www.csast.csas.cz/widp/oauth2/"
    ]
    
    public var isLockerUIVisible : Bool {
        if (self.lockerUIWindow?.isHidden == false || self.lockerWaitWindow?.isHidden == false){
            return true
        }
        return false
    }
    
    public var currentUIHandOrientation: UIHandOrientation {
        get {
            return UIHandOrientation(rawValue: UserDefaults.standard.integer(forKey: kUIHandOrientation))!
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kUIHandOrientation)
        }
    }
    
    //--------------------------------------------------------------------------
    func swapCurrentUIHandOrientation()
    {
        let currentHandOrientation = self.currentUIHandOrientation
        switch ( currentHandOrientation ) {
        case .right:
            self.currentUIHandOrientation = .left
        case .left:
            self.currentUIHandOrientation = .right
        }
    }
    
//    public var supportedInterfaceOrientations : UIInterfaceOrientationMask
//    {
//        return UIInterfaceOrientationMask.All
//    }
    
    
    class func getBundle() -> Bundle
    {
        let bundleForThisClass = Bundle(for: LockerUI.classForCoder())
        if bundleForThisClass.bundleIdentifier == BundleIdentifier{
            return bundleForThisClass
        }else{
            return Bundle( url: bundleForThisClass.url(forResource: BundleIdentifier, withExtension: "bundle")!)!
        }
    }
    
    
    class func localized( _ string: String ) -> String
    {
        let localized =  NSLocalizedString( string, tableName: nil, bundle: LockerUI.getBundle(), value: "", comment: "")
        return localized
    }
    
    public class var sharedInstance: LockerUIApi {
        if let instance = _sharedInstance{
            return instance
        }else{
            let instance = LockerUI()
            _sharedInstance = instance
            return instance
        }
    }
    fileprivate static var _sharedInstance : LockerUI?
    
    internal class var internalSharedInstance : LockerUI{
        return sharedInstance as! LockerUI
    }
    
    public var authFlowOptions: AuthFlowOptions {
        get {
            if let options = self._authFlowOptions {
                return options
            } else {
                return AuthFlowOptions()
            }
        }
        set {
            self._authFlowOptions = newValue
        }
    }
    
    public var lockerUIOptions: LockerUIOptions {
        get {
            if let options = self._lockerUIOptions {
                return options
            } else {
                let newOptions = self.validateLockerUIOptions( LockerUIOptions() )
                if let tint = newOptions.customTint {
                    self.mainColor = tint
                }
                return newOptions
            }
        }
        set {
            self._lockerUIOptions = self.validateLockerUIOptions( newValue )
            if let tint = self._lockerUIOptions?.customTint {
                var hue = CGFloat(0)
                var saturation = CGFloat(0)
                var brightness = CGFloat(0)
                var alpha = CGFloat(0)
                tint.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                self.mainColor = UIColor(hue: hue, saturation: 0.87, brightness: 0.57, alpha: 1)
            }
            if self._lockerUIOptions?.backgroundImage == nil{
                self._lockerUIOptions?.backgroundImage = UIImage.init(named: "default-background", in: Bundle(for: LockerUI.self) , compatibleWith: nil)
            }
        }
    }
    
    public var locker: LockerAPI {
        return CoreSDK.sharedInstance.locker
    }
    
    public var canUseBiometrics: Bool {
        var error: NSError? = nil
        let result = LAContext().canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error )
  
        return result && error == nil
    }
    
    fileprivate var _authFlowOptions: AuthFlowOptions?
    fileprivate var _lockerUIOptions: LockerUIOptions?
    
    internal var waitController: WaitViewController?
    internal var lockerWaitWindow: UIWindow?
    internal var lockerUIWindow: UIWindow?
    
    
    //MARK: -
    //--------------------------------------------------------------------------
    required public override init()
    {
        self.mainColor = UIColor.init(hexString: "135091")
        let auxColors = LockerUI.createAuxColors(mainColor)
        self.lightColor = auxColors[0]
        self.darkColor = auxColors[1]
        
        UINavigationBar.appearance().barTintColor = UIColor.white
        
        super.init()
        lockerUIOptions = LockerUIOptions()
    }
    
    //MARK: - 1
    //--------------------------------------------------------------------------
    public func startAuthenticationFlow(animated: Bool, options authFlowOptions: AuthFlowOptions?, completion: @escaping ((_ status: LockerStatus) -> ()))
    {
        clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: "Entering authentication flow." )
        
        if let options = authFlowOptions {
            self.authFlowOptions = options
        }
        
        let finishMessage = "Finishing authentication flow."
        
        switch self.locker.status.lockStatus {
        case .unregistered:
            if self.authFlowOptions.skipStatusScreen.rawValue <= SkipStatusScreen.whenNotRegistered.rawValue {
                LockerUI.internalSharedInstance.unlockOrRegister( animated: animated, completion: { result in
                    switch result {
                    case .failure( let error ):
                        if ( error is CSErrorBase && ( (error as! CSErrorBase).isServerError || error.code == HttpStatusCodeNotFound) ) {
                            self.showStatusScreenWithLoginFailureInfoWithError( error, completion: { result in
                                switch ( result ) {
                                case .success(_):
                                    self.startAuthenticationFlow(options: authFlowOptions, completion: { status in
                                        clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                                        completion(status)
                                    })
                                    
                                default:
                                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                                    completion( self.locker.status )
                                }
                            })
                        }
                        else {
                            switch error.code {
                            case CoreSDKErrorKind.operationCancelled.rawValue:
                                self.popToRootLockerUIControllerWithCompletion({
                                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                                    completion( self.locker.status )
                                })
                                
                            default:
                                self.showAlertWithError( error , completion: {
                                    self.popToRootLockerUIControllerWithCompletion({
                                        clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                                        completion( self.locker.status )
                                    })
                                })
                            }
                        }
                    case .success, .cancel, .backward:
                        self.popToRootLockerUIControllerWithCompletion({
                            clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                            completion( self.locker.status )
                        })
                    }
                })
            }
            else {
                self.registerWithStatusScreen(animated: animated, completion:{ status in
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                    completion(status)
                })
            }
            
        case .locked:
            if self.authFlowOptions.skipStatusScreen.rawValue <= SkipStatusScreen.whenLocked.rawValue {
                
                LockerUI.internalSharedInstance.unlockOrRegister(animated: animated, completion: { result in
                    switch result {
                    case .failure:
                        self.popToRootLockerUIControllerWithCompletion({
                            clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                            completion( self.locker.status)
                        })
                        
                    case .success, .cancel, .backward:
                        self.popToRootLockerUIControllerWithCompletion({
                            clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                            completion( self.locker.status)
                        })
                    }
                })
            }
            else {
                self.unlockWithStatusScreen(animated: animated,completion : { status in
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                    completion(status)
                })
            }
            
        case .unlocked:
            clog(LockerUI.ModuleName, activityName: LockerUIActivities.AuthenticationFlow.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
            completion( self.locker.status )
        }
    }
    
    //--------------------------------------------------------------------------
    public func startAuthenticationFlow( options authFlowOptions: AuthFlowOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        self.startAuthenticationFlow(animated: true, options: authFlowOptions, completion: completion)
    }
    
    //--------------------------------------------------------------------------
    public func displayInfo(options displayInfoOptions: DisplayInfoOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        self.displayInfo(animated: true, options: displayInfoOptions, completion: completion);
    }
    
    //MARK: - registered -> change locker status
    //--------------------------------------------------------------------------
    public func displayInfo(animated: Bool, options displayInfoOptions: DisplayInfoOptions?, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: "Entering display info." )
        
        let finishMessage             = "Finishing display info."        
        let infoController            = self.viewControllerWithName( LockerUI.DisplayInfoSceneName ) as! DisplayInfoViewController
        infoController.options        = displayInfoOptions
        infoController.lockType       = self.locker.lockType
        infoController.backgroundTint = self.mainColor
        
        infoController.completion = { infoResult in
            switch infoResult {
            case .success:
                self.changePasswordWithCompletion({ changeResult in
                    switch changeResult{
                    case .backward:
                        clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                        
                    default:
                        self.popToRootLockerUIController(animated: true, dismissCompletion: {
                            clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                            completion( self.locker.status )
                        })
                    }
                })
            case .backward, .cancel, .failure:
                self.popToRootLockerUIController(animated: true, dismissCompletion: {
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                    completion( self.locker.status )
                })
            }
        }
        
        infoController.secondCompletion = { infoResult in
            switch infoResult {
            case .success:
                self.unregisterUserWithCompletion({ result in
                    self.popToRootLockerUIController(animated: true, dismissCompletion: {
                        clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                        completion( self.locker.status )
                    })
                })
                
            case .backward, .cancel, .failure:
                self.popToRootLockerUIController(animated: true, dismissCompletion: {
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.DisplayInfo.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.info, format: finishMessage )
                    completion( self.locker.status )
                })
            }
        }
        
        self.pushLockerUIController(infoController, animated: animated)
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    public func useLockerUIOptions( _ options: LockerUIOptions ) -> LockerUI
    {
        self.lockerUIOptions = options
        return self
    }
    
    //--------------------------------------------------------------------------
    func showAlertWithError( _ error: NSError, completion: (() -> ())? )
    {
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: LockerUI.localized( "title-error" ), message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert )
            let alertCompletion: ((UIAlertAction) -> Void)? = ( completion != nil ? { action in completion!() } : nil )
            alert.addAction( UIAlertAction(title: LockerUI.localized( "btn-cancel" ), style: UIAlertActionStyle.cancel, handler: alertCompletion ))
            
            if let topViewController = UIApplication.topViewController() {
                topViewController.present( alert, animated: false, completion: nil )
            } else {
                // Should not happen.
                completion?()
            }
        })
    }
    
    //MARK: - 3
    //--------------------------------------------------------------------------
    func registerWithStatusScreenAndCompletion( _ completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        self.registerWithStatusScreen( animated: true, completion: completion )
    }
    
    //--------------------------------------------------------------------------
    func registerWithStatusScreen( animated: Bool, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        var options = StatusScreenOptions( iconName: "icon-key", mainText: LockerUI.localized( "info-user-registration" ), actionCaption: LockerUI.localized( "btn-register" ) )
        
        if let appName = self.lockerUIOptions.appName {
            options.appName = appName
        }
        
        if let registrationInfo = self.authFlowOptions.registrationScreenText {
            options.statusDescriptionText = registrationInfo
        }
        else {
            options.statusDescriptionText = String( format: LockerUI.localized( "info-user-registration-description" ), (options.appName)! )
        }
        statusController.options = options
        statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        statusController.backgroundTint = self.mainColor
        
        statusController.completion = { result in
            switch result {
            case .success:
                self.unlockOrRegisterWithCompletion( { registerResult in
                    switch registerResult {
                    case .failure( let error ):
                        switch error.code{
                        case LockerErrorKind.loginTimeOut.rawValue:
                            self.popLockerUIController()
                        
                        case CoreSDKErrorKind.operationCancelled.rawValue :
                            // Pop without alert here.
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( self.locker.status )
                            })
                        
                        default:
                            self.showAlertWithError( error, completion: {
                                self.popToRootLockerUIControllerWithCompletion({
                                    completion( self.locker.status )
                                })
                            })
                        }
                    case .success, .cancel, .backward:
                        self.popToRootLockerUIControllerWithCompletion({
                            completion( self.locker.status )
                        })
                    }
                })
                
            default:
                self.popToRootLockerUIControllerWithCompletion({
                    completion( self.locker.status )
                })
            }
        }
        
        self.pushLockerUIController( statusController )
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    func registerAfterUnlockFailureWithStatusScreenAndCompletion( _ completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        
        var options = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-user-login-failed" ), actionCaption: LockerUI.localized( "btn-register" ) )
        
        if let appName = self.lockerUIOptions.appName {
            options.appName = appName
        }
        
        if let registrationInfo = self.authFlowOptions.registrationScreenText {
            options.statusDescriptionText = registrationInfo
        }
        else {
            options.statusDescriptionText = String( format: LockerUI.localized( "info-user-registration-description" ), (options.appName)! )
        }
        
        statusController.options = options
        statusController.backgroundTint = self.mainColor
        
        statusController.completion = { result in
            switch result {
            case .success:
                self.unlockOrRegisterWithCompletion( { registerResult in
                    switch registerResult {
                    case .failure( let error ):
                        self.showAlertWithError( error, completion: {
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( self.locker.status )
                            })
                        })
                    case .success, .cancel, .backward:
                        self.popToRootLockerUIControllerWithCompletion({
                            completion( self.locker.status )
                        })
                    }
                })
            default:
                self.popToRootLockerUIControllerWithCompletion({
                    completion( self.locker.status )
                })
            }
        }
        self.pushLockerUIController( statusController )
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    func unlockWithStatusScreenAndCompletion( _ completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        self.unlockWithStatusScreen( animated: true, completion: completion)
    }
        
    //--------------------------------------------------------------------------
    func unlockWithStatusScreen(animated: Bool, completion: @escaping ( ( _ status: LockerStatus ) -> () ) )
    {
        let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        var options = StatusScreenOptions( iconName: "lock-ok", mainText: LockerUI.localized( "info-user-unlock" ), actionCaption: LockerUI.localized( "btn-unlock" ) )
        
        if let appName = self.lockerUIOptions.appName {
            options.appName = appName
        }
        
        if let unlockInfo = self.authFlowOptions.lockedScreenText {
            options.statusDescriptionText = unlockInfo
        }
        else {
            options.statusDescriptionText = String( format: LockerUI.localized( "info-user-registration-description" ), (options.appName)! )
        }
        
        statusController.options = options
        statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        statusController.backgroundTint = self.mainColor
        
        statusController.completion = { result in
            switch result {
            case .success:
                self.unlockOrRegisterWithCompletion( { unlockResult in
                    switch  unlockResult {
                    case .failure:
                        self.registerAfterUnlockFailureWithStatusScreenAndCompletion( completion )
                        
                    case .success, .cancel, .backward:
                        self.popToRootLockerUIControllerWithCompletion({
                            completion( self.locker.status )
                        })
                    }
                })
                
            default:
                self.popToRootLockerUIControllerWithCompletion({
                    completion( self.locker.status )
                })
            }
        }

        self.pushLockerUIController( statusController )
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    func unlockOTPWithCompletion( _ completion: @escaping ( ( _ status: LockStatus ) -> () ) )
    {
        let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        statusController.options = StatusScreenOptions( iconName: "icon-key", mainText: "OTP Unlock", actionCaption: "TRY OTP UNLOCK" )
        if let appName = self.lockerUIOptions.appName {
            statusController.options?.appName = appName
        }
        
        if let unlockInfo = self.authFlowOptions.lockedScreenText {
            statusController.options?.statusDescriptionText = unlockInfo
        }
        else {
            statusController.options?.statusDescriptionText = String( format: LockerUI.localized( "info-user-registration-description" ), (statusController.options?.appName)! )
        }
        
        statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        
        statusController.completion = { result in
            switch result {
            case .success:
                self.locker.unlockUserUsingOTPWithCompletion( { result, remainingAttempts in
                    switch result {
                    case .success:
                        self.popToRootLockerUIControllerWithCompletion({
                            completion( self.locker.lockStatus )
                        })
                        
                    case .failure( let error ):
                        self.showAlertWithError( error , completion: {
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( self.locker.lockStatus )
                            })
                        })
                    }
                })
                
            default:
                self.popToRootLockerUIControllerWithCompletion({
                    completion( self.locker.lockStatus )
                })
            }
            
        }
        
        self.pushLockerUIController( statusController )
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    func validateLockerUIOptions( _ originalLockerUIOptions: LockerUIOptions ) -> LockerUIOptions
    {
        var lockerUIOptions  = originalLockerUIOptions
        var removeIndex: Int = -1
        var i: Int = 0
        
        for lockTypeItem in lockerUIOptions.allowedLockTypes {
            switch lockTypeItem.lockType {
            case .pinLock:
                if lockTypeItem.length < 4 || lockTypeItem.length > 8 {
                    assert( false, "PIN length must be set in interval 4..8" )
                }
            case .gestureLock:
                if lockTypeItem.length < 3 || lockTypeItem.length > 5 {
                    assert( false, "Gesture length must be set in interval 3..5" )
                }
            case .biometricLock:

                if !self.canUseBiometrics {
                    removeIndex = i
                }
            default:
                break
            }
            i += 1
        }
        
        if removeIndex >= 0 {
            lockerUIOptions.allowedLockTypes.remove(at: removeIndex)
        }
        
        return lockerUIOptions
    }
    
    //MARK: -
    //--------------------------------------------------------------------------
    fileprivate static func createAuxColors(_ mainColor: UIColor) -> [UIColor] {
        return [ mainColor.colorWithHSB(-10.0/360, saturation:-57.0/100 , brightness: 30/100),
                 mainColor.colorWithHSB(-8.0/360, saturation:2.0/100 , brightness: -5.0/100)]
    }
    
    //--------------------------------------------------------------------------
    public func passwordLengthWithLockType( _ lockType: LockType ) -> UInt8
    {
        for lockTypeItem in lockerUIOptions.allowedLockTypes {
            if lockTypeItem.lockType == lockType {
                return lockTypeItem.length
            }
        }
        return 4
    }
    
    //MARK: -
    
    
    //--------------------------------------------------------------------------
    public func cancel(animated: Bool, completion: ((_ status: LockerStatus) -> ())?) {
        self.locker.cancelWithCompletion( { status in
            self.popToRootLockerUIController( animated: true, dismissCompletion: {
                completion?( status )
            })
        })
    }
    
    //--------------------------------------------------------------------------
    public func cancelWithCompletion( _ completion: (( _ status: LockerStatus ) -> ())? )
    {
        self.cancel( animated: true, completion: completion)
    }
    
    //--------------------------------------------------------------------------
    func handlePossibleUnlockNetworkError( _ error: NSError, completion : @escaping UIUnlockCompletion ) -> Bool
    {
        if error is CoreSDKError {
            
            let statusController            = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
            statusController.backgroundTint = self.mainColor
            statusController.completion     = { result in
                
                switch result {
                case .success:
                    self.unlockUserWithCompletion( completion )
                    
                default:
                    self.popToRootLockerUIController( animated: true, dismissCompletion: {
                        completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: error )! ) )
                    })
                }
                
            }
            
            statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
            
            let coreError        = error as! CoreSDKError
            var options: StatusScreenOptions!
            
            if coreError.isNetworkError {
                options                            = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-network-connection-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
                options.statusDescriptionText      = LockerUI.localized( "info-connect-to-internet-and-try-again" )
                
                statusController.options           = options
                
                self.popToRootLockerUIControllerAndPushNewController(statusController)
                return true
            }
            else if ( coreError.isServerError ) {
                options                       = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-different-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
                options.statusDescriptionText = LockerUI.localized( "info-retry-later" )
                statusController.options      = options
                
                self.popToRootLockerUIControllerAndPushNewController(statusController)
                return true
            }
        }
        
        return false
    }
    
    //MARK: - Unlock
    //--------------------------------------------------------------------------
    func unlockUserWithCompletion( _ completion : @escaping UIUnlockCompletion )
    {
        self.unlockUser( animated: true, completion: completion )
    }
    
    //--------------------------------------------------------------------------
    func unlockUser( animated: Bool, completion : @escaping UIUnlockCompletion )
    {
        let status   = self.locker.status
        let lockType = status.lockType
        
        //TODO: Debug only
        //let lockType = LockType.GestureLock
        
        do {
            try self.checkLockType(lockType)
        }
        catch let error {
            if error is LockerError, (error as! LockerError).kind == .wrongLockType {
                clog(LockerUI.ModuleName, activityName: LockerUIActivities.UnlockUser.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.error, format: "LockType: \(lockType), error: \(error.localizedDescription) User will be unregistered." )
                self.unregisterUserWithCompletion(completion)
                return
            }
            else {
                assert(false, "An unexpected error \(error.localizedDescription)")
            }
        }
        
        self.remainingAttempts = nil
        
        if let passwordController = self.passwordControllerWithLockType( lockType) {
            
            passwordController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
            passwordController.dialogType = PasswordDialogType.inputPasswordOnly
            passwordController.step = 0
            passwordController.passwordLength = Int( self.passwordLengthWithLockType( lockType))
            passwordController.remainingAttempts = self.remainingAttempts
            passwordController.backgroundTint = self.mainColor
            passwordController.completion = { result in
                
                let passwordInput = result
                switch passwordInput {
                    
                case .success( let password ):
                    self.showWaitViewWithMessage( "info-moment", detailMessage: "info-unlock-in-progress" )
                    self.locker.unlockUserWithPassword( password as? String, completion: { ( result: CoreResult<Bool>, remainingAttempts: Int?  ) in
                        
                        switch result {
                        case .success:
                            self.remainingAttempts = nil
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( LockerUIDialogBoolResult.success( true ) )
                            })
                            
                        case .failure( let error ):
                            if ( error is CoreSDKError ) {
                                if ( ( error as! CoreSDKError ).kind == .operationCancelled ) {
                                    completion( LockerUIDialogBoolResult.cancel)
                                    return
                                }
                            }
                            
                            if let attemptsLeft = remainingAttempts {
                                self.remainingAttempts = attemptsLeft
                                if attemptsLeft > 0 {
                                    DispatchQueue.main.async {
                                        self.dismissWaitViewAnimated(true, dismissWaitCompletion: {
                                            passwordController.remainingAttempts = attemptsLeft
                                            passwordController.refreshPasswordDialog()
                                        })
                                    }
                                }
                                else {
                                    self.locker.unregisterUserWithCompletion( { result in
                                        self.showStatusScreenWithLoginFailureAndUnregistrationInfoWithError( error, completion: completion )
                                    })
                                }
                            }
                            else {
                                self.remainingAttempts = nil
                                if error.code == HttpStatusCodeNotAuthenticated {
                                    self.showStatusScreenWithLoginFailureAndUnregistrationInfoWithError( error, completion: completion )
                                }
                                else {
                                    self.showStatusScreenWithLoginFailureInfoWithError( error, completion: { result in
                                        switch ( result ) {
                                        case .success(_):
                                            self.unlockUserWithCompletion( completion )
                                        default:
                                            completion( result )
                                        }
                                    })
                                }
                            }
                        }
                    })
                    
                case .backward:
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( LockerUIDialogBoolResult.backward )
                    })
                    
                case .cancel:
                    self.popToRootLockerUIController( animated: true, dismissCompletion: {
                        completion( LockerUIDialogBoolResult.cancel )
                    })
                    
                case .failure( let nestedError ):
                    switch nestedError.code {
                    case LockerErrorKind.touchIDNotAvailable.rawValue:
                        self.unregisterUserWithCompletion({ result in
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: nestedError )! ))
                            })
                        })
                    case LockerErrorKind.loginCanceled.rawValue:
                        if ( lockType == .biometricLock ) {
                            self.showStatusScreenWithNewLoginAttemptOrNewRegistrationWithCompletion( completion )
                        }
                        else {
                            self.popToRootLockerUIControllerWithCompletion({
                                completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: nestedError )! ) )
                            })
                        }
                        
                    default:
                        self.popToRootLockerUIControllerWithCompletion({
                            completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: nestedError )! ) )
                        })
                    }
                }
            }

            self.pushLockerUIController( passwordController, animated: animated )
            
        }
        else {   // In case of LockType.NoAuth ...
            
            self.showWaitViewWithMessage( "info-moment", detailMessage: "info-unlock-in-progress" )
            self.locker.unlockUserWithPassword( nil, completion: { ( result: CoreResult<Bool>, remainingAttempts: Int?  ) in
                
                switch result {
                case .success:
                    self.remainingAttempts = nil
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( LockerUIDialogBoolResult.success( true ) )
                    })
                    
                case .failure( let error ):
                    if error.code == CoreSDKErrorKind.operationCancelled.rawValue {
                        completion( LockerUIDialogBoolResult.cancel)
                        return
                    }
                    
                    if let attemptsLeft = remainingAttempts {
                        self.remainingAttempts = attemptsLeft
                        if attemptsLeft > 0 {
                            DispatchQueue.main.async {
                                self.dismissWaitViewAnimated(true, dismissWaitCompletion: {
                                    self.unlockUserWithCompletion( completion )
                                })
                            }
                        }
                        else {
                            self.locker.unregisterUserWithCompletion( { result in
                                self.showStatusScreenWithLoginFailureAndUnregistrationInfoWithError( error, completion: completion )
                            })
                        }
                    }
                    else {
                        self.remainingAttempts = nil
                        if !self.handlePossibleUnlockNetworkError( error, completion: completion) {
                            if error.code == HttpStatusCodeNotAuthenticated {
                                self.showStatusScreenWithLoginFailureAndUnregistrationInfoWithError( error, completion: completion )
                            } else {
                                self.showStatusScreenWithLoginFailureInfoWithError( error, completion: completion )
                            }
                        }
                    }
                }
            })
        }
    }
    
    //--------------------------------------------------------------------------
    func showStatusScreenWithLoginFailureAndUnregistrationInfoWithError( _ error: NSError, completion : @escaping UIUnlockCompletion )
    {
        var options = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-user-login-failed" ), actionCaption: LockerUI.localized( "btn-register" ) )
        
        let statusController = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        if let appName = self.lockerUIOptions.appName {
            options.appName = appName
        }
        options.statusDescriptionText = LockerUI.localized( "info-user-login-failed-description" )
        statusController.options = options
        statusController.backgroundTint = self.mainColor
        
        statusController.completion = { result in
            switch result {
            case .success:
                self.popToRootLockerUIController( animated: true, dismissCompletion: {
                    self.showWaitView()
                    self.registerUserWithCompletion({(result: CoreResult<Bool>) in
                        switch result {
                        case .success(_):
                            completion( LockerUIDialogBoolResult.success(true))
                        case .failure(let error):
                            completion( LockerUIDialogBoolResult.failure(error))
                        }
                    })
                })
                
            default:
                self.popToRootLockerUIControllerWithCompletion( {
                    completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: error )! ) )
                })
            }
        }
        self.pushLockerUIController( statusController )
    }
    
    //--------------------------------------------------------------------------
    func showStatusScreenWithLoginFailureInfoWithError( _ error: NSError, completion : @escaping UIUnlockCompletion )
    {
        var options: StatusScreenOptions!
        let coreError: CoreSDKError = ( ( error is CoreSDKError ) ? error as! CoreSDKError : CoreSDKError.errorWithCode(error.code, underlyingError: error)! )
        let statusController        = self.viewControllerWithName( LockerUI.StatusSceneName ) as! StatusViewController
        
        if ( coreError.isNetworkError ) {
            // Problem with connection to internet.
            options                       = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-network-connection-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
            options.statusDescriptionText = LockerUI.localized( "info-connect-to-internet-and-try-again" )
        }
        else if ( coreError.isServerError || coreError.code == HttpStatusCodeNotFound ) {
            // Http error 5xx
            options                       = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-different-error" ), actionCaption: LockerUI.localized( "btn-repeat" ) )
            options.statusDescriptionText = LockerUI.localized( "info-retry-later" )
        }
        else {
            options = StatusScreenOptions( iconName: "lock-broken", mainText: LockerUI.localized( "info-user-login-failed" ), actionCaption: LockerUI.localized( "btn-unlock" ) )
            options.statusDescriptionText = error.localizedDescription
        }
        
        if let appName = self.lockerUIOptions.appName {
            options.appName = appName
        }
        
        statusController.options = options
        statusController.lockerViewOptions = self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue
        statusController.backgroundTint = self.mainColor
        
        statusController.completion = { result in
            switch result {
            case .success:
                completion( LockerUIDialogBoolResult.success(true) )
                
            default:
                self.popToRootLockerUIControllerWithCompletion( {
                    completion( LockerUIDialogBoolResult.failure( CoreSDKError.errorWithCode(LockerErrorKind.loginFailed.rawValue, underlyingError: error )! ) )
                })
            }
        }
        self.pushLockerUIController( statusController )
    }
    
    //--------------------------------------------------------------------------
    func showStatusScreenWithNewLoginAttemptOrNewRegistrationWithCompletion( _ completion : @escaping UIUnlockCompletion )
    {
        let repeatOrRegisterController               = self.viewControllerWithName( LockerUI.RepeatLoginOrRegisterSceneName ) as! RepeatLoginOrRegisterViewController
        repeatOrRegisterController.lockerViewOptions = ( self.authFlowOptions.hideCancelButton ? LockerViewOptions.showNoButton.rawValue : LockerViewOptions.showCancelButton.rawValue )
        repeatOrRegisterController.backgroundTint    = self.mainColor
        
        repeatOrRegisterController.completion = { result in
            switch  result {
            case .cancel:
                if self.locker.lockStatus == .unregistered {
                    self.registerUserWithCompletion() { result in
                        switch result {
                        case .success(_):
                            completion( LockerUIDialogBoolResult.success(true))
                        case .failure(_):
                            completion( LockerUIDialogBoolResult.cancel )
                        }
                    }
                }
                else {
                    self.popToRootLockerUIControllerWithCompletion({
                        completion( LockerUIDialogBoolResult.cancel )
                    })
                }
                
            default:
                self.unlockUserWithCompletion({ result in
                    completion( result )
                })
            }
        }
        repeatOrRegisterController.secondCompletion = {_ in
            self.registerUserWithCompletion( { status in
                clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationFinished.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.debug, format: "New registration finished with status \(status)." )
                switch ( status ) {
                case .success(_):
                    completion( LockerUIDialogBoolResult.success(true))
                case .failure(let error):
                    completion( LockerUIDialogBoolResult.failure(error))
                }
            })
        }
        
        self.popToRootLockerUIControllerAndPushNewController( repeatOrRegisterController )
    }
    
    // MARK: - Other methods
    //--------------------------------------------------------------------------
    public func injectTestingJSForRegistration(javaScript: String?)
    {
        if let script = javaScript {
            var urlPath: String = ""
            if let url = self.locker.registrationURL() {
                urlPath = url.absoluteString
                for whiteUrlPath in self.testingJSUrlWhitelist {
                    if ( urlPath.contains(whiteUrlPath)) {
                        self.testingJSForRegistration = script
                        return
                    }
                }
            }
            assert(false, "Injecting of testing JavaScript for registration URL \(urlPath) not allowed!")
        }
        else {
            self.testingJSForRegistration = nil
        }
    }
}
