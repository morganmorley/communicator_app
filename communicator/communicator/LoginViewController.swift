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
import FirebaseDatabase

class LoginViewController: UIViewController {
    
    var ref: FIRDatabaseReference?
    
    // outlets that change depending upon login or create account is active
    @IBOutlet weak var loginButton: UIButton!

    // outlets that stay the same
    @IBOutlet weak var loginSelector: UISegmentedControl!
    
    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    // boolean storing whether the login view is currently active
    var isLogin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        setView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            confirmTextField.isHidden = true
        } else {
            loginButton.setTitle("Sign Up", for: .normal)
            confirmTextField.isHidden = false
        }
    }

    // logs into or registers user with Firebase
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let pass = passwordTextField.text else { print("login failed"); return }
        
        func completeSignIn(user : FIRUser?, error : Error?) {
            guard user != nil else { print("an error occured \(String(describing: error))"); return }
            if isLogin == false {
                let userID = FIRAuth.auth()?.currentUser?.uid
                let emailArr = email.components(separatedBy: "@")
                let username = emailArr[0]
                let userData = ["email": email, "username": username]
                ref?.child("user_details").child(userID!).child("details").setValue(userData)
            }
            self.performSegue(withIdentifier: "goToShelf", sender: self)
        }
        
        // check if login or create account view is active
        if isLogin {
            // sign in with Firebase
            FIRAuth.auth()?.signIn(withEmail: email, password: pass, completion: completeSignIn)
        } else {
            guard let confirmation = confirmTextField.text else { print("confirm password error"); return }
            if (email.components(separatedBy: "@")[1] != "bennington.edu")
                || (pass.characters.count > 16)
                || (email.characters.count > 254) {
                print("form invalid error")
                return
            }
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
        confirmTextField.resignFirstResponder()
    }
}

