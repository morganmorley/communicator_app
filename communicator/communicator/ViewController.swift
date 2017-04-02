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

class ViewController: UIViewController {
    
    var ref: FIRDatabaseReference?
    
    // Outlets that change depending upon login or create account is active
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var confirmLabel: UILabel!
    @IBOutlet weak var confirmTextField: UITextField!

    // outlets that stay the same
    @IBOutlet weak var loginSelector: UISegmentedControl!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // boolean storing whether the login view is currently active
    var isLogin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setView()
        ref = FIRDatabase.database().reference()

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
            guard user != nil else { print("an error occured \(String(describing: error))"); return }
            if isLogin == false {
                let userID = FIRAuth.auth()?.currentUser?.uid
                let emailArr = email.components(separatedBy: "@")
                let username = emailArr[0]
                let userData = ["email": email, "username": username]
                ref?.child("users").child(userID!).child("details").setValue(userData)
            }
            self.performSegue(withIdentifier: "goToStream", sender: self)
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

