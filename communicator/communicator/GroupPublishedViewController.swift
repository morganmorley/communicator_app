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

    var isAdmin: Bool = false
    var shelf: Bool = false
    
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var rosterButton: UIButton!
    
    var eventData = [String: String]()
    var eventTitles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up references to the database and find the current user's ID
        ref = FIRDatabase.database().reference()
        groupRef = ref?.child("posts").child("groups").child(groupID!)
        userID = FIRAuth.auth()?.currentUser?.uid
        userRef = ref?.child("users").child(userID!)
        
        //Default settings for view
        groupRef?.child("details").child("admin").observeSingleEvent(of: .value, with: { (snapshot) in
            if let adminID = snapshot.value as? String {
                if adminID == self.userID {
                    self.isAdmin = true
                    self.bottomButton.setTitle("Edit Group", for: .normal)
                    self.barButton.title = "Resources"
                }
            }
            self.groupRef?.child("linked_users").child(self.userID!).observeSingleEvent(of: .value, with: { (snapshot) in
                if let role = snapshot.value as? String {
                    self.barButton.title = "Resources"
                }
            })
        })
        groupRef?.child("details").observeSingleEvent(of: .value, with: { (snapshot) in
            if let groupDetails = snapshot.value as? Dictionary<String,String> {
                self.titleLabel.text = groupDetails["title"]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell")
        cell?.textLabel?.text = eventTitles[indexPath.row]
        return cell!
    }
    
    @IBAction func barButtonTapped(_ sender: Any) {
        if shelf {
            self.performSegue(withIdentifier: "goToResources", sender: self)
        } else {
            userRef?.child("linked_groups").child(groupID!).setValue(titleLabel.text)
            groupRef?.child("linked_users").child(userID!).setValue("member")
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
            if let publishedResourceViewController = segue.destination as? PublishedResourceViewController {
                //send to appropriate groupID to PublishedResourcesViewController
                publishedResourceViewController.groupID = groupID!
            }
        } else if segue.identifier == "goToRoster" {
            if let rosterViewController = segue.destination as? RosterViewController {
                // send along the appropriate post type (groups or events) and the postId
                rosterViewController.postID = groupID!
                rosterViewController.postType = "groups"
            }
        } else if segue.identifier == "goToEvent" {
            if segue.identifier == "goToEvent" {
                if let eventPublishedViewController = segue.destination as? EventPublishedViewController {
                    // send appropriate UID to groupID variable on Profile View Controller
                    eventPublishedViewController.eventID = eventData[(sender as? UITableViewCell)!.textLabel!.text! as String]
                }
            }
        }
    }

}
