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

class GroupPublishedViewController:  UIViewController, UITableViewDelegate, UITableViewDataSource {

    var ref: FIRDatabaseReference?
    var groupRef: FIRDatabaseReference?
    var userRef: FIRDatabaseReference?
    
    var groupID: String?
    var userID: String?

    var isAdmin: Bool = false
    var isMember: Bool = false
    var eventData = [String: String]()
    var eventTitles = [String]()
    

    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var membersTextView: UITextView!
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var bottomButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        groupRef = ref?.child("groups").child("current").child(groupID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("user_details").child(userID!)
        
        //Default settings for view
        groupRef?.child("linked_users").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(self.userID!){
                if let member = snapshot.value as? Dictionary<String,String> {
                    let role = member[self.userID!]
                    if ((role != nil) || (self.userID == "ADMIN")) {
                        self.isMember = true
                        self.barButton.title = "Resources"
                    }
                    if ((role == "admin") || (self.userID == "ADMIN")) {
                        self.isAdmin = true
                        self.bottomButton.setTitle("Edit Group", for: .normal)
                    }
                }
            }
        })
        groupRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupDetails = snapshot.value as? Dictionary<String,String> {
                self.titleTextView.text = groupDetails["title"]
                self.descTextView.text = groupDetails["desc"]
            }
        })

        //Query the database for table view
        groupRef?.child("linked_events").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupEvents = snapshot.value as? Dictionary<String,String> {
                for (eventID, eventName) in groupEvents {
                    self.eventData[eventName] = eventID
                    self.eventTitles.append(eventName)
                }
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return eventTitles.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // number of cells needed
        return eventTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell")
        cell?.textLabel?.text = eventTitles[indexPath.row]
        return cell!
    }
    
    @IBAction func barButtonTapped(_ sender: Any) {
        if isMember {
            self.performSegue(withIdentifier: "goToResources", sender: self)
        } else {
            userRef?.child("linked_groups").child(groupID!).setValue(titleTextView.text)
            groupRef?.child("linked_users").child(userID!).setValue("member")
            let promotedPost = ["post_name": titleTextView.text as String, "role": "member"]
            ref?.child("user_profiles").child(userID!).child("possible").child("2017").child(groupID!).setValue(promotedPost)
        }
    }

    @IBAction func bottomButtonTapped(_ sender: Any) {
        if isAdmin {
            self.performSegue(withIdentifier: "goToEditGroup", sender: self)
        } else {
            userRef?.child("linked_groups").child(groupID!).removeValue()
            groupRef?.child("linked_users").child(userID!).removeValue()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEditGroup" {
            if let editGroupViewController = segue.destination as? EditGroupViewController {
                // send appropriate UID to groupID variable on Profile View Controller
                editGroupViewController.groupID = groupID!
            }
        } else if segue.identifier == "goToResources" {
            if let publishedResourcesViewController = segue.destination as? PublishedResourcesViewController {
                //send to appropriate groupID to PublishedResourcesViewController
                publishedResourcesViewController.groupID = groupID!
            }
        }
    }

}
