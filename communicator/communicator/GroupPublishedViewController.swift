//
//  GroupPublishedViewController.swift
//  communicator
//
//  Created by Morgan Morley Mills on 4/23/17.
//  Copyright © 2017 Morgan Morley Mills. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class GroupPublishedViewController: UIViewController {

    var ref: FIRDatabaseReference?
    var groupRef: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    var groupID: String?
    var userID: String?
    var adminID: String?

    var isAdmin: Bool = false
    var shelf: Bool = false
    
    @IBOutlet weak var adminButton: UIButton!
    @IBOutlet weak var rosterButton: UIButton!
    @IBOutlet weak var addDeleteButton: UIButton!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    func findAdminID() {
        // Find the UID of the admin to search for their username in users
        groupRef?.child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupUsers = snapshot.value as? Dictionary<String,String> {
                for (user, role) in groupUsers {
                    if role == "admin" {
                        self.adminID = user
                    }
                }
                if self.adminID != nil {
                    //get admin's username for adminButton title
                    self.ref?.child("users").child(self.adminID!).child("details").child("username").observeSingleEvent(of: .value, with: { (snapshot) in
                        if let value = snapshot.value as? String {
                            self.adminButton.setTitle(value, for: .normal)
                        } else {
                            print("Could not find admin's username.")
                        }
                    })
                    //set admin view
                    if self.adminID == self.userID {
                        self.isAdmin = true
                        self.addDeleteButton.isHidden = true // eventually will turn into edit button and be false
                        self.rosterButton.isHidden = false
                        self.shelf = true
                    }
                } else {
                    print("Could not find admin linked to the event: " + String(describing: self.groupID!))
                }
            } else {
                print("Could not find users linked to the event: " + String(describing: self.groupID!))
            }
        })
    }

    func setLabels() {
        //Set the date, time, title, and place labels as well as description scroll view
        groupRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupDetails = snapshot.value as? Dictionary<String,String> {
                self.titleLabel.text = groupDetails["title"]
                self.descLabel.text = groupDetails["desc"]
                // set rsvp label and button; set addDeleteButton title
                self.userRef?.child("linked_groups").child(self.groupID!).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let value = snapshot.value as? String {
                        if value == "shelf" {
                            self.addDeleteButton.setTitle("x", for: .normal)
                        }
                    }
                })
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        groupRef = ref?.child("posts").child("groups").child(groupID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("users").child(userID!)
        
        //Default settings for view
        addDeleteButton.isHidden = false
        addDeleteButton.setTitle("+", for: .normal)
        rosterButton.isHidden = true

        //Query the database
        findAdminID()
        setLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToProfile" {
            if let profileViewController = segue.destination as? ProfileViewController {
                // send appropriate UID to userForLookup variable on Profile View Controller
                profileViewController.userIDForLookup = adminID!
            }
        } else if segue.identifier == "goToRoster" {
            if let rosterViewController = segue.destination as? RosterViewController {
                // send along the appropriate post type (groups or events) and the postId
                rosterViewController.postID = groupID!
                rosterViewController.postType = "groups"
            }
        }
    }

}
