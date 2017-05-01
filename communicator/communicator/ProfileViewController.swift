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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
