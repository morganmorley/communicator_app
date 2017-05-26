//
//  MyProfileViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 3/13/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MyProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    var userID: String?
    
    @IBOutlet weak var promotedPosts: UITableView!
    @IBOutlet weak var usernameTextView: UITextView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var emailTextView: UITextView!
    
    var promotedPostTitles = [String]()
    var promotedPostData = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        promotedPosts.delegate = self
        promotedPosts.dataSource = self
        ref = FIRDatabase.database().reference()
        // set the logout and delete account buttons:
        userID = FIRAuth.auth()?.currentUser?.uid
        
        // retrieve the email and text labels for the appropriate username clicked in roster:
        ref?.child("user_details").child(userID!).child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            let details = snapshot.value as? Dictionary<String,String>
            if let email = details?["email"], let username = details?["username"] {
                self.usernameTextView.text = username
                self.emailTextView.text = email
            } else { print("no user details") }
            self.ref?.child("user_profiles").child(self.userID!).child("possible").observeSingleEvent(of: .value, with: { (snapshot) in
                if let posts = snapshot.value as? Dictionary<String,Dictionary<String,Dictionary<String,String>>> {
                    for (_, promoted) in posts {
                        for (postID, post) in promoted {
                            self.promotedPostData[post["name"]!] = postID
                            self.promotedPostTitles.append(post["name"]!)
                            // Reload the tableView
                            self.promotedPosts.reloadData()
                        }
                    }
                }
            })

        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        //TODO - ADD GROUPS AND EDIT FUNCTIONALITY
        let eventsRef = self.ref?.child("events")
        // search user's linked events:
        userRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? Dictionary<String, String>
            for (eventID, _) in value! {
                eventsRef?.child("drafts").child(eventID).child("linked_users").child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    let users = snapshot.value as? String
                    if users == "admin" {
                        eventsRef?.child("drafts").child(eventID).removeValue()
                    } else {
                        eventsRef?.child("drafts").child(eventID).child("linked_users").child(self.userID!).removeValue()
                    }
                })
                eventsRef?.child("current").child(eventID).child("linked_users").child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    let users = snapshot.value as? String
                    if users == "admin" {
                        eventsRef?.child("current").child(eventID).removeValue()
                    } else {
                        eventsRef?.child("current").child(eventID).child("linked_users").child(self.userID!).removeValue()
                    }
                })
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return promotedPostTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = promotedPostTitles[indexPath.row]
        return cell!
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditPromoted" {
            if let editPromotedViewController = segue.destination as? EditPromotedViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                editPromotedViewController.postID = promotedPostData[(sender as? UITableViewCell)!.textLabel!.text! as String]
            }
        }
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
