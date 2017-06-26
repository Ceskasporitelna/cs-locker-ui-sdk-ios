//
//  Locker+UI.swift
//  CoreSDKTestApp
//
//  Created by Vladimír Nevyhoštěný on 12.11.15.
//  Copyright © 2015 Applifting. All rights reserved.
//

import Foundation
import CSCoreSDK


extension LockerUI
{
    
    func viewControllerWithName( _ name: String ) -> LockerViewController?
    {
        let viewController: ( () -> LockerViewController? ) = {
            let lockerBundle = LockerUI.getBundle()
            let lockerStoryboard: UIStoryboard? = UIStoryboard.init(name: LockerUI.StoryboardName, bundle:lockerBundle )
            if let scene = lockerStoryboard?.instantiateViewController( withIdentifier: name ) {
                if scene.isKind(of: LockerViewController.self ) {
                    return ( scene as? LockerViewController )
                }
            }
            
            return nil
        }
        
        var result: LockerViewController?
        
        if Thread.isMainThread {
            result = viewController()
        }
        else {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async(execute: {
                result = viewController()
                semaphore.signal()
            })
            _ = semaphore.wait(timeout: DispatchTime.distantFuture )
        }
        
        return result
    }
    
    //--------------------------------------------------------------------------
    func checkLockType(_ lockType: LockType) throws
    {
        for lockInfo in self.lockerUIOptions.allowedLockTypes {
            if lockInfo.lockType == lockType {
                return
            }
        }
        
        throw LockerError.init(kind: .wrongLockType)
    }
    
    //--------------------------------------------------------------------------
    func passwordControllerWithLockType( _ lockType: LockType ) -> LockerPasswordViewController?
    {
        switch lockType {
        case .pinLock:
            return self.viewControllerWithName( LockerUI.PinInputSceneName ) as! PinViewController
        case .fingerprintLock:
            return self.viewControllerWithName( LockerUI.FingerprintInputSceneName ) as! FingerprintViewController
        case .gestureLock:
            return self.viewControllerWithName( LockerUI.GestureInputSceneName ) as! GestureViewController
        case .noLock:
            return nil
        }
    }
    
    func showWaitView()
    {
        self.showWaitViewWithMessage( nil, detailMessage: nil )
    }
    
