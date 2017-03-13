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
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(userForLookup ?? "no user")
        ref = FIRDatabase.database().reference()
        ref?.child("users").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? Dictionary<String, Dictionary<String, Any>>
            let currentUser = FIRAuth.auth()?.currentUser?.uid
            for (user, details) in (value)! {
                if user == currentUser {}
                let username = details["username"] as? String ?? ""
                if username == self.userForLookup {
                    let email = details["email"] as? String ?? ""
                    self.nameLabel.text = username
                    self.emailLabel.text = email
                }
            }
        })

        //}) { (error) in
          //  print(error.localizedDescription)
        //}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
