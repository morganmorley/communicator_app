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
    var userID: String?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        userID = FIRAuth.auth()?.currentUser?.uid
        
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("user_details").child(userID!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.nameLabel.text = username
                self.emailLabel.text = email
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        // search user's linked events:
        ref?.child("events").child("current").observeSingleEvent(of: .value, with: { (snapshot) in
            if let eventsDetails = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                for (eventID, postData) in eventsDetails {
                    if (postData["details"]?["admin"] ?? "") == self.userID {
                        self.ref?.child("events").child("current").child(eventID).removeValue()
                    } else {
                        if (postData["linked_users"]?[self.userID!] ?? "") != nil {
                            self.ref?.child("events").child("current").child(eventID).child("linked_users").child(self.userID!).removeValue()
                        }
                    }
                }
            }
            self.ref?.child("groups").child("current").observeSingleEvent(of: .value, with: { (snapshot) in
                if let groupsDetails = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (groupID, postData) in groupsDetails {
                        if (postData["details"]?["admin"] ?? "") == self.userID {
                            self.ref?.child("events").child("current").child(groupID).removeValue()
                        } else {
                            if (postData["linked_users"]?[self.userID!] ?? "") != nil {
                                self.ref?.child("groups").child("current").child(groupID).child("linked_users").child(self.userID!).removeValue()
                            }
                        }
                    }
                }
                // remove the user from the database
                self.ref?.child("user_details").child(self.userID!).removeValue { (error, ref) in
                    if error != nil {
                        print("error \(String(describing: error))")
                    }
                    FIRAuth.auth()?.currentUser?.delete { error in
                        if error != nil {
                            // An error happened.
                        } else {
                            // Account deleted.
                        }
                    }
                    // go to login page
                    self.performSegue(withIdentifier: "goToLogin", sender: self)
                    
                }
            })
            
        })
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
    
}
