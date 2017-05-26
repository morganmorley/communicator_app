//
//  MemberProfileViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 5/24/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MemberProfileViewController: UIViewController {

    var ref: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    var userIDForLookup: String?
    var groupIDForLookup: String?
    
    @IBOutlet weak var usernameTextView: UILabel!
    @IBOutlet weak var postsTextView: UITextView!
    @IBOutlet weak var emailTextView: UILabel!
    @IBOutlet weak var groupRoleTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().reference()
        
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("users").child(userIDForLookup!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.usernameTextView.text = username
                self.emailTextView.text = email
            }
            //Add in promoted posts
            self.ref?.child("user_profiles").child("possible").observeSingleEvent(of: .value, with: { (snapshot) in
                if let posts = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (year, promoted) in posts {
                        self.postsTextView.text = self.postsTextView.text + "\n" + year + "\n"
                        for (_, post) in promoted {
                            self.postsTextView.text = self.postsTextView.text + post["role"]! + " in "
                            self.postsTextView.text = self.postsTextView.text + post["name"]! + "\n"
                        }
                    }
                }
            })
            
        })
        
    }
    
    @IBAction func saveRole(_ sender: Any) {
        if let groupID = groupIDForLookup, let userID = userIDForLookup {
            ref?.child("groups").child("drafts").child(groupID).child(userID).setValue(groupRoleTextView.text ?? "")
            //Dismiss the popover
            self.performSegue(withIdentifier: "goToEditEvent", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // dismiss the keyboard when the view is tapped on
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        groupRoleTextView.resignFirstResponder()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditGroup" {
            if let editGroupViewController = segue.destination as? EditGroupViewController {
                editGroupViewController.groupID = groupIDForLookup!
            }
        }
    }
    
}
