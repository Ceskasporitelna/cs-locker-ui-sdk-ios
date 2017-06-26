//
//  WebViewController.swift
//  CSLockerUI
//
//  Created by Marty on 18/01/16.
//  Copyright © 2016 Applifting. All rights reserved.
//

import Foundation
import WebKit
import UIKit
import CSCoreSDK


class WebViewController: LockerViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webBaseView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    var theWebView:WKWebView
    
    var requestURL:URL!
    var lockerRedirectUrlPath:String!
    var testingJSForRegistration: String?
    var isTestingJSCodeInjected = false
    
    override var shouldShowTitleLogo: Bool {
        switch (LockerUI.internalSharedInstance.lockerUIOptions.showLogo) {
        case .always:
            return true
        case .exceptRegistration, .never:
            return false
        }
    }
    
    fileprivate struct Constants
    {
        static let estimatedProgress = "estimatedProgress"
    }
    
    required init(coder aDecoder: NSCoder)
    {
        self.theWebView = WKWebView(frame: CGRect.zero)
        super.init(coder: aDecoder)
        self.theWebView.navigationDelegate = self
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.webBaseView.addSubview(self.theWebView)
        self.theWebView.translatesAutoresizingMaskIntoConstraints = false
        
        let top = NSLayoutConstraint(item: self.theWebView,
                                     attribute: .top, relatedBy: .equal,
                                     toItem: self.topLayoutGuide, attribute: .bottom,
                                     multiplier: 1, constant: 0)
        
        let bottom = NSLayoutConstraint(item: self.theWebView,
                                        attribute: .bottom, relatedBy: .equal,
                                        toItem: self.bottomLayoutGuide, attribute: .bottom,
                                        multiplier: 1, constant: 0)
        
        let width = NSLayoutConstraint(item: self.theWebView,
                                       attribute: .width, relatedBy: .equal,
                                       toItem: view, attribute: .width,
                                       multiplier: 1, constant: 0)
        
        view.addConstraints([top,bottom, width])
        
        self.makeUrlRequest()
        
        if self.lockerViewOptions == LockerViewOptions.showNoButton.rawValue {
            let reloadButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action:#selector(WebViewController.makeUrlRequest))
            reloadButton.tintColor = LockerUI.internalSharedInstance.mainColor
            self.navigationItem.rightBarButtonItem = reloadButton
        }
        
        // To support accessibility ...
        self.view.accessibilityTraits    = UIAccessibilityTraitAllowsDirectInteraction
        
        self.overlayView.backgroundColor = LockerUI.internalSharedInstance.mainColor
        self.activityIndicator.color     = LockerUI.internalSharedInstance.mainColor.maxBright()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.updateConstraintsWithScreenSize()
        self.theWebView.addObserver(self, forKeyPath: Constants.estimatedProgress, options: .new, context: nil)
        self.theWebView.becomeFirstResponder()
    }
    
    //--------------------------------------------------------------------------
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        self.activityIndicator.bringSubview(toFront: self.theWebView)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.theWebView.removeObserver(self, forKeyPath: Constants.estimatedProgress)
        if self.activityIndicator != nil && self.activityIndicator.isAnimating {
            self.stopAnimating()
        }
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
        if ( self.shouldShowTitleLogo ) {
            if ( UIDevice.current.isLandscape && UIDevice.current.isPhone ) {
                self.navigationItem.titleView                = UIImageView(image: self.imageNamed("logo-csas-landscape") )
            }
            else {
                self.navigationItem.titleView                = UIImageView(image: self.imageNamed("logo-csas") )
            }
        }
    }
    

    
    func makeUrlRequest()
    {
//        if let testingJS = self.testingJSForRegistration {
//            let wkScript = WKUserScript(source: testingJS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
//            self.theWebView.configuration.userContentController.addUserScript(wkScript)
//        }
        self.activityIndicator.startAnimating()

        let request = URLRequest(url: requestURL)
        self.theWebView.load(request)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if keyPath == Constants.estimatedProgress {
            if self.theWebView.estimatedProgress == 1 {
                //self.activityIndicator.stopAnimating()
            }
        }
    }
    
    //--------------------------------------------------------------------------
    func stopAnimating()
    {
        self.activityIndicator.stopAnimating()
        UIView.animate(withDuration: 0.5,
                       animations: { self.overlayView.alpha = 0.2 },
                       completion: { _ in
            self.overlayView.removeFromSuperview()
        })
    }
    
}

extension WebViewController: WKNavigationDelegate{
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        
        if CoreSDK.sharedInstance.environment.allowUntrustedCertificates{
            if challenge.protectionSpace.serverTrust != nil {
                let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, cred)
            }else{
                completionHandler(.performDefaultHandling, nil)
            }
        }else{
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        if let url = navigationAction.request.url{
            if url.absoluteString.hasPrefix(self.lockerRedirectUrlPath){
                let locker = CoreSDK.sharedInstance.locker as! Locker
                _ = locker.continueWithUserRegistrationUsingOAuth2Url(url)
                decisionHandler(.cancel)
                return
            }else if navigationAction.targetFrame == nil {
                if UIApplication.shared.canOpenURL(url){
                    UIApplication.shared.openURL(url)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    
    //--------------------------------------------------------------------------
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
    {
        if let response = navigationResponse.response as? HTTPURLResponse {
            let coreError = CoreSDKError.errorWithCode(response.statusCode)!
            if ( coreError.isServerError || coreError.code == HttpStatusCodeNotFound ) {
                self.completion?( LockerUIDialogResult.failure(CoreSDKError.errorWithCode(response.statusCode)!))
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    //--------------------------------------------------------------------------
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        self.stopAnimating()
    }
    
    //--------------------------------------------------------------------------
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        self.stopAnimating()
        
        if let testingJS = self.testingJSForRegistration {//, !self.isTestingJSCodeInjected {
            self.isTestingJSCodeInjected = true
            clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationStarted.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.debug, format: "Testing registration JS will be execuded: \(testingJS)" )
            webView.evaluateJavaScript(testingJS, completionHandler: { value, error in
                if let err = error {
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationStarted.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.error, format: "Testing registration JS execuded with error: \(err)" )
                }
                else {
                    clog(LockerUI.ModuleName, activityName: LockerUIActivities.UserRegistrationStarted.rawValue, fileName: #file, functionName: #function, lineNumber: #line, logLevel: LogLevel.debug, format: "Testing registration JS execuded with result: \(value ?? "")" )
                }
            })
        }
    }
}

