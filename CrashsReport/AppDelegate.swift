//
//  AppDelegate.swift
//  CrashsReport
//
//  Created by 田子瑶 on 2017/6/30.
//  Copyright © 2017年 田子瑶. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        UncaughtExceptionHandler.installUncaughtExceptionHandler(true, showAlert: true)
        
        #if RELEASE
            UncaughtExceptionHandler.uploadCrashLog()
        #endif
        return true
    }
}