    func showWaitViewWithMessage( _ message: String?, detailMessage: String? )
    {
        DispatchQueue.main.async(execute: {
            if self.lockerWaitWindow == nil {
                self.waitController = self.viewControllerWithName( LockerUI.WaitSceneName ) as? WaitViewController
                
                self.waitController?.message = message != nil ? LockerUI.localized( message! ) : nil
                self.waitController?.messageDetail = detailMessage != nil ? LockerUI.localized( detailMessage! ) : nil
                self.waitController?.navBarColor = self.lockerUIOptions.navBarColor.color
                
                self.lockerWaitWindow = UIWindow( frame: UIScreen.main.bounds )
                self.lockerWaitWindow?.rootViewController = self.waitController
                self.lockerWaitWindow?.makeKeyAndVisible()
                self.lockerWaitWindow?.windowLevel = 1.2
                self.lockerWaitWindow?.alpha = 0.0
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.lockerWaitWindow?.alpha = 1.0
                })
            } else {
                self.lockerWaitWindow?.makeKeyAndVisible()
                
                self.waitController?.message = message != nil ? LockerUI.localized( message! ) : nil
                self.waitController?.messageDetail = detailMessage != nil ? LockerUI.localized( detailMessage! ) : nil
                self.waitController?.navBarColor = self.lockerUIOptions.navBarColor.color
                
                self.waitController?.view.setNeedsDisplay()
            }
        })
    }

    //--------------------------------------------------------------------------
    func pushLockerUIController( _ viewController: LockerViewController )
    {
        self.pushLockerUIController(viewController, animated: true )
    }

    //--------------------------------------------------------------------------
    func pushLockerUIController( _ viewController: LockerViewController, animated: Bool )
    {
        DispatchQueue.main.async(execute: {
            
            if  self.waitController != nil  {
                self.waitController?.dismiss( animated: false, completion: nil )
                self.waitController = nil
                
                self.lockerWaitWindow?.rootViewController = nil
                self.lockerWaitWindow?.isHidden = true
                self.lockerWaitWindow = nil
            }
            
            if self.lockerUIWindow == nil  {
                if let _ = UIApplication.shared.keyWindow?.frame {
                    self.lockerUIWindow = UIWindow( frame: UIScreen.main.bounds )
                    let rootVC = LockerNavigationController( rootViewController: viewController )
                    //rootVC.setupNavBar(self.lockerUIOptions.navBarColor)
                    rootVC.setupNavBar(options: self.lockerUIOptions)
                    
                    self.lockerUIWindow?.rootViewController = rootVC
                    self.lockerUIWindow?.isHidden = false
                    self.lockerUIWindow?.makeKeyAndVisible()
                    self.lockerUIWindow?.alpha = ( animated ? 0.0 : 1.0 )
                    self.lockerUIWindow?.windowLevel = 1.2
                    
                    if ( animated ) {
                        UIView.animate( withDuration: 0.5,
                            animations: {
                                self.lockerUIWindow?.alpha = 1.0
                            },
                            completion: { completed in
                            }
                        )
                    }
                }
            }
            else {
                let navController: LockerNavigationController = self.lockerUIWindow?.rootViewController as! LockerNavigationController
                //navController.setupNavBar(self.lockerUIOptions.navBarColor)
                navController.setupNavBar(options: self.lockerUIOptions)
                
                navController.pushViewController(viewController, animated: true )
            }
        })
    }
    
    func popLockerUIController()
    {
        DispatchQueue.main.async(execute: {
            
            if self.waitController != nil {
                self.waitController?.dismiss( animated: false, completion: nil )
                self.waitController = nil
                
                self.lockerWaitWindow?.rootViewController = nil
                self.lockerWaitWindow?.isHidden = true
                self.lockerWaitWindow = nil
            }
            
            if self.lockerUIWindow != nil {
                
                let navController: LockerNavigationController = self.lockerUIWindow?.rootViewController as! LockerNavigationController
                //navController.setupNavBar(self.lockerUIOptions.navBarColor)
                navController.setupNavBar(options: self.lockerUIOptions)
                
                if navController.viewControllers.count > 0 {
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        if navController.viewControllers.count == 0 {
                            self.lockerUIWindow?.rootViewController = nil
                            self.lockerUIWindow?.isHidden = true
                            self.lockerUIWindow = nil
                        }
                    })
                    navController.popViewController( animated: true )
                    CATransaction.commit()
                }
            }
        })
    }
    
    //--------------------------------------------------------------------------
    func popToRootLockerUIControllerWithCompletion( _ dismissCompletion: ( () -> Void )?)
    {
        self.popToRootLockerUIController(animated: true, dismissCompletion: dismissCompletion)
    }
    
    //--------------------------------------------------------------------------
    func dismissWaitViewAnimated( _ animated: Bool, dismissWaitCompletion: @escaping (() -> ()) )
    {
        assert( Thread.isMainThread, "Must be called on main thread only!")
        if self.waitController != nil {
            if ( animated ) {
                UIView.animate( withDuration: 0.5, animations: {
                    
                    self.lockerWaitWindow?.alpha = 0.0
                    }, completion: { completed in
                        
                        self.waitController?.dismiss( animated: false, completion: nil )
                        self.waitController = nil
                        
                        self.lockerWaitWindow?.rootViewController = nil
                        self.lockerWaitWindow?.isHidden = true
                        self.lockerWaitWindow = nil
                        
                        dismissWaitCompletion()
                })
            }
            else {
                self.waitController?.dismiss( animated: false, completion: nil )
                self.waitController = nil
                
                self.lockerWaitWindow?.rootViewController = nil
                self.lockerWaitWindow?.isHidden = true
                self.lockerWaitWindow = nil
                
                dismissWaitCompletion()
            }
        }
        else {
            dismissWaitCompletion()
        }
        
    }
    
    //--------------------------------------------------------------------------
    func popToRootLockerUIController( animated: Bool, dismissCompletion: ( () -> Void )?)
    {
        DispatchQueue.main.async(execute: {
            if self.lockerUIWindow != nil {
                if ( animated ) {
                    if ( self.waitController != nil ) {
                        self.lockerUIWindow?.rootViewController = nil
                        self.lockerUIWindow?.isHidden             = true
                        self.lockerUIWindow                     = nil
                        
                        self.dismissWaitViewAnimated(animated, dismissWaitCompletion: {
                            DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64( 0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                                dismissCompletion?()
                            })
                        })
                    }
                    else {
                        UIView.animate( withDuration: 0.5, animations: {
                            
                            self.lockerUIWindow?.alpha = 0.0
                            }, completion: { completed in
                                
                                _ = self.lockerUIWindow?.rootViewController?.navigationController?.popToRootViewController(animated: false)
                                self.lockerUIWindow?.rootViewController = nil
                                self.lockerUIWindow?.isHidden           = true
                                self.lockerUIWindow                     = nil
                                
                                dismissCompletion?()
                        })
                    }
                }
                else {
                    self.dismissWaitViewAnimated(animated, dismissWaitCompletion: {
                        _ = self.lockerUIWindow?.rootViewController?.navigationController?.popToRootViewController(animated: false)
                        self.lockerUIWindow?.rootViewController = nil
                        self.lockerUIWindow?.isHidden           = true
                        self.lockerUIWindow                     = nil
                        dismissCompletion?()
                    })
                }
            }
            else {
                self.dismissWaitViewAnimated(animated, dismissWaitCompletion: {
                    dismissCompletion?()
                })
            }

        })
    }

    
    //--------------------------------------------------------------------------
    func popToRootLockerUIControllerAndPushNewController( _ controller: LockerViewController )
    {
        DispatchQueue.main.async(execute: {
            
            if self.waitController != nil {
                self.waitController?.dismiss( animated: false, completion: nil )
                self.waitController = nil
                
                self.lockerWaitWindow?.rootViewController = nil
                self.lockerWaitWindow?.isHidden = true
                self.lockerWaitWindow = nil
            }
            
            if self.lockerUIWindow != nil {
                _ = self.lockerUIWindow?.rootViewController?.navigationController?.popToRootViewController(animated: false)
            }
            
            self.pushLockerUIController(controller)
        })
    }
    
}
