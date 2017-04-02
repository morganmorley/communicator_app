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
    var userRef: FIRDatabaseReference?
    var userID: String?
    var userIDForLookup: String?
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
        ref?.child("users").child(userIDForLookup!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.nameLabel.text = username
                self.emailLabel.text = email
            }
        })
        // set the logout and delete account buttons:
        userID = FIRAuth.auth()?.currentUser?.uid
        if userIDForLookup == userID! { isAccount = true }
        setView()
        
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
        let eventsRef = self.ref?.child("posts").child("events")
        // search user's linked events:
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? Dictionary<String, String>
            for (eventID, role) in value! {
                if role == "admin" {
                    // delete events user administrates
                    eventsRef?.child(eventID).removeValue { (error, ref) in
                        if error != nil {
                            print("error \(String(describing: error))")
                        }
                    }
                } else if role == "rsvp" || role == "shelf" {
                    // delete user as a member of events they do not administrate
                    eventsRef?.child(eventID).child("linked_users").child(self.userID!).removeValue { (error, ref) in
                        if error != nil {
                            print("error \(String(describing: error))")
                        }
                    }
                }
            }
        })
        // remove the user from the database
        userRef?.removeValue { (error, ref) in
            if error != nil {
                print("error \(String(describing: error))")
            }
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
