//
//  ProfileViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/13/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController {

    var ref: FIRDatabaseReference?
    var userForLookup: String?
    var isAccount: Bool = false

    
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? Dictionary<String, Dictionary<String, Any>>
            let currentUser = FIRAuth.auth()?.currentUser?.uid
            for (user, details) in (value)! {
                let username = details["username"] as? String ?? ""
                if username == self.userForLookup {
                    if user == currentUser { self.isAccount = true }
                    let email = details["email"] as? String ?? ""
                    self.nameLabel.text = username
                    self.emailLabel.text = email
                }
            }
            // set the logout and delete account buttons:
            self.setView()
        })
    }
    
    // checks isAccount and sets the logout and delete account buttons
    func setView() {
        if isAccount {
            logoutButton.isHidden = false
            deleteButton.isHidden = false
        } else {
            logoutButton.isHidden = true
            deleteButton.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        let user = FIRAuth.auth()?.currentUser
        
        if let userID = user?.uid {
            let userRef = self.ref?.child("users").child(userID)
            let eventsRef = self.ref?.child("posts").child("events")
            // search user's linked events
            userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
                let value = snapshot.value as? Dictionary<String, String>
                for (eventID, role) in value! {
                    if role == "admin" {
                        // delete events user administrates
                        eventsRef?.child(eventID).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(error)")
                            }
                        }
                    } else if role == "member" {
                        // delete user as a member of events they do not administrate
                        eventsRef?.child(eventID).child("linked_users").child(userID).removeValue { (error, ref) in
                            if error != nil {
                                print("error \(error)")
                            }
                        }
                    }
                }
            })
            // remove the user from the database
            userRef?.removeValue { (error, ref) in
                if error != nil {
                    print("error \(error)")
                }
            }
        }
        
        user?.delete { error in
            if error != nil {
                // An error happened.
            } else {
                // Account deleted.
            }
        }
        // go to login page
        self.performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    @IBAction func logoutButtonTapped(_ sender: Any) {
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logOutError {
            print("Error Logging User Out - \(logOutError)")
        }
        // go to login page
        self.performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
