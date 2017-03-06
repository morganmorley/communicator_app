//
//  ViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/6/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//
//  sources:
//      Firebase Tutorials for iOS Apps Playlist by CodeWithChris (Youtube.com)

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    // button to toggle between login and create account views
    @IBOutlet weak var loginSelector: UISegmentedControl!

    // email address
    @IBOutlet weak var emailTextField: UITextField!
    
    // password confirmation label for hiding on login view
    @IBOutlet weak var confirmLabel: UILabel!
    
    // password
    @IBOutlet weak var passwordTextField: UITextField!
    
    // password confirmation
    @IBOutlet weak var confirmTextField: UITextField!
    
    // button to login or sign up
    @IBOutlet weak var loginButton: UIButton!
    
    // boolean storing whether the login view is currently active
    var isLogin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        confirmLabel.isHidden = true
        confirmTextField.isHidden = true
        print("welcome")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // switches between login and create account views and buttons
    @IBAction func loginSelectorChanged(_ sender: Any) {
        // change the boolean
        isLogin = !isLogin
        
        // check isLogin and set the button and password confirmation prompts
        if isLogin {
            loginButton.setTitle("Login", for: .normal)
            confirmLabel.isHidden = true
            confirmTextField.isHidden = true
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
            confirmLabel.isHidden = false
            confirmTextField.isHidden = false
        }
    }

    // logs into or registers user with Firebase
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // TODO - Form validation on email and password - separate function
        if let email = emailTextField.text, let pass = passwordTextField.text {
            // check if login or create account view is active
            if isLogin {
                // sign in with Firebase
                FIRAuth.auth()?.signIn(withEmail: email, password: pass, completion: { (user, error) in
                    //Check that user isn't nil
                    if let u = user {
                        // go to roster
                        self.performSegue(withIdentifier: "goToRoster", sender: self)
                    } else {
                        print("an error occured \(error)")
                    }
                })
            } else {
                if let confirmation = confirmTextField.text {
                    if pass == confirmation {
                        //sign up with Firebase
                        FIRAuth.auth()?.createUser(withEmail: email, password: pass, completion: { (user, error) in
                            if let u = user {
                                // go to roster
                                self.performSegue(withIdentifier: "goToRoster", sender: self)
                            } else {
                                print("an error occured: \(error)")
                            }
                        })
                    }
                }
            }
            return
        }
        print("login failed")
    }
    
    // Dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }

}

