//
//  LoginViewController.swift
//  RoseChecker
//
//  Created by Augustine's MacBook on 5/12/20.
//  Copyright © 2020 Augustine. All rights reserved.
//

import UIKit
import Rosefire
import Firebase
import GoogleSignIn
import Floaty

class LoginViewController : UIViewController{
    let showCalSegueIdentifier = "showCalenderSegue"
    let REGISTRY_TOKEN = REGISTRATION.token
    @IBOutlet weak var emailAddressTextField: UITextField!
    
    @IBOutlet weak var roseSigninButton: RoundButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: GIDSignInButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        emailAddressTextField.placeholder = "Email Address"
        emailAddressTextField.backgroundColor = .systemGray4
        emailAddressTextField.textContentType = .emailAddress
        passwordTextField.placeholder = "Password"
        passwordTextField.backgroundColor = .systemGray4
        navigationItem.title = "Photo Bucket Auth"
        let tapGesture = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tapGesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGesture)

        
        GIDSignIn.sharedInstance()?.presentingViewController = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Auth.auth().currentUser != nil {
            self.gotoListView()
        }
    }
    
    
    @IBAction func singinWithRosefire(_ sender: Any) {
        Rosefire.sharedDelegate().uiDelegate = self // This should be your view controller
        Rosefire.sharedDelegate().signIn(registryToken: REGISTRY_TOKEN) { (err, result) in
            if let err = err {
                print("Rosefire sign in error! \(err)")
                return
            }
            print("Result = \(result!.token!)")
            print("Result = \(result!.username!)")
            print("Result = \(result!.name!)")
            print("Result = \(result!.email!)")
            print("Result = \(result!.group!)")
            Auth.auth().signIn(withCustomToken: result!.token) { (authResult, error) in
                if let error = error {
                    print("Firebase sign in error! \(error)")
                    return
                }
                // User is signed in using Firebase!
                self.gotoListView()
            }
        }
    }
    
    @IBAction func signupNew(_ sender: Any) {
        guard let email = emailAddressTextField.text else { return }
        guard let password = passwordTextField.text else {return}
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error create new user \(error)")
                return
            }
            print("New user is created and signed in")
            self.gotoListView()
        }
    }
    
    @IBAction func loginExisting(_ sender: Any) {
        guard let email = emailAddressTextField.text else { return }
        guard let password = passwordTextField.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error create new user \(error)")
                return
            }
            print("New user is created and signed in")
            self.gotoListView()
        }
    }
    
    func gotoListView(){
        performSegue(withIdentifier: showCalSegueIdentifier, sender: self)
    }

}

