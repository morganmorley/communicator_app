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
    var userIDForLookup: String?

    @IBOutlet weak var usernameTextView: UILabel!
    @IBOutlet weak var postsTextView: UITextView!
    @IBOutlet weak var emailTextView: UILabel!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("user_details").child(userIDForLookup!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.usernameTextView.text = username
                self.emailTextView.text = email
            }
            //Add in promoted posts
            self.ref?.child("user_profiles").child(self.userIDForLookup!).child("current").observeSingleEvent(of: .value, with: { (snapshot) in
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
