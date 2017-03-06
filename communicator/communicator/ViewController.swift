//
//  ViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/6/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var loginSelector: UISegmentedControl!

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var confirmLabel: UILabel!
    
    @IBOutlet weak var confirmTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    var isLogin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        usernameLabel.isHidden = true
        usernameTextField.isHidden = true
        confirmLabel.isHidden = true
        confirmTextField.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginSelectorChanged(_ sender: Any) {
        // Change the boolean
        isLogin = !isLogin
        
        // Check isLogin and set the button and labels
        if isLogin {
            loginButton.setTitle("Login", for: .normal)
            usernameLabel.isHidden = true
            usernameTextField.isHidden = true
            confirmLabel.isHidden = true
            confirmTextField.isHidden = true
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
            usernameLabel.isHidden = false
            usernameTextField.isHidden = false
            confirmLabel.isHidden = false
            confirmTextField.isHidden = false
        }
    }

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // TODO - Form validation on email and password
        if let email = emailTextField.text, let pass = passwordTextField.text {
            // Check isLogin to sign in or register the user with Firebase
            if isLogin {
                confirmedLogin(email: email, pass: pass)
            } else {
                if let confirmation = confirmTextField.text, let username = usernameTextField.text {
                    if pass == confirmation {
                        confirmedRegister(email: email, pass: pass, confirmation: confirmation)
                        // add username to user account
                    }
                }
            }
        }
    }
    
    func confirmedLogin(email: String, pass: String) {
        // sign in with Firebase
        FIRAuth.auth()?.signIn(withEmail: email, password: pass, completion: { (user, error) in
            //Check that user isn't nil
            if let u = user {
                // go to roster
                self.performSegue(withIdentifier: "goToRoster", sender: self)
            } else {
                // error
            }
        })
    }
    
    func confirmedRegister(email: String, pass: String, confirmation: String) {
        //sign up with Firebase
        FIRAuth.auth()?.createUser(withEmail: email, password: pass, completion: { (user, error) in
            if let u = user {
                // go to roster
                self.performSegue(withIdentifier: "goToRoster", sender: self)
            
            } else {
                // error
            }
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Dismiss the keyboard when the view is tapped on
        emailTextField.resignFirstResponder()
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }

}

