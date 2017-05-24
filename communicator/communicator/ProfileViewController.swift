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
    
    var promotedPosts = [String: [String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("users").child(userIDForLookup!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.usernameTextView.text = username
                self.emailTextView.text = email
            }
            //Add in promoted posts
            self.ref?.child("users").child(self.userIDForLookup!).child("promoted_posts").child("shown").observeSingleEvent(of: .value, with: { (snapshot) in
                if let posts = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (year, promoted) in posts {
                        self.promotedPosts[year] = []
                        for (_, post) in promoted {
                            self.promotedPosts[year]!.append(post["role"]!)
                            self.promotedPosts[year]!.append(post["name"]!)
                        }
                    }
                    for (year, posts) in self.promotedPosts {
                        self.emailTextView.text = self.emailTextView.text! + year + "\n"
                        var counter = 0
                        for detail in posts {
                            if(counter % 2) == 0 {
                                self.emailTextView.text = self.emailTextView.text! + detail + "\t"
                            } else {
                                self.emailTextView.text = self.emailTextView.text! + detail + "\n"
                            }
                            counter += 1
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
