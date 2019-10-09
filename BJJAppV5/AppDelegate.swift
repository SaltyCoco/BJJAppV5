//
//  AppDelegate.swift
//  BJJAppV5
//
//  Created by Ryan Schulte on 9/30/19.
//  Copyright © 2019 meyita. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var isInitialized = false
    //let identityId = AWSMobileClient.default().getIdentityId()
    let identityId = "us-west-2:1f3e128e-5462-40d5-b25b-ba7a22b143dd"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let didFinishLaunching = AWSSignInManager.sharedInstance().interceptApplication(application, didFinishLaunchingWithOptions: launchOptions)
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USWest2, identityPoolId: identityId)
        let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialsProvider)
        AWSServiceManager.default()?.defaultServiceConfiguration = configuration
        
        if(!isInitialized){
            AWSSignInManager.sharedInstance().resumeSession(completionHandler: {
                (result: Any?, error: Error?) in
                print("Result: \(result) \n Error:\(error)")
                }
            )
            isInitialized = true
        }
        return didFinishLaunching
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

