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
        setView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // switches between login and create account views and buttons
    @IBAction func loginSelectorChanged(_ sender: Any) {
        // change the boolean
        isLogin = !isLogin
        setView()
    }
    
    // checks isLogin and set the button and password confirmation prompts
    func setView() {
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
        
        guard let email = emailTextField.text, let pass = passwordTextField.text else { print("login failed"); return }
        func completeSignIn(user : FIRUser?, error : Error?) {
            guard user != nil else { print("an error occured \(error)"); return }
            self.performSegue(withIdentifier: "goToRoster", sender: self)
        }
        
        // check if login or create account view is active
        if isLogin {
            // sign in with Firebase
            FIRAuth.auth()?.signIn(withEmail: email, password: pass, completion: completeSignIn)
        } else {
            guard let confirmation = confirmTextField.text else { print("confirm password"); return }
            if pass == confirmation {
                //register with Firebase
                FIRAuth.auth()?.createUser(withEmail: email, password: pass, completion: completeSignIn)
            } else {
                print("password and password confirmation do not match")
            }
        }
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }

}

