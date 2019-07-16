//
//  AppDelegate.swift
//  Example
//
//  Created by Nobuhiro Ito on 7/10/19.
//  Copyright © 2019 Nobuhiro Ito. All rights reserved.
//

import UIKit
import SimpleTwitterAuthentication

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let auth = TwitterAuthentication(consumerKey: "<<<WRITE YOUR CONSUMER KEY>>>",
                                     consumerSecret: "<<<WRITE YOUR CONSUMER SECRET>>>",
                                     callbackScheme: "<<<WRITE YOUR CALLBACK SCHEME>>>")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if auth?.handleOpen(url, options: options) ?? false { return true }
        return true
    }
}

