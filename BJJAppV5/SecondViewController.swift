//
//  SecondViewController.swift
//  BJJAppV5
//
//  Created by Ryan Schulte on 9/30/19.
//  Copyright © 2019 meyita. All rights reserved.
//

import UIKit
import AWSCore
import AWSS3
import AWSAuthUI
import AWSMobileClient
import AWSUserPoolsSignIn
import AWSCognitoIdentityProvider

class SecondViewController: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    
    
    @IBAction func btn_showS3Image(_ sender: Any) {
        test()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showSignIn()
        initializeAWSMobileClient()
        
    }
    
    func initializeAWSMobileClient() {
        AWSMobileClient.default().initialize { (userState, error) in
            if let userState = userState {
                switch(userState){
                case .signedIn: // is Signed IN
                    print("Logged In")
                    print("Cognito Identity Id (authenticated): \(AWSMobileClient.default().identityId))")
                case .signedOut: // is Signed OUT
                    print("Logged Out")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutUserPoolsTokenInvalid: // User Pools refresh token INVALID
                    print("User Pools refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                case .signedOutFederatedTokensInvalid: // Facebook or Google refresh token INVALID
                    print("Federated refresh token is invalid or expired.")
                    DispatchQueue.main.async {
                        self.showSignIn()
                    }
                default:
                    AWSMobileClient.default().signOut()
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func showSignIn() {
        AWSMobileClient.default()
            .showSignIn(navigationController: self.navigationController!,
                             signInUIOptions: SignInUIOptions(
                                   canCancel: false,
                                   logoImage: UIImage(named: "TXBjj"),
                                    backgroundColor: UIColor.black)) { (result, err) in
                                     DispatchQueue.main.async {
                                        print("User successfully logged in")
                                    }
        }
    }
    
    func test(){
        let transferManager = AWSS3TransferManager.default()
        let downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.png")
        
        if let downloadRequest = AWSS3TransferManagerDownloadRequest(){
            downloadRequest.bucket = "bjjappv5-envbjjfive"
            downloadRequest.key = "schdFri.png"
            downloadRequest.downloadingFileURL = downloadingFileURL
            
            transferManager.download(downloadRequest).continueWith(executor: AWSExecutor.default(), block: { (task: AWSTask<AnyObject>) -> Any? in
                    if( task.error != nil){
                        print(task.error!.localizedDescription)
                        return nil
                    }
                
                    print(task.result!)
                    
                    if let data = NSData(contentsOf: downloadingFileURL){
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.image.image = UIImage(data: data as Data)
                        })
                    }
                return nil
                })
            }
    }
    
    
}

