//
//  LockerNavigationController.swift
//  CSLockerUI
//
//  Created by Marty on 26/02/16.
//  Copyright © 2016 Applifting. All rights reserved.
//

import UIKit

//==============================================================================
class LockerNavigationController: UINavigationController
{
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask
    {
        return UIInterfaceOrientationMask.all
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
//        self.setupNavBar(CSNavBarColor.default)
        self.setupNavBar(backgroundColor: .default, tintColor: .default)
    }
    
    override var shouldAutorotate : Bool
    {
        return true
    }

//    func setupNavBar(_ navBarColor:CSNavBarColor)
//    {
//        self.navigationBar.barTintColor = navBarColor.color
//        self.navigationBar.isTranslucent = false
//    }
    
    //--------------------------------------------------------------------------
    func setupNavBar(options: LockerUIOptions)
    {
        self.setupNavBar(backgroundColor: options.navBarColor, tintColor: options.navBarTintColor)
    }
    
    //--------------------------------------------------------------------------
    fileprivate func setupNavBar(backgroundColor: CSNavBarColor, tintColor: CSNavBarTintColor)
    {
        self.navigationBar.barTintColor  = backgroundColor.color
        self.navigationBar.tintColor     = tintColor.color
        self.navigationBar.isTranslucent = false
    }

}
