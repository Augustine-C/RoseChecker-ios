//
//  AppDelegate.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/10/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    var credential:AuthCredential!

    var restrictRotation: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
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

    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        if UIDevice.current.userInterfaceIdiom == .pad{
            return .all
        }
        return self.restrictRotation
    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        print(url)
        return true
    }

        func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
           -> Bool {
            print("HERE")
            if(url.isFileURL){
                do {
                    print("HERE")
                    let str = try String(contentsOf: url, encoding: .utf8)
                    print(str)
        //                    var events = try CalParser.parse(str)
        //                    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        //                    print(events[0])
                } catch let error {
                    print(error)
                    return false
                }
                return true
            }else{
                print("HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                return GIDSignIn.sharedInstance().handle(url)
            }
        }
       
       func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
           // ...
           if let error = error {
               print("there's an error with google signin \(error)")
               return
           }
           
           guard let authentication = user.authentication else { return }
           credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                      accessToken: authentication.accessToken)
           let loginVC = GIDSignIn.sharedInstance()?.presentingViewController as! LoginViewController
           Auth.auth().signIn(with: credential) { (authResult, error) in
               if let error = error {
                   let authError = error as NSError
                   if (authError.code == AuthErrorCode.secondFactorRequired.rawValue) {
                       // The user is a multi-factor user. Second factor challenge is required.
                       let resolver = authError.userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
                       var displayNameString = ""
                       for tmpFactorInfo in (resolver.hints) {
                           displayNameString += tmpFactorInfo.displayName ?? ""
                           displayNameString += " "
                       }
                       loginVC.showTextInputPrompt(withMessage: "Select factor to sign in\n\(displayNameString)", completionBlock: { userPressedOK, displayName in
                           var selectedHint: PhoneMultiFactorInfo?
                           for tmpFactorInfo in resolver.hints {
                               if (displayName == tmpFactorInfo.displayName) {
                                   selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
                               }
                           }
                           PhoneAuthProvider.provider().verifyPhoneNumber(with: selectedHint!, uiDelegate: nil, multiFactorSession: resolver.session) { verificationID, error in
                               if error != nil {
                                   print("Multi factor start sign in failed. Error: \(error.debugDescription)")
                               } else {
                                   loginVC.showTextInputPrompt(withMessage: "Verification code for \(selectedHint?.displayName ?? "")", completionBlock: { userPressedOK, verificationCode in
                                       let credential: PhoneAuthCredential? = PhoneAuthProvider.provider().credential(withVerificationID: verificationID!, verificationCode: verificationCode!)
                                       let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator.assertion(with: credential!)
                                       resolver.resolveSignIn(with: assertion!) { authResult, error in
                                           if error != nil {
                                               print("Multi factor finanlize sign in failed. Error: \(error.debugDescription)")
                                           } else {
                                               loginVC.navigationController?.popViewController(animated: true)
                                           }
                                       }
                                   })
                               }
                           }
                       })
                   } else {
                       loginVC.showMessagePrompt(error.localizedDescription)
                       return
                   }
                   // ...
                   return
               }
               // User is signed in
               // ...
               loginVC.gotoListView()
               
           }
           
           // ...
       }
       
       func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
           // Perform any operations when the user disconnects from app here.
           // ...
       }
}

